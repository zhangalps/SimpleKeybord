import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import VirtualKeyboard

ApplicationWindow {
    id: window
    width: 800
    height: 480
    minimumWidth: 800
    minimumHeight: 480
    visible: true
    title: "7-Inch Industrial HMI - VirtualKeyboard Demo (800x480)"

    readonly property bool dark: InputEngine.darkTheme
    readonly property bool isZh: InputEngine.globalLanguage === "zh_CN"
    property string statusToast: ""

    color: dark ? "#0B0F17" : "#F1F5F9"

    // Background click area to dismiss keyboard when clicking outside inputs
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (window.activeFocusItem) {
                window.activeFocusItem.focus = false
            }
            vKeyboard.closeKeyboard()
        }
    }

    // Liftable Page Content Container (automatically pushed up by VirtualKeyboard when lower inputs are focused)
    Item {
        id: pageContent
        width: parent.width
        height: parent.height

        // 1. Industrial Top Status & Control Bar
        Rectangle {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52
            z: 10
            color: window.dark ? "#131B2E" : "#FFFFFF"
            border.width: 1
            border.color: window.dark ? "#1E293B" : "#CBD5E1"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: InputEngine.dictionaryReady ? "#22C55E" : "#F59E0B"
                }

                Text {
                    text: window.isZh
                          ? "\u5de5\u63a7\u4e0a\u4f4d\u673a\u7ec8\u7aef (7\u5bf8 800\u00d7480)"
                          : "Industrial HMI Terminal (800\u00d7480)"
                    font.pixelSize: 17
                    font.bold: true
                    font.family: "Microsoft YaHei UI"
                    color: window.dark ? "#F8FAFC" : "#0F172A"
                }

                Text {
                    text: InputEngine.dictionaryReady
                          ? (window.isZh ? "[\u8bcd\u5e93\u5df2\u5c31\u7eea]" : "[Dict Ready]")
                          : (window.isZh ? "[\u8bcd\u5e93\u52a0\u8f7d\u4e2d...]" : "[Loading Dict...]")
                    font.pixelSize: 12
                    font.family: "Microsoft YaHei UI"
                    color: InputEngine.dictionaryReady ? "#22C55E" : "#F59E0B"
                }

                Item { Layout.fillWidth: true }

                // Global System Language Switcher
                Rectangle {
                    Layout.preferredHeight: 34
                    Layout.preferredWidth: 136
                    radius: 6
                    color: langTouch.pressed
                           ? "#2563EB"
                           : (window.dark ? "#1E293B" : "#E2E8F0")
                    border.width: 1
                    border.color: "#3B82F6"

                    Text {
                        anchors.centerIn: parent
                        text: window.isZh ? "\ud83c\udf10 \u8bed\u8a00: \u4e2d\u6587" : "\ud83c\udf10 Lang: EN"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                    }

                    MouseArea {
                        id: langTouch
                        anchors.fill: parent
                        onClicked: {
                            InputEngine.globalLanguage = window.isZh ? "en_US" : "zh_CN"
                        }
                    }
                }

                // Industrial Dark / Light Theme Switcher
                Rectangle {
                    Layout.preferredHeight: 34
                    Layout.preferredWidth: 126
                    radius: 6
                    color: themeTouch.pressed
                           ? "#2563EB"
                           : (window.dark ? "#1E293B" : "#E2E8F0")
                    border.width: 1
                    border.color: window.dark ? "#334155" : "#94A3B8"

                    Text {
                        anchors.centerIn: parent
                        text: window.dark ? "\ud83c\udf19 \u5de5\u63a7\u6df1\u8272" : "\u2600\ufe0f \u73b0\u4ee3\u6d45\u8272"
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                    }

                    MouseArea {
                        id: themeTouch
                        anchors.fill: parent
                        onClicked: {
                            InputEngine.darkTheme = !InputEngine.darkTheme
                        }
                    }
                }
            }
        }

        // 2. Main Login & Industrial Parameter Card
        Rectangle {
            id: loginCard
            width: 560
            height: 380
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: topBar.bottom
            anchors.topMargin: 22
            radius: 10
            color: window.dark ? "#151D2C" : "#FFFFFF"
            border.width: 1
            border.color: window.dark ? "#26334D" : "#CBD5E1"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: window.isZh ? "\u64cd\u4f5c\u5458\u5b89\u5168\u767b\u5f55\u4e0e\u7ad9\u70b9\u914d\u7f6e" : "Operator Login & Station Setup"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F1F5F9" : "#0F172A"
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: window.statusToast
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: "#22C55E"
                        visible: window.statusToast.length > 0
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: window.dark ? "#243046" : "#E2E8F0"
                }

                // Field 1: User Account
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: window.isZh ? "\u64cd\u4f5c\u5458\u8d26\u53f7 :" : "Operator ID :"
                        Layout.preferredWidth: 110
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#CBD5E1" : "#334155"
                    }

                    TextField {
                        id: userField
                        objectName: "operator_user"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        placeholderText: window.isZh
                                         ? "\u70b9\u51fb\u8f93\u5165\u8d26\u53f7 (\u8f93\u5165\u62fc\u97f3\u65f6\u81ea\u52a8\u663e\u793a\u5019\u9009\u8bcd\u680f)"
                                         : "Tap to enter operator ID"
                        font.pixelSize: 16
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                        placeholderTextColor: window.dark ? "#64748B" : "#94A3B8"
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 12
                        rightPadding: 12

                        background: Rectangle {
                            radius: 6
                            color: window.dark ? "#0D131F" : "#F8FAFC"
                            border.width: userField.activeFocus ? 2 : 1
                            border.color: userField.activeFocus
                                          ? "#3B82F6"
                                          : (window.dark ? "#2E3C56" : "#CBD5E1")
                        }
                    }
                }

                // Field 2: Password Field (Lower position -> Auto Page Lift + Forced Alphanumeric)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: window.isZh ? "\u5b89\u5168\u5bc6\u7801 :" : "Password :"
                        Layout.preferredWidth: 110
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#CBD5E1" : "#334155"
                    }

                    TextField {
                        id: passwordField
                        objectName: "operator_password"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        echoMode: TextInput.Password
                        placeholderText: window.isZh
                                         ? "\u5f3a\u5236\u9501\u5b9a\u82f1\u6570\u6a21\u5f0f \u00b7 \u7981\u7528\u62fc\u97f3\u5019\u9009\u680f"
                                         : "Forced Alphanumeric \u00b7 No Candidates"
                        font.pixelSize: 16
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                        placeholderTextColor: window.dark ? "#64748B" : "#94A3B8"
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 12
                        rightPadding: 12

                        background: Rectangle {
                            radius: 6
                            color: window.dark ? "#0D131F" : "#F8FAFC"
                            border.width: passwordField.activeFocus ? 2 : 1
                            border.color: passwordField.activeFocus
                                          ? "#F59E0B"
                                          : (window.dark ? "#2E3C56" : "#CBD5E1")
                        }
                    }
                }

                // Field 3: Bottom PLC Station / Batch Input (Demonstrates larger Page Lift + Symbols)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: window.isZh ? "\u5de5\u4f4d/\u6279\u6b21\u53f7 :" : "PLC Batch :"
                        Layout.preferredWidth: 110
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#CBD5E1" : "#334155"
                    }

                    TextField {
                        id: stationField
                        objectName: "plc_station"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        text: "PLC_LINE_01#A"
                        placeholderText: window.isZh
                                         ? "\u4f4d\u4e8e\u754c\u9762\u5e95\u90e8 \u00b7 \u805a\u7126\u65f6\u81ea\u52a8\u5411\u4e0a\u5e73\u6ed1\u63a8\u9876\u9632\u906e\u6321"
                                         : "Bottom field \u00b7 Auto page-lift anti-occlusion test"
                        font.pixelSize: 16
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                        placeholderTextColor: window.dark ? "#64748B" : "#94A3B8"
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 12
                        rightPadding: 12

                        background: Rectangle {
                            radius: 6
                            color: window.dark ? "#0D131F" : "#F8FAFC"
                            border.width: stationField.activeFocus ? 2 : 1
                            border.color: stationField.activeFocus
                                          ? "#3B82F6"
                                          : (window.dark ? "#2E3C56" : "#CBD5E1")
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Login & Reset Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 6
                        color: clearBtnTouch.pressed
                               ? (window.dark ? "#334155" : "#CBD5E1")
                               : (window.dark ? "#1E293B" : "#E2E8F0")
                        border.width: 1
                        border.color: window.dark ? "#36435C" : "#94A3B8"

                        Text {
                            anchors.centerIn: parent
                            text: window.isZh ? "\u6e05\u7a7a\u8868\u5355" : "Reset Fields"
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "Microsoft YaHei UI"
                            color: window.dark ? "#E2E8F0" : "#1E293B"
                        }

                        MouseArea {
                            id: clearBtnTouch
                            anchors.fill: parent
                            onClicked: {
                                userField.text = ""
                                passwordField.text = ""
                                stationField.text = ""
                                window.statusToast = window.isZh ? "\u5df2\u6e05\u7a7a\u6240\u6709\u8f93\u5165\u5185\u5bb9" : "All fields cleared"
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: 6
                        color: loginBtnTouch.pressed ? "#1D4ED8" : "#2563EB"
                        border.width: 1
                        border.color: "#60A5FA"

                        Text {
                            anchors.centerIn: parent
                            text: window.isZh ? "\u2713 \u786e\u8ba4\u767b\u5f55" : "\u2713 Sign In"
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "Microsoft YaHei UI"
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: loginBtnTouch
                            anchors.fill: parent
                            onClicked: {
                                vKeyboard.closeKeyboard()
                                window.statusToast = window.isZh
                                                     ? ("\u767b\u5f55\u6210\u529f: " + (userField.text || "\u533f\u540d\u64cd\u4f5c\u5458"))
                                                     : ("Signed in: " + (userField.text || "Operator"))
                            }
                        }
                    }
                }
            }
        }
    }

    // 3. Global 7-Inch Touch Virtual Keyboard Instance
    VirtualKeyboard {
        id: vKeyboard
        pageContainer: pageContent
    }
}
