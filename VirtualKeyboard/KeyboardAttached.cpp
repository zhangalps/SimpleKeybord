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

KeyboardAttachedType *KeyboardProp::qmlAttachedProperties(QObject *object)
{
    return new KeyboardAttachedType(object);
}
