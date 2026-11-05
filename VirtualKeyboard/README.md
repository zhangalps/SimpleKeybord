# VirtualKeyboard 7寸工控触摸屏虚拟键盘插件集成指南

`VirtualKeyboard` 是专为 7 寸横屏（800×480 / 1024×600）工业上位机设计的轻量级 Qt 6 / QML 中英文虚拟键盘模块。模块内置异步拼音词库解析、全局焦点自动接管、按需显示的拼音候选词栏、防遮挡页面平滑推顶（Page Lift）以及密码框强制英数安全模式。

---

## 1. 目录结构

将整个 `VirtualKeyboard` 文件夹直接复制到你的上位机工程根目录下即可：

```text
YourProject/
├── CMakeLists.txt
├── main.cpp
├── Main.qml
└── VirtualKeyboard/                # 复制此目录到你的工程中
    ├── CMakeLists.txt              # 模块构建配置 (URI: VirtualKeyboard)
    ├── InputEngine.h / .cpp        # C++ 输入法核心单例
    ├── KeyboardAttached.h / .cpp   # KeyboardProp 附加属性定义
    ├── pinyin.txt                  # 拼音词库文件 (自动打包进 QRC 资源)
    ├── pinyin/
    │   └── PinyinDecoder.h / .cpp  # 异步词库加载与拼音分词检索内核
    ├── VirtualKeyboard.qml         # 虚拟键盘主组件
    ├── CandidateBar.qml            # 拼音预编辑与大触控候选词栏（有拼音输入时自动显示）
    └── KeyButton.qml               # 工控触控按键组件
```

---

## 2. 两步快速集成

### 第一步：修改主工程 `CMakeLists.txt`

在主工程的 `CMakeLists.txt` 中添加 `Concurrent` 组件，通过 `add_subdirectory(VirtualKeyboard)` 引入子模块，并将 `VirtualKeyboardplugin` 链接到你的主程序目标：

```cmake
# 1. 确保查找 Concurrent 模块（用于后台线程异步加载词库）
find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Concurrent)

# 2. MSVC 环境下建议开启 /utf-8 编译选项
if(MSVC)
    add_compile_options(/utf-8)
endif()

# 3. 引入 VirtualKeyboard 子模块
add_subdirectory(VirtualKeyboard)

# ... 你的可执行程序定义 qt_add_executable(yourApp ...) ...

# 4. 链接 VirtualKeyboardplugin
target_link_libraries(yourApp
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Concurrent
        VirtualKeyboardplugin
)
```

### 第二步：在主窗口 QML 中挂载 `VirtualKeyboard`

在顶层 `ApplicationWindow` 或 `Window` 中导入 `VirtualKeyboard`，将页面内容包裹在一个容器 `Item` 中并赋值给 `pageContainer`，即可实现全局输入框自动唤起键盘及防遮挡平滑推顶：

```qml
import QtQuick
import QtQuick.Controls.Basic
import VirtualKeyboard

ApplicationWindow {
    id: window
    width: 800
    height: 480
    visible: true

    // 1. 页面主内容容器（供键盘弹出时自动向上推顶防遮挡）
    Item {
        id: mainPageContainer
        width: parent.width
        height: parent.height

        // 普通输入框：无需任何额外代码，点击自动弹出键盘
        TextField {
            x: 100; y: 120; width: 320; height: 44
            placeholderText: "请输入操作员账号"
        }

        // 密码框：自动识别 echoMode，强制锁定英数模式、禁用拼音候选栏
        TextField {
            x: 100; y: 300; width: 320; height: 44
            echoMode: TextInput.Password
            placeholderText: "请输入安全密码"
        }
    }

    // 2. 全局挂载虚拟键盘实例（整个窗口只需挂载一个）
    VirtualKeyboard {
        id: vKeyboard
        pageContainer: mainPageContainer
    }
}
```

---

## 3. 附加属性与全局接口参考

### 3.1 附加属性 `KeyboardProp.enabled`

如果某个特殊输入框不需要弹出虚拟键盘（如扫码枪专用隐藏输入框），可附加 `KeyboardProp.enabled: false`：

```qml
TextField {
    KeyboardProp.enabled: false
}
```

### 3.2 全局单例 `InputEngine` 常用属性

| 属性名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `InputEngine.globalLanguage` | `string` | 上位机全局语言（`"zh_CN"` 默认开启中文拼音；`"en_US"` 默认进入英文模式） |
| `InputEngine.darkTheme` | `bool` | 键盘主题配色（`true` 为工控深色高对比度风格，`false` 为现代浅色风格） |
| `InputEngine.dictionaryReady` | `bool` | 后台线程词库是否已加载完成（只读） |
| `InputEngine.chineseMode` | `bool` | 当前是否处于中文拼音输入态 |
| `InputEngine.passwordMode` | `bool` | 当前焦点是否为密码框安全模式（只读） |
