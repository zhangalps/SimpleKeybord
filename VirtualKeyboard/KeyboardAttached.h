#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqml.h>
#include <QtQml/qqmlregistration.h>

class KeyboardAttachedType : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged FINAL)
    Q_PROPERTY(bool enableHistory READ enableHistory WRITE setEnableHistory NOTIFY enableHistoryChanged FINAL)
    Q_PROPERTY(QString historyKey READ historyKey WRITE setHistoryKey NOTIFY historyKeyChanged FINAL)

public:
    explicit KeyboardAttachedType(QObject *parent = nullptr);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool value);

    bool enableHistory() const { return m_enableHistory; }
    void setEnableHistory(bool value);

    QString historyKey() const { return m_historyKey; }
    void setHistoryKey(const QString &value);

signals:
    void enabledChanged();
    void enableHistoryChanged();
    void historyKeyChanged();

private:
    bool m_enabled = true;
    bool m_enableHistory = false;
    QString m_historyKey;
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

