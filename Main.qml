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
                          ? "工控上位机终端 (7寸 800×480)"
                          : "Industrial HMI Terminal (800×480)"
                    font.pixelSize: 17
                    font.bold: true
                    font.family: "Microsoft YaHei UI"
                    color: window.dark ? "#F8FAFC" : "#0F172A"
                }

                Text {
                    text: InputEngine.dictionaryReady
                          ? (window.isZh ? "[词库已就绪]" : "[Dict Ready]")
                          : (window.isZh ? "[词库加载中...]" : "[Loading Dict...]")
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
                        text: window.isZh ? "🌐 语言: 中文" : "🌐 Lang: EN"
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
                        text: window.dark ? "🌙 工控深色" : "☀️ 现代浅色"
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
                        text: window.isZh ? "操作员安全登录与站点配置" : "Operator Login & Station Setup"
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

                // Field 1: User Account (Supports History Dropdown + Auto Language Mode)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: window.isZh ? "操作员账号 :" : "Operator ID :"
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
                                         ? "点击输入账号 (支持中文拼音与历史记忆补全)"
                                         : "Tap to enter operator ID (History enabled)"
                        font.pixelSize: 16
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                        placeholderTextColor: window.dark ? "#64748B" : "#94A3B8"
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 12
                        rightPadding: 12

                        // Enable history popup for User field
                        KeyboardProp.enableHistory: true
                        KeyboardProp.historyKey: "login_user"

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

                // Field 2: Password Field (Lower position -> Auto Page Lift + Forced Alphanumeric + No History)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: window.isZh ? "安全密码 :" : "Password :"
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
                                         ? "强制锁定英数模式 · 隐藏候选栏 · 严禁历史记录"
                                         : "Forced Alphanumeric · No Candidates · No History"
                        font.pixelSize: 16
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                        placeholderTextColor: window.dark ? "#64748B" : "#94A3B8"
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 12
                        rightPadding: 12

                        // Even if someone sets enableHistory on a password field, InputEngine strictly blocks it
                        KeyboardProp.enableHistory: true
                        KeyboardProp.historyKey: "should_never_record"

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

                // Field 3: Bottom PLC Station / Batch Input (Demonstrates larger Page Lift + History + Symbols)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: window.isZh ? "工位/批次号 :" : "PLC Batch :"
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
                                         ? "位于界面底部 · 聚焦时自动向上平滑推顶防遮挡"
                                         : "Bottom field · Auto page-lift anti-occlusion test"
                        font.pixelSize: 16
                        font.family: "Microsoft YaHei UI"
                        color: window.dark ? "#F8FAFC" : "#0F172A"
                        placeholderTextColor: window.dark ? "#64748B" : "#94A3B8"
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 12
                        rightPadding: 12

                        KeyboardProp.enableHistory: true
                        KeyboardProp.historyKey: "plc_station_batch"

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
                            text: window.isZh ? "清空表单" : "Reset Fields"
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
                                window.statusToast = window.isZh ? "已清空所有输入内容" : "All fields cleared"
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
                            text: window.isZh ? "✓ 确认登录 (保存账号历史)" : "✓ Sign In (Save History)"
                            font.pixelSize: 15
                            font.bold: true
                            font.family: "Microsoft YaHei UI"
                            color: "#FFFFFF"
                        }

                        MouseArea {
                            id: loginBtnTouch
                            anchors.fill: parent
                            onClicked: {
                                if (userField.text.trim().length > 0) {
                                    InputEngine.commitHistory("login_user", userField.text)
                                }
                                if (stationField.text.trim().length > 0) {
                                    InputEngine.commitHistory("plc_station_batch", stationField.text)
                                }
                                vKeyboard.closeKeyboard()
                                window.statusToast = window.isZh
                                                     ? ("登录成功: " + (userField.text || "匿名操作员"))
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
