#include "KeyboardAttached.h"

KeyboardAttachedType::KeyboardAttachedType(QObject *parent)
    : QObject(parent)
{
}

void KeyboardAttachedType::setEnabled(bool value)
{
    if (m_enabled == value)
        return;
    m_enabled = value;
    emit enabledChanged();
}

void KeyboardAttachedType::setEnableHistory(bool value)
{
    if (m_enableHistory == value)
        return;
    m_enableHistory = value;
    emit enableHistoryChanged();
}

void KeyboardAttachedType::setHistoryKey(const QString &value)
{
    if (m_historyKey == value)
        return;
    m_historyKey = value;
    emit historyKeyChanged();
}

KeyboardAttachedType *KeyboardProp::qmlAttachedProperties(QObject *object)
{
    return new KeyboardAttachedType(object);
}

