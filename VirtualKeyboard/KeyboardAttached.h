#pragma once

#include <QObject>
#include <QtQml/qqml.h>
#include <QtQml/qqmlregistration.h>

class KeyboardAttachedType : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged FINAL)

public:
    explicit KeyboardAttachedType(QObject *parent = nullptr);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool value);

signals:
    void enabledChanged();

private:
    bool m_enabled = true;
};

class KeyboardProp : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("KeyboardProp can only be used as an attached property.")
    QML_ATTACHED(KeyboardAttachedType)

public:
    using QObject::QObject;
    static KeyboardAttachedType *qmlAttachedProperties(QObject *object);
};
