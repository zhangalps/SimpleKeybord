import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool showBar: false
    property bool darkTheme: true
    property string pinyinText: ""
    property var candidates: []
    property bool hasPrevPage: false
    property bool hasNextPage: false

    signal candidateSelected(int index)
    signal prevPageClicked()
    signal nextPageClicked()

    height: 48
    visible: showBar && (pinyinText.length > 0 || candidates.length > 0)
    clip: true

    color: darkTheme ? "#182030" : "#E2E8F0"
    border.width: 1
    border.color: darkTheme ? "#2B374F" : "#CBD5E1"

    // Prevent clicks on candidate bar background from passing through to underlying page
    MouseArea {
        anchors.fill: parent
        onPressed: function(mouse) { mouse.accepted = true }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // Pre-edit Pinyin display pill (strictly 36px height, vertically centered in 48px bar)
        Rectangle {
            visible: root.pinyinText.length > 0
            Layout.preferredHeight: 36
            Layout.preferredWidth: Math.max(76, pinyinLabel.implicitWidth + 24)
            Layout.alignment: Qt.AlignVCenter
            radius: 6
            color: root.darkTheme ? "#0F172A" : "#FFFFFF"
            border.width: 2
            border.color: "#3B82F6"

            Text {
                id: pinyinLabel
                anchors.fill: parent
                text: root.pinyinText
                font.pixelSize: 17
                font.bold: true
                font.family: "Consolas"
                color: root.darkTheme ? "#60A5FA" : "#1D4ED8"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Touch-friendly horizontal flickable candidate list (strictly 36px height, vertically centered)
        ListView {
            id: candidateListView
            visible: root.candidates.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.candidates

            delegate: Rectangle {
                id: candItem
                required property string modelData
                required property int index

                height: 36
                width: Math.max(58, candRow.implicitWidth + 24)
                radius: 6
                color: candTouch.pressed
                       ? (root.darkTheme ? "#2563EB" : "#3B82F6")
                       : (index === 0
                          ? (root.darkTheme ? "#263554" : "#DBEAFE")
                          : (root.darkTheme ? "#232D42" : "#F8FAFC"))
                border.width: 1
                border.color: index === 0
                              ? "#3B82F6"
                              : (root.darkTheme ? "#334155" : "#CBD5E1")
                scale: candTouch.pressed ? 0.95 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 50 }
                }

                RowLayout {
                    id: candRow
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 3

                    Text {
                        text: (candItem.index + 1) + "."
                        font.pixelSize: 13
                        font.family: "Consolas"
                        color: candTouch.pressed
                               ? "#E2E8F0"
                               : (root.darkTheme ? "#94A3B8" : "#64748B")
                        Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: candItem.modelData
                        font.pixelSize: 18
                        font.bold: candItem.index === 0
                        font.family: "Microsoft YaHei UI"
                        color: candTouch.pressed
                               ? "#FFFFFF"
                               : (root.darkTheme ? "#F8FAFC" : "#0F172A")
                        Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                MouseArea {
                    id: candTouch
                    anchors.fill: parent
                    onClicked: root.candidateSelected(candItem.index)
                }
            }
        }

        // Page navigation buttons (Prev / Next)
        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter
                radius: 6
                visible: root.candidates.length > 0 || root.hasPrevPage || root.hasNextPage
                enabled: root.hasPrevPage
                opacity: enabled ? 1.0 : 0.35
                color: prevTouch.pressed
                       ? "#2563EB"
                       : (root.darkTheme ? "#243046" : "#FFFFFF")
                border.width: 1
                border.color: root.darkTheme ? "#36435C" : "#94A3B8"

                Text {
                    anchors.fill: parent
                    text: "\u25c0"
                    font.pixelSize: 15
                    color: root.darkTheme ? "#F1F5F9" : "#1E293B"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: prevTouch
                    anchors.fill: parent
                    onClicked: root.prevPageClicked()
                }
            }

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 36
                Layout.alignment: Qt.AlignVCenter
                radius: 6
                visible: root.candidates.length > 0 || root.hasPrevPage || root.hasNextPage
                enabled: root.hasNextPage
                opacity: enabled ? 1.0 : 0.35
                color: nextTouch.pressed
                       ? "#2563EB"
                       : (root.darkTheme ? "#243046" : "#FFFFFF")
                border.width: 1
                border.color: root.darkTheme ? "#36435C" : "#94A3B8"

                Text {
                    anchors.fill: parent
                    text: "\u25b6"
                    font.pixelSize: 15
                    color: root.darkTheme ? "#F1F5F9" : "#1E293B"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: nextTouch
                    anchors.fill: parent
                    onClicked: root.nextPageClicked()
                }
            }
        }
    }
}
