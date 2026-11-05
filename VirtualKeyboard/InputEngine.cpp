#include "InputEngine.h"
#include "KeyboardAttached.h"

#include <QCoreApplication>
#include <QEvent>
#include <QKeyEvent>
#include <QMetaObject>
#include <QMetaProperty>
#include <QtConcurrent/QtConcurrentRun>
#include <algorithm>

InputEngine::InputEngine(QObject *parent)
    : QObject(parent)
    , m_decoder(std::make_shared<ime_pinyin::PinyinDecoder>())
{
    connect(&m_dictWatcher, &QFutureWatcher<bool>::finished, this, [this]() {
        m_dictionaryReady = m_dictWatcher.result();
        emit dictionaryReadyChanged();
        if (!m_pinyinBuffer.isEmpty()) {
            updatePinyinSearch();
        }
    });

    auto decoderPtr = m_decoder;
    m_dictWatcher.setFuture(QtConcurrent::run([decoderPtr]() {
        return decoderPtr->loadDictionary();
    }));
}

InputEngine::~InputEngine()
{
    if (m_dictWatcher.isRunning()) {
        m_dictWatcher.waitForFinished();
    }
}

void InputEngine::setGlobalLanguage(const QString &lang)
{
    if (m_globalLanguage == lang)
        return;
    m_globalLanguage = lang;
    emit globalLanguageChanged();

    if (!m_passwordMode) {
        const bool shouldBeChinese = lang.startsWith(QStringLiteral("zh"), Qt::CaseInsensitive);
        setChineseMode(shouldBeChinese);
    }
}

void InputEngine::setChineseMode(bool value)
{
    if (m_passwordMode)
        value = false;
    if (m_chineseMode == value)
        return;
    m_chineseMode = value;
    clearPinyinBuffer();
    emit chineseModeChanged();
}

void InputEngine::setCapsLock(bool value)
{
    if (m_capsLock == value)
        return;
    m_capsLock = value;
    emit capsLockChanged();
}

void InputEngine::setDarkTheme(bool value)
{
    if (m_darkTheme == value)
        return;
    m_darkTheme = value;
    emit darkThemeChanged();
}

QString InputEngine::pinyinDisplay() const
{
    if (m_composedPrefix.isEmpty())
        return m_segmentedPinyin;
    return m_composedPrefix + QStringLiteral(" ") + m_segmentedPinyin;
}

bool InputEngine::hasNextPage() const
{
    return (m_currentPage + 1) * kPageSize < m_allCandidates.size();
}

bool InputEngine::isTextInputItem(QObject *item) const
{
    if (!item)
        return false;
    const QMetaObject *meta = item->metaObject();
    return (meta->indexOfProperty("text") >= 0 && meta->indexOfProperty("cursorPosition") >= 0);
}

bool InputEngine::isKeyboardEnabled(QObject *item) const
{
    if (!item)
        return false;
    auto *attached = qobject_cast<KeyboardAttachedType *>(
        qmlAttachedPropertiesObject<KeyboardProp>(item, false));
    if (attached)
        return attached->enabled();
    return true;
}

bool InputEngine::checkIsPasswordInput(QObject *item) const
{
    if (!item)
        return false;
    const QVariant echoVar = item->property("echoMode");
    if (!echoVar.isValid())
        return false;
    const int echoMode = echoVar.toInt();
    // TextInput.Password == 2, TextInput.PasswordEchoOnEdit == 3
    return (echoMode == 2 || echoMode == 3);
}

void InputEngine::bindTargetItem(QObject *item)
{
    if (m_targetItem == item)
        return;

    if (m_targetItem) {
        m_targetItem->removeEventFilter(this);
    }

    clearPinyinBuffer();
    m_targetItem = item;

    if (!m_targetItem) {
        if (m_passwordMode) {
            m_passwordMode = false;
            emit passwordModeChanged();
        }
        return;
    }

    m_targetItem->installEventFilter(this);

    const bool isPwd = checkIsPasswordInput(m_targetItem);
    if (m_passwordMode != isPwd) {
        m_passwordMode = isPwd;
        emit passwordModeChanged();
    }

    if (m_passwordMode) {
        setChineseMode(false);
    } else {
        const bool defaultZh = m_globalLanguage.startsWith(QStringLiteral("zh"), Qt::CaseInsensitive);
        setChineseMode(defaultZh);
    }
}

bool InputEngine::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_targetItem && event) {
        if (event->type() == QEvent::MouseButtonPress || event->type() == QEvent::TouchBegin) {
            emit requestShowKeyboard();
        }
    }
    return QObject::eventFilter(watched, event);
}

void InputEngine::handleKeyPress(const QString &key)
{
    if (!m_targetItem || key.isEmpty())
        return;

    const QChar ch = key.at(0);
    if (m_chineseMode && !m_passwordMode && !m_capsLock && ch.isLower() && ch >= u'a' && ch <= u'z') {
        if (m_pinyinBuffer.length() < 32) {
            m_pinyinBuffer.append(ch);
            updatePinyinSearch();
        }
        return;
    }

    if (!m_pinyinBuffer.isEmpty()) {
        injectTextToTarget(m_composedPrefix + m_pinyinBuffer);
        clearPinyinBuffer();
    }

    injectTextToTarget(key);
}

void InputEngine::handleSymbolPress(const QString &symbol)
{
    if (!m_targetItem || symbol.isEmpty())
        return;

    if (!m_pinyinBuffer.isEmpty()) {
        if (!m_allCandidates.isEmpty()) {
            injectTextToTarget(m_composedPrefix + m_allCandidates.first());
        } else {
            injectTextToTarget(m_composedPrefix + m_pinyinBuffer);
        }
        clearPinyinBuffer();
    }

    if (m_chineseMode && !m_passwordMode) {
        if (symbol == QStringLiteral(".")) {
            injectTextToTarget(QStringLiteral("\u3002"));
            return;
        }
        if (symbol == QStringLiteral(",")) {
            injectTextToTarget(QStringLiteral("\uff0c"));
            return;
        }
        if (symbol == QStringLiteral("?")) {
            injectTextToTarget(QStringLiteral("\uff1f"));
            return;
        }
        if (symbol == QStringLiteral("!")) {
            injectTextToTarget(QStringLiteral("\uff01"));
            return;
        }
    }

    injectTextToTarget(symbol);
}

void InputEngine::handleBackspace()
{
    if (!m_pinyinBuffer.isEmpty()) {
        m_pinyinBuffer.chop(1);
        if (m_pinyinBuffer.isEmpty() && !m_composedPrefix.isEmpty()) {
            injectTextToTarget(m_composedPrefix);
            m_composedPrefix.clear();
        }
        updatePinyinSearch();
        return;
    }

    injectBackspaceToTarget();
}

void InputEngine::handleSpace()
{
    if (!m_pinyinBuffer.isEmpty()) {
        selectCandidate(0);
        return;
    }
    injectTextToTarget(QStringLiteral(" "));
}

void InputEngine::handleEnter()
{
    if (!m_pinyinBuffer.isEmpty()) {
        injectTextToTarget(m_composedPrefix + m_pinyinBuffer);
        clearPinyinBuffer();
    }

    if (m_targetItem) {
        QKeyEvent pressEvt(QEvent::KeyPress, Qt::Key_Return, Qt::NoModifier, QStringLiteral("\r"));
        QKeyEvent releaseEvt(QEvent::KeyRelease, Qt::Key_Return, Qt::NoModifier, QStringLiteral("\r"));
        QCoreApplication::sendEvent(m_targetItem, &pressEvt);
        QCoreApplication::sendEvent(m_targetItem, &releaseEvt);
    }
}

void InputEngine::selectCandidate(int pageIndex)
{
    if (pageIndex < 0 || pageIndex >= m_pageCandidates.size())
        return;

    const int globalIdx = m_currentPage * kPageSize + pageIndex;
    if (globalIdx < 0 || globalIdx >= m_allCandidates.size())
        return;

    const QString chosen = m_allCandidates.at(globalIdx);
    const int consumed = (globalIdx < m_consumedLengths.size())
                             ? m_consumedLengths.at(globalIdx)
                             : m_pinyinBuffer.length();

    m_decoder->boostCandidate(chosen);

    if (consumed >= m_pinyinBuffer.length()) {
        injectTextToTarget(m_composedPrefix + chosen);
        clearPinyinBuffer();
    } else {
        m_composedPrefix.append(chosen);
        m_pinyinBuffer = m_pinyinBuffer.mid(consumed);
        updatePinyinSearch();
    }
}

void InputEngine::nextCandidatePage()
{
    if (!hasNextPage())
        return;
    ++m_currentPage;
    updatePageSlice();
    emit candidatesChanged();
}

void InputEngine::prevCandidatePage()
{
    if (!hasPrevPage())
        return;
    --m_currentPage;
    updatePageSlice();
    emit candidatesChanged();
}

void InputEngine::clearPinyinBuffer()
{
    if (m_pinyinBuffer.isEmpty() && m_composedPrefix.isEmpty() && m_allCandidates.isEmpty())
        return;
    m_pinyinBuffer.clear();
    m_segmentedPinyin.clear();
    m_composedPrefix.clear();
    m_allCandidates.clear();
    m_consumedLengths.clear();
    m_pageCandidates.clear();
    m_currentPage = 0;
    emit pinyinBufferChanged();
    emit candidatesChanged();
}

void InputEngine::toggleLanguageMode()
{
    if (m_passwordMode)
        return;
    setChineseMode(!m_chineseMode);
}

void InputEngine::toggleCapsLock()
{
    if (!m_pinyinBuffer.isEmpty()) {
        injectTextToTarget(m_composedPrefix + m_pinyinBuffer);
        clearPinyinBuffer();
    }
    setCapsLock(!m_capsLock);
}

void InputEngine::updatePinyinSearch()
{
    if (m_pinyinBuffer.isEmpty()) {
        m_segmentedPinyin.clear();
        m_allCandidates.clear();
        m_consumedLengths.clear();
        m_pageCandidates.clear();
        m_currentPage = 0;
        emit pinyinBufferChanged();
        emit candidatesChanged();
        return;
    }

    const ime_pinyin::SearchResult res = m_decoder->search(m_pinyinBuffer);
    m_segmentedPinyin = res.segmentedPinyin;
    m_allCandidates = res.candidates;
    m_consumedLengths = res.consumedLengths;
    m_currentPage = 0;
    updatePageSlice();

    emit pinyinBufferChanged();
    emit candidatesChanged();
}

void InputEngine::updatePageSlice()
{
    const int start = m_currentPage * kPageSize;
    if (start >= m_allCandidates.size()) {
        m_pageCandidates.clear();
        return;
    }
    m_pageCandidates = m_allCandidates.mid(start, kPageSize);
}

void InputEngine::injectTextToTarget(const QString &text)
{
    if (!m_targetItem || text.isEmpty())
        return;

    const int selStart = m_targetItem->property("selectionStart").toInt();
    const int selEnd = m_targetItem->property("selectionEnd").toInt();
    QString curText = m_targetItem->property("text").toString();
    int cursorPos = m_targetItem->property("cursorPosition").toInt();

    if (selEnd > selStart && selStart >= 0 && selEnd <= curText.length()) {
        curText.remove(selStart, selEnd - selStart);
        cursorPos = selStart;
    }

    cursorPos = std::clamp(cursorPos, 0, static_cast<int>(curText.length()));
    curText.insert(cursorPos, text);
    m_targetItem->setProperty("text", curText);
    m_targetItem->setProperty("cursorPosition", cursorPos + text.length());
}

void InputEngine::injectBackspaceToTarget()
{
    if (!m_targetItem)
        return;

    const int selStart = m_targetItem->property("selectionStart").toInt();
    const int selEnd = m_targetItem->property("selectionEnd").toInt();
    QString curText = m_targetItem->property("text").toString();
    int cursorPos = m_targetItem->property("cursorPosition").toInt();

    if (selEnd > selStart && selStart >= 0 && selEnd <= curText.length()) {
        curText.remove(selStart, selEnd - selStart);
        m_targetItem->setProperty("text", curText);
        m_targetItem->setProperty("cursorPosition", selStart);
        return;
    }

    if (cursorPos > 0 && !curText.isEmpty()) {
        curText.remove(cursorPos - 1, 1);
        m_targetItem->setProperty("text", curText);
        m_targetItem->setProperty("cursorPosition", cursorPos - 1);
    }
}
