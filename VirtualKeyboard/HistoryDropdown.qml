import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool active: false
    property bool darkTheme: true
    property var historyItems: []
    property real popupX: 0
    property real popupY: 0
    property real popupWidth: 280

    signal historySelected(string text)
    signal clearHistoryRequested()
    signal closeRequested()

    readonly property int rowHeight: 42
    readonly property int headerHeight: 34
    readonly property int maxVisibleRows: 3
    readonly property int visibleRowCount: Math.min(historyItems.length, maxVisibleRows)

    visible: active && historyItems.length > 0
    x: popupX
    y: popupY
    width: Math.max(240, popupWidth)
    height: headerHeight + visibleRowCount * rowHeight + 6
    z: 1000

    Rectangle {
        id: panelBg
        anchors.fill: parent
        radius: 8
        color: root.darkTheme ? "#1B2434" : "#FFFFFF"
        border.width: 1
        border.color: root.darkTheme ? "#3B82F6" : "#64748B"
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 2
            spacing: 0

            // Header bar with title and one-click clear button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.headerHeight
                radius: 6
                color: root.darkTheme ? "#111827" : "#F1F5F9"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: "⏱ 最近输入记录 (" + root.historyItems.length + ")"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Microsoft YaHei UI"
                        color: root.darkTheme ? "#94A3B8" : "#475569"
                        Layout.fillWidth: true
                    }

                    // One-click Clear History button
                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: clearText.implicitWidth + 16
                        radius: 4
                        color: clearTouch.pressed
                               ? "#DC2626"
                               : (root.darkTheme ? "#311B24" : "#FEE2E2")
                        border.width: 1
                        border.color: "#EF4444"

                        Text {
                            id: clearText
                            anchors.centerIn: parent
                            text: "清空记录"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: "Microsoft YaHei UI"
                            color: clearTouch.pressed
                                   ? "#FFFFFF"
                                   : (root.darkTheme ? "#FCA5A5" : "#B91C1C")
                        }

                        MouseArea {
                            id: clearTouch
                            anchors.fill: parent
                            onClicked: root.clearHistoryRequested()
                        }
                    }

                    // Close dropdown button
                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 4
                        color: closeTouch.pressed
                               ? (root.darkTheme ? "#334155" : "#CBD5E1")
                               : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 13
                            color: root.darkTheme ? "#94A3B8" : "#475569"
                        }

                        MouseArea {
                            id: closeTouch
                            anchors.fill: parent
                            onClicked: root.closeRequested()
                        }
                    }
                }
            }

            // Touch-friendly History List (rowHeight >= 42px)
            ListView {
                id: historyListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.historyItems

                delegate: Rectangle {
                    id: rowItem
                    required property string modelData
                    required property int index

                    width: historyListView.width
                    height: root.rowHeight
                    color: rowTouch.pressed
                           ? (root.darkTheme ? "#2563EB" : "#DBEAFE")
                           : (index % 2 === 1
                              ? (root.darkTheme ? "#1E293B" : "#F8FAFC")
                              : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: rowItem.modelData
                            font.pixelSize: 16
                            font.family: "Microsoft YaHei UI"
                            color: rowTouch.pressed && root.darkTheme
                                   ? "#FFFFFF"
                                   : (root.darkTheme ? "#F1F5F9" : "#0F172A")
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "填入 ↵"
                            font.pixelSize: 12
                            font.family: "Microsoft YaHei UI"
                            color: rowTouch.pressed && root.darkTheme
                                   ? "#E2E8F0"
                                   : (root.darkTheme ? "#60A5FA" : "#2563EB")
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: root.darkTheme ? "#263248" : "#E2E8F0"
                        visible: rowItem.index < root.historyItems.length - 1
                    }

                    MouseArea {
                        id: rowTouch
                        anchors.fill: parent
                        onClicked: root.historySelected(rowItem.modelData)
                    }
                }
            }
        }
    }
}

