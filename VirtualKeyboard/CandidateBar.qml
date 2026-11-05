import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property bool showBar: true
    property bool darkTheme: true
    property string pinyinText: ""
    property var candidates: []
    property bool hasPrevPage: false
    property bool hasNextPage: false

    signal candidateSelected(int index)
    signal prevPageClicked()
    signal nextPageClicked()
    signal closeKeyboardClicked()

    implicitHeight: showBar ? 48 : 0
    Layout.fillWidth: true
    Layout.preferredHeight: showBar ? 48 : 0
    Layout.minimumHeight: showBar ? 48 : 0
    Layout.maximumHeight: showBar ? 48 : 0
    visible: showBar
    clip: true

    color: darkTheme ? "#182030" : "#E2E8F0"
    border.width: showBar ? 1 : 0
    border.color: darkTheme ? "#2B374F" : "#CBD5E1"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        // Pre-edit Pinyin display pill
        Rectangle {
            visible: root.pinyinText.length > 0
            Layout.preferredHeight: 34
            Layout.preferredWidth: Math.max(76, pinyinLabel.implicitWidth + 24)
            Layout.alignment: Qt.AlignVCenter
            radius: 6
            color: root.darkTheme ? "#0F172A" : "#FFFFFF"
            border.width: 2
            border.color: "#3B82F6"

            Text {
                id: pinyinLabel
                anchors.centerIn: parent
                text: root.pinyinText
                font.pixelSize: 17
                font.bold: true
                font.family: "Consolas"
                color: root.darkTheme ? "#60A5FA" : "#1D4ED8"
            }
        }

        // Empty hint when in Chinese mode with no active pinyin input
        Text {
            visible: root.pinyinText.length === 0 && root.candidates.length === 0
            text: "中文拼音模式 · 请点击下方字母输入拼音"
            font.pixelSize: 14
            font.family: "Microsoft YaHei UI"
            color: root.darkTheme ? "#94A3B8" : "#475569"
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Touch-friendly horizontal flickable candidate list
        ListView {
            id: candidateListView
            visible: root.candidates.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: height
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
                width: Math.max(58, candText.implicitWidth + 24)
                y: Math.round((candidateListView.height - height) / 2)
                radius: 6
                color: candTouch.pressed
                       ? (root.darkTheme ? "#2563EB" : "#3B82F6")
                       : (index === 0 && root.pinyinText.length > 0
                          ? (root.darkTheme ? "#263554" : "#DBEAFE")
                          : (root.darkTheme ? "#232D42" : "#F8FAFC"))
                border.width: 1
                border.color: index === 0 && root.pinyinText.length > 0
                              ? "#3B82F6"
                              : (root.darkTheme ? "#334155" : "#CBD5E1")
                scale: candTouch.pressed ? 0.95 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: 50 }
                }

                Row {
                    id: candText
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: (candItem.index + 1) + "."
                        font.pixelSize: 13
                        font.family: "Consolas"
                        color: candTouch.pressed
                               ? "#E2E8F0"
                               : (root.darkTheme ? "#94A3B8" : "#64748B")
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: candItem.modelData
                        font.pixelSize: 18
                        font.bold: candItem.index === 0
                        font.family: "Microsoft YaHei UI"
                        color: candTouch.pressed
                               ? "#FFFFFF"
                               : (root.darkTheme ? "#F8FAFC" : "#0F172A")
                        anchors.verticalCenter: parent.verticalCenter
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
                    anchors.centerIn: parent
                    text: "◀"
                    font.pixelSize: 15
                    color: root.darkTheme ? "#F1F5F9" : "#1E293B"
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
                    anchors.centerIn: parent
                    text: "▶"
                    font.pixelSize: 15
                    color: root.darkTheme ? "#F1F5F9" : "#1E293B"
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
