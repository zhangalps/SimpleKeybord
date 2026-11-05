#pragma once

#include <QObject>
#include <QPointer>
#include <QString>
#include <QStringList>
#include <QFutureWatcher>
#include <QtQml/qqml.h>
#include <QtQml/qqmlregistration.h>
#include <memory>
#include "pinyin/PinyinDecoder.h"

class InputEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString globalLanguage READ globalLanguage WRITE setGlobalLanguage NOTIFY globalLanguageChanged FINAL)
    Q_PROPERTY(bool chineseMode READ chineseMode WRITE setChineseMode NOTIFY chineseModeChanged FINAL)
    Q_PROPERTY(bool passwordMode READ passwordMode NOTIFY passwordModeChanged FINAL)
    Q_PROPERTY(bool capsLock READ capsLock WRITE setCapsLock NOTIFY capsLockChanged FINAL)
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged FINAL)
    Q_PROPERTY(QString pinyinBuffer READ pinyinBuffer NOTIFY pinyinBufferChanged FINAL)
    Q_PROPERTY(QString pinyinDisplay READ pinyinDisplay NOTIFY pinyinBufferChanged FINAL)
    Q_PROPERTY(QStringList candidates READ candidates NOTIFY candidatesChanged FINAL)
    Q_PROPERTY(int currentPage READ currentPage NOTIFY candidatesChanged FINAL)
    Q_PROPERTY(bool hasPrevPage READ hasPrevPage NOTIFY candidatesChanged FINAL)
    Q_PROPERTY(bool hasNextPage READ hasNextPage NOTIFY candidatesChanged FINAL)
    Q_PROPERTY(bool historyEnabled READ historyEnabled NOTIFY historyStateChanged FINAL)
    Q_PROPERTY(QString currentHistoryKey READ currentHistoryKey NOTIFY historyStateChanged FINAL)
    Q_PROPERTY(QStringList historyList READ historyList NOTIFY historyStateChanged FINAL)
    Q_PROPERTY(bool dictionaryReady READ dictionaryReady NOTIFY dictionaryReadyChanged FINAL)

public:
    explicit InputEngine(QObject *parent = nullptr);
    ~InputEngine() override;

    QString globalLanguage() const { return m_globalLanguage; }
    void setGlobalLanguage(const QString &lang);

    bool chineseMode() const { return m_chineseMode; }
    void setChineseMode(bool value);

    bool passwordMode() const { return m_passwordMode; }
    bool capsLock() const { return m_capsLock; }
    void setCapsLock(bool value);

    bool darkTheme() const { return m_darkTheme; }
    void setDarkTheme(bool value);

    QString pinyinBuffer() const { return m_pinyinBuffer; }
    QString pinyinDisplay() const;

    QStringList candidates() const { return m_pageCandidates; }
    int currentPage() const { return m_currentPage; }
    bool hasPrevPage() const { return m_currentPage > 0; }
    bool hasNextPage() const;

    bool historyEnabled() const { return m_historyEnabled; }
    QString currentHistoryKey() const { return m_currentHistoryKey; }
    QStringList historyList() const { return m_historyList; }
    bool dictionaryReady() const { return m_dictionaryReady; }

    // QML Invokable Methods
    Q_INVOKABLE bool isTextInputItem(QObject *item) const;
    Q_INVOKABLE bool isKeyboardEnabled(QObject *item) const;
    Q_INVOKABLE void bindTargetItem(QObject *item);

    Q_INVOKABLE void handleKeyPress(const QString &key);
    Q_INVOKABLE void handleSymbolPress(const QString &symbol);
    Q_INVOKABLE void handleBackspace();
    Q_INVOKABLE void handleSpace();
    Q_INVOKABLE void handleEnter();

    Q_INVOKABLE void selectCandidate(int pageIndex);
    Q_INVOKABLE void nextCandidatePage();
    Q_INVOKABLE void prevCandidatePage();
    Q_INVOKABLE void clearPinyinBuffer();

    Q_INVOKABLE void toggleLanguageMode();
    Q_INVOKABLE void toggleCapsLock();

    Q_INVOKABLE void applyHistoryItem(const QString &text);
    Q_INVOKABLE void commitHistory(const QString &key, const QString &value);
    Q_INVOKABLE void clearCurrentHistory();
    Q_INVOKABLE void clearHistory(const QString &key);

    bool eventFilter(QObject *watched, QEvent *event) override;

signals:
    void globalLanguageChanged();
    void chineseModeChanged();
    void passwordModeChanged();
    void capsLockChanged();
    void darkThemeChanged();
    void pinyinBufferChanged();
    void candidatesChanged();
    void historyStateChanged();
    void dictionaryReadyChanged();
    void requestShowKeyboard();
    void requestHideKeyboard();

private:
    void updatePinyinSearch();
    void updatePageSlice();
    void injectTextToTarget(const QString &text);
    void injectBackspaceToTarget();
    void loadHistoryForKey(const QString &key);
    bool checkIsPasswordInput(QObject *item) const;

    static constexpr int kPageSize = 7;
    static constexpr int kMaxHistoryCount = 10;

    QString m_globalLanguage = QStringLiteral("zh_CN");
    bool m_chineseMode = true;
    bool m_passwordMode = false;
    bool m_capsLock = false;
    bool m_darkTheme = true;
    bool m_dictionaryReady = false;

    QPointer<QObject> m_targetItem;
    QString m_pinyinBuffer;
    QString m_segmentedPinyin;
    QString m_composedPrefix;
    QStringList m_allCandidates;
    QVector<int> m_consumedLengths;
    QStringList m_pageCandidates;
    int m_currentPage = 0;

    bool m_historyEnabled = false;
    QString m_currentHistoryKey;
    QStringList m_historyList;

    std::shared_ptr<ime_pinyin::PinyinDecoder> m_decoder;
    QFutureWatcher<bool> m_dictWatcher;
};

