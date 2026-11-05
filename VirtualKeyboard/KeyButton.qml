import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string text: ""
    property string subText: ""
    property bool isFunctionKey: false
    property bool isPrimaryKey: false
    property bool isActiveState: false
    property bool showStatusDot: false
    property bool statusActive: false
    property bool autoRepeat: false
    property int repeatDelay: 400
    property int repeatInterval: 50
    property bool darkTheme: true
    property int fontPixelSize: isFunctionKey ? 15 : 19

    signal clicked()
    signal pressAndHold()

    implicitWidth: 52
    implicitHeight: 42
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: 40
    Layout.minimumHeight: 38

    readonly property bool pressed: touchArea.pressed

    readonly property color normalBgColor: {
        if (isPrimaryKey) {
            return darkTheme ? "#2563EB" : "#1D4ED8"
        }
        if (isActiveState) {
            return darkTheme ? "#3B82F6" : "#2563EB"
        }
        if (isFunctionKey) {
            return darkTheme ? "#1E2636" : "#CBD5E1"
        }
        return darkTheme ? "#283246" : "#FFFFFF"
    }

    readonly property color pressedBgColor: {
        if (isPrimaryKey) {
            return darkTheme ? "#3B82F6" : "#2563EB"
        }
        return darkTheme ? "#3B82F6" : "#93C5FD"
    }

    readonly property color borderColor: {
        if (pressed) {
            return darkTheme ? "#60A5FA" : "#2563EB"
        }
        if (isPrimaryKey || isActiveState) {
            return darkTheme ? "#3B82F6" : "#1D4ED8"
        }
        return darkTheme ? "#36435C" : "#94A3B8"
    }

    readonly property color textColor: {
        if (isPrimaryKey || isActiveState || (pressed && darkTheme)) {
            return "#FFFFFF"
        }
        return darkTheme ? "#F1F5F9" : "#0F172A"
    }

    Rectangle {
        id: keyBg
        anchors.fill: parent
        radius: 6
        color: root.pressed ? root.pressedBgColor : root.normalBgColor
        border.width: 1
        border.color: root.borderColor
        scale: root.pressed ? 0.94 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 55
                easing.type: Easing.OutQuad
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 50
            }
        }

        // Bottom subtle bevel for industrial key tactile look
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            radius: 6
            visible: !root.pressed
            color: root.darkTheme ? "#0F141E" : "#94A3B8"
            opacity: 0.65
        }

        // Optional status indicator LED dot (e.g. CapsLock)
        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 5
            anchors.leftMargin: 6
            visible: root.showStatusDot
            color: root.statusActive ? "#22C55E" : (root.darkTheme ? "#475569" : "#94A3B8")
            border.width: root.statusActive ? 1 : 0
            border.color: "#86EFAC"
        }

        // Optional secondary label in top-right corner
        Text {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 2
            anchors.rightMargin: 5
            visible: root.subText.length > 0
            text: root.subText
            font.pixelSize: 10
            font.family: "Microsoft YaHei UI"
            color: root.darkTheme ? "#94A3B8" : "#64748B"
        }

        // Main key label
        Text {
            anchors.centerIn: parent
            text: root.text
            font.pixelSize: root.fontPixelSize
            font.bold: !root.isFunctionKey || root.isPrimaryKey
            font.family: "Microsoft YaHei UI"
            color: root.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Timer {
        id: initialDelayTimer
        interval: root.repeatDelay
        repeat: false
        onTriggered: {
            if (root.pressed && root.autoRepeat) {
                root.clicked()
                repeatTimer.start()
            }
        }
    }

    Timer {
        id: repeatTimer
        interval: root.repeatInterval
        repeat: true
        onTriggered: {
            if (root.pressed && root.autoRepeat) {
                root.clicked()
            } else {
                stop()
            }
        }
    }

    MouseArea {
        id: touchArea
        anchors.fill: parent
        anchors.margins: -2 // slightly expand hit target into spacing gap

        onPressed: {
            if (root.autoRepeat) {
                root.clicked()
                initialDelayTimer.restart()
            }
        }

        onReleased: {
            initialDelayTimer.stop()
            repeatTimer.stop()
            if (!root.autoRepeat && containsMouse) {
                root.clicked()
            }
        }

        onCanceled: {
            initialDelayTimer.stop()
            repeatTimer.stop()
        }

        onPressAndHold: {
            root.pressAndHold()
        }
    }
}

