import QtQuick
import QtQuick.Layouts
import QtQuick.Window

Item {
    id: root

    // Optional reference to the host page content Item to lift up when an input is occluded
    property Item pageContainer: null
    // Exposed lift offset (positive means lifted up by pageLiftOffset px)
    property real pageLiftOffset: 0
    // Whether the keyboard is currently popped up
    property bool keyboardVisible: false
    // Current active text input item
    property Item activeInputItem: null
    // Current panel: 0 = QWERTY, 1 = 123 & Industrial Symbols, 2 = Extended Symbols
    property int panelIndex: 0
    // Whether history dropdown is allowed to show for current focus session
    property bool showHistoryPopup: false

    anchors.fill: parent
    z: 999

    readonly property bool darkTheme: InputEngine.darkTheme
    readonly property bool showCandidateBar: InputEngine.chineseMode && !InputEngine.passwordMode

    // Keyboard height takes ~46% of 7-inch screen when candidate bar is visible, ~38% when collapsed
    readonly property real panelHeight: {
        var baseRatio = showCandidateBar ? 0.47 : 0.39
        return Math.round(Math.max(185, Math.min(260, root.height * baseRatio)))
    }

    // Apply smooth page lift directly to pageContainer if provided
    Binding {
        target: root.pageContainer
        property: "y"
        value: -root.pageLiftOffset
        when: root.pageContainer !== null
    }

    Behavior on pageLiftOffset {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // Track Window.activeFocusItem automatically via attached property binding
    readonly property Item windowFocusItem: Window.activeFocusItem
    onWindowFocusItemChanged: {
        root.evaluateFocusItem(windowFocusItem)
    }

    Connections {
        target: InputEngine
        function onRequestShowKeyboard() {
            if (root.activeInputItem) {
                root.keyboardVisible = true
                if (InputEngine.historyEnabled && !InputEngine.passwordMode && InputEngine.historyList.length > 0) {
                    root.showHistoryPopup = true
                }
                root.updateGeometryAndLift()
            }
        }
        function onRequestHideKeyboard() {
            root.closeKeyboard()
        }
    }

    function evaluateFocusItem(item) {
        if (item && InputEngine.isTextInputItem(item) && InputEngine.isKeyboardEnabled(item)) {
            root.activeInputItem = item
            root.panelIndex = 0
            InputEngine.bindTargetItem(item)
            root.keyboardVisible = true
            root.showHistoryPopup = InputEngine.historyEnabled && !InputEngine.passwordMode && InputEngine.historyList.length > 0
            liftUpdateTimer.restart()
        } else if (!item || !isDescendantOfKeyboard(item)) {
            root.activeInputItem = null
            InputEngine.bindTargetItem(null)
            root.closeKeyboard()
        }
    }

    function isDescendantOfKeyboard(item) {
        var cur = item
        while (cur) {
            if (cur === root)
                return true
            cur = cur.parent
        }
        return false
    }

    function closeKeyboard() {
        root.keyboardVisible = false
        root.showHistoryPopup = false
        root.pageLiftOffset = 0
        InputEngine.clearPinyinBuffer()
    }

    // Calculate anti-occlusion lift offset and history popup coordinates
    function updateGeometryAndLift() {
        if (!root.keyboardVisible || !root.activeInputItem) {
            root.pageLiftOffset = 0
            return
        }

        // Map activeInputItem coordinates to root ( accounting for current pageLiftOffset )
        var posInRoot = root.activeInputItem.mapToItem(root, 0, 0)
        var unliftedTopY = posInRoot.y + root.pageLiftOffset
        var unliftedBottomY = unliftedTopY + root.activeInputItem.height

        var kbTopY = root.height - root.panelHeight
        var safetyMargin = 14

        if (unliftedBottomY + safetyMargin > kbTopY) {
            root.pageLiftOffset = Math.min(kbTopY - 40, unliftedBottomY + safetyMargin - kbTopY)
        } else {
            root.pageLiftOffset = 0
        }

        // Update history dropdown position relative to the lifted input position
        var liftedTopY = unliftedTopY - root.pageLiftOffset
        var liftedBottomY = unliftedBottomY - root.pageLiftOffset
        historyDropdown.popupX = Math.max(8, Math.min(root.width - root.activeInputItem.width - 8, posInRoot.x))
        historyDropdown.popupWidth = Math.max(240, root.activeInputItem.width)

        var dropdownHeight = historyDropdown.height
        if (liftedBottomY + dropdownHeight + 6 <= kbTopY) {
            historyDropdown.popupY = liftedBottomY + 4
        } else {
            historyDropdown.popupY = Math.max(6, liftedTopY - dropdownHeight - 4)
        }
    }

    Timer {
        id: liftUpdateTimer
        interval: 16
        repeat: false
        onTriggered: root.updateGeometryAndLift()
    }

    onPanelHeightChanged: {
        if (root.keyboardVisible) {
            root.updateGeometryAndLift()
        }
    }

    // History recommendation dropdown near the focused input field
    HistoryDropdown {
        id: historyDropdown
        active: root.keyboardVisible && root.showHistoryPopup && !InputEngine.passwordMode && InputEngine.historyEnabled
        darkTheme: root.darkTheme
        historyItems: InputEngine.historyList

        onHistorySelected: function(selectedText) {
            InputEngine.applyHistoryItem(selectedText)
            root.showHistoryPopup = false
        }

        onClearHistoryRequested: {
            InputEngine.clearCurrentHistory()
            root.showHistoryPopup = false
        }

        onCloseRequested: {
            root.showHistoryPopup = false
        }
    }

    // Main Keyboard Bottom Dock
    Rectangle {
        id: keyboardDock
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.panelHeight
        y: root.keyboardVisible ? (root.height - height) : root.height
        visible: y < root.height
        color: root.darkTheme ? "#141A26" : "#E2E8F0"
        border.width: 1
        border.color: root.darkTheme ? "#2B374B" : "#CBD5E1"

        Behavior on y {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        // Prevent clicks on keyboard background from stealing focus or passing through
        MouseArea {
            anchors.fill: parent
            onPressed: function(mouse) { mouse.accepted = true }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 1. Pinyin Candidate Bar (auto-collapses in English or Password mode)
            CandidateBar {
                id: candidateBar
                showBar: root.showCandidateBar
                darkTheme: root.darkTheme
                pinyinText: InputEngine.pinyinDisplay
                candidates: InputEngine.candidates
                hasPrevPage: InputEngine.hasPrevPage
                hasNextPage: InputEngine.hasNextPage

                onCandidateSelected: function(idx) {
                    InputEngine.selectCandidate(idx)
                }
                onPrevPageClicked: InputEngine.prevCandidatePage()
                onNextPageClicked: InputEngine.nextCandidatePage()
                onCloseKeyboardClicked: root.closeKeyboard()
            }

            // 2. Key Rows Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // ============================================================
                // PANEL 0: QWERTY Letter Keyboard
                // ============================================================
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 4
                    visible: root.panelIndex === 0

                    // Row 1: Q W E R T Y U I O P
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                            model: [
                                { k: "q", sub: "1" }, { k: "w", sub: "2" }, { k: "e", sub: "3" },
                                { k: "r", sub: "4" }, { k: "t", sub: "5" }, { k: "y", sub: "6" },
                                { k: "u", sub: "7" }, { k: "i", sub: "8" }, { k: "o", sub: "9" },
                                { k: "p", sub: "0" }
                            ]
                            delegate: KeyButton {
                                required property var modelData
                                text: InputEngine.capsLock ? modelData.k.toUpperCase() : modelData.k
                                subText: modelData.sub
                                darkTheme: root.darkTheme
                                onClicked: {
                                    root.showHistoryPopup = false
                                    InputEngine.handleKeyPress(text)
                                }
                            }
                        }
                    }

                    // Row 2: A S D F G H J K L
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: 22
                        Layout.rightMargin: 22
                        spacing: 4

                        Repeater {
                            model: ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
                            delegate: KeyButton {
                                required property string modelData
                                text: InputEngine.capsLock ? modelData.toUpperCase() : modelData
                                darkTheme: root.darkTheme
                                onClicked: {
                                    root.showHistoryPopup = false
                                    InputEngine.handleKeyPress(text)
                                }
                            }
                        }
                    }

                    // Row 3: CapsLock + Z X C V B N M + Backspace (Long-press auto-repeat)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        KeyButton {
                            text: "⇧ 大写"
                            isFunctionKey: true
                            isActiveState: InputEngine.capsLock
                            showStatusDot: true
                            statusActive: InputEngine.capsLock
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 74
                            onClicked: InputEngine.toggleCapsLock()
                        }

                        Repeater {
                            model: ["z", "x", "c", "v", "b", "n", "m"]
                            delegate: KeyButton {
                                required property string modelData
                                text: InputEngine.capsLock ? modelData.toUpperCase() : modelData
                                darkTheme: root.darkTheme
                                onClicked: {
                                    root.showHistoryPopup = false
                                    InputEngine.handleKeyPress(text)
                                }
                            }
                        }

                        KeyButton {
                            text: "⌫ 退格"
                            isFunctionKey: true
                            autoRepeat: true
                            repeatDelay: 400
                            repeatInterval: 50
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 78
                            onClicked: InputEngine.handleBackspace()
                        }
                    }

                    // Row 4: 123 | 中/英 | _ | Space | . | 收起 | 确定(Enter)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        KeyButton {
                            text: "123/符"
                            isFunctionKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 68
                            onClicked: {
                                InputEngine.clearPinyinBuffer()
                                root.panelIndex = 1
                            }
                        }

                        KeyButton {
                            text: InputEngine.passwordMode
                                  ? "🔒 英数"
                                  : (InputEngine.chineseMode ? "中 / 英" : "英 / 中")
                            isFunctionKey: true
                            isActiveState: InputEngine.chineseMode && !InputEngine.passwordMode
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 68
                            onClicked: InputEngine.toggleLanguageMode()
                        }

                        KeyButton {
                            text: "_"
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 46
                            onClicked: {
                                root.showHistoryPopup = false
                                InputEngine.handleSymbolPress("_")
                            }
                        }

                        KeyButton {
                            text: InputEngine.passwordMode
                                  ? "🔒 密码安全模式 (仅英数·禁历史)"
                                  : (InputEngine.chineseMode ? "空格 (中文拼音)" : "Space (English)")
                            isFunctionKey: true
                            fontPixelSize: 14
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 230
                            onClicked: {
                                root.showHistoryPopup = false
                                InputEngine.handleSpace()
                            }
                        }

                        KeyButton {
                            text: "."
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 46
                            onClicked: {
                                root.showHistoryPopup = false
                                InputEngine.handleSymbolPress(".")
                            }
                        }

                        KeyButton {
                            text: "▼ 收起"
                            isFunctionKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 66
                            onClicked: root.closeKeyboard()
                        }

                        KeyButton {
                            text: "↵ 确定"
                            isFunctionKey: true
                            isPrimaryKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 82
                            onClicked: {
                                InputEngine.handleEnter()
                                root.closeKeyboard()
                            }
                        }
                    }
                }

                // ============================================================
                // PANEL 1: 123 Numbers & High-Frequency Industrial Symbols
                // ============================================================
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 4
                    visible: root.panelIndex === 1

                    // Row 1: 1 2 3 4 5 6 7 8 9 0
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                            delegate: KeyButton {
                                required property string modelData
                                text: modelData
                                darkTheme: root.darkTheme
                                onClicked: {
                                    root.showHistoryPopup = false
                                    InputEngine.handleSymbolPress(modelData)
                                }
                            }
                        }
                    }

                    // Row 2: Industrial Common Symbols (_ @ - . / # : + = *)
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                            model: ["_", "@", "-", ".", "/", "#", ":", "+", "=", "*"]
                            delegate: KeyButton {
                                required property string modelData
                                text: modelData
                                darkTheme: root.darkTheme
                                onClicked: {
                                    root.showHistoryPopup = false
                                    InputEngine.handleSymbolPress(modelData)
                                }
                            }
                        }
                    }

                    // Row 3: More Symbols + ( ) [ ] % & ? ! + Backspace
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        KeyButton {
                            text: "#+= 更多"
                            isFunctionKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 76
                            onClicked: root.panelIndex = 2
                        }

                        Repeater {
                            model: ["(", ")", "[", "]", "%", "&", "?", "!"]
                            delegate: KeyButton {
                                required property string modelData
                                text: modelData
                                darkTheme: root.darkTheme
                                onClicked: {
                                    root.showHistoryPopup = false
                                    InputEngine.handleSymbolPress(modelData)
                                }
                            }
                        }

                        KeyButton {
                            text: "⌫ 退格"
                            isFunctionKey: true
                            autoRepeat: true
                            repeatDelay: 400
                            repeatInterval: 50
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 78
                            onClicked: InputEngine.handleBackspace()
                        }
                    }

                    // Row 4: ABC | 中/英 | , | Space | : | 收起 | 确定
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        KeyButton {
                            text: "ABC 返回"
                            isFunctionKey: true
                            isActiveState: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 76
                            onClicked: root.panelIndex = 0
                        }

                        KeyButton {
                            text: InputEngine.passwordMode ? "🔒 英数" : "中 / 英"
                            isFunctionKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 68
                            onClicked: {
                                root.panelIndex = 0
                                InputEngine.toggleLanguageMode()
                            }
                        }

                        KeyButton {
                            text: ","
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 46
                            onClicked: InputEngine.handleSymbolPress(",")
                        }

                        KeyButton {
                            text: "Space 空格"
                            isFunctionKey: true
                            fontPixelSize: 14
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 222
                            onClicked: InputEngine.handleSpace()
                        }

                        KeyButton {
                            text: ";"
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 46
                            onClicked: InputEngine.handleSymbolPress(";")
                        }

                        KeyButton {
                            text: "▼ 收起"
                            isFunctionKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 66
                            onClicked: root.closeKeyboard()
                        }

                        KeyButton {
                            text: "↵ 确定"
                            isFunctionKey: true
                            isPrimaryKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 82
                            onClicked: {
                                InputEngine.handleEnter()
                                root.closeKeyboard()
                            }
                        }
                    }
                }

                // ============================================================
                // PANEL 2: Extended Industrial Symbols Keyboard
                // ============================================================
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 4
                    visible: root.panelIndex === 2

                    // Row 1
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                            model: ["~", "`", "!", "@", "#", "$", "%", "^", "&", "*"]
                            delegate: KeyButton {
                                required property string modelData
                                text: modelData
                                darkTheme: root.darkTheme
                                onClicked: InputEngine.handleSymbolPress(modelData)
                            }
                        }
                    }

                    // Row 2
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                            model: ["{", "}", "[", "]", "<", ">", "|", "\\", "/", "?"]
                            delegate: KeyButton {
                                required property string modelData
                                text: modelData
                                darkTheme: root.darkTheme
                                onClicked: InputEngine.handleSymbolPress(modelData)
                            }
                        }
                    }

                    // Row 3
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        KeyButton {
                            text: "123 数字"
                            isFunctionKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 76
                            onClicked: root.panelIndex = 1
                        }

                        Repeater {
                            model: ["'", "\"", ":", ";", ",", ".", "-", "_"]
                            delegate: KeyButton {
                                required property string modelData
                                text: modelData
                                darkTheme: root.darkTheme
                                onClicked: InputEngine.handleSymbolPress(modelData)
                            }
                        }

                        KeyButton {
                            text: "⌫ 退格"
                            isFunctionKey: true
                            autoRepeat: true
                            repeatDelay: 400
                            repeatInterval: 50
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 78
                            onClicked: InputEngine.handleBackspace()
                        }
                    }

                    // Row 4
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        KeyButton {
                            text: "ABC 返回"
                            isFunctionKey: true
                            isActiveState: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 76
                            onClicked: root.panelIndex = 0
                        }

                        KeyButton {
                            text: "+"
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 56
                            onClicked: InputEngine.handleSymbolPress("+")
                        }

                        KeyButton {
                            text: "="
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 56
                            onClicked: InputEngine.handleSymbolPress("=")
                        }

                        KeyButton {
                            text: "Space 空格"
                            isFunctionKey: true
                            fontPixelSize: 14
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 242
                            onClicked: InputEngine.handleSpace()
                        }

                        KeyButton {
                            text: "±"
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 46
                            onClicked: InputEngine.handleSymbolPress("±")
                        }

                        KeyButton {
                            text: "▼ 收起"
                            isFunctionKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 66
                            onClicked: root.closeKeyboard()
                        }

                        KeyButton {
                            text: "↵ 确定"
                            isFunctionKey: true
                            isPrimaryKey: true
                            darkTheme: root.darkTheme
                            Layout.preferredWidth: 82
                            onClicked: {
                                InputEngine.handleEnter()
                                root.closeKeyboard()
                            }
                        }
                    }
                }
            }
        }
    }
}

