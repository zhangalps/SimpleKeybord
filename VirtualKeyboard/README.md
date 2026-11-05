# VirtualKeyboard 7寸工控触摸屏虚拟键盘插件集成指南

`VirtualKeyboard` 是专为 7 寸横屏（800×480 / 1024×600）工业上位机设计的轻量级 Qt 6 / QML 中英文虚拟键盘模块。模块内置异步拼音词库解析、全局焦点自动接管、防遮挡页面平滑推顶（Page Lift）、密码框强制英数安全模式以及历史输入记忆补全。

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
    ├── CandidateBar.qml            # 拼音预编辑与大触控候选词栏
    ├── HistoryDropdown.qml         # 历史输入推荐下拉弹窗
    └── KeyButton.qml               # 工控触控按键组件
```

---

## 2. 三步快速集成

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

### 第二步：在 `main.cpp` 中配置应用标识

历史输入记录功能基于 `QSettings` 持久化存储，请在 `main.cpp` 启动时设置组织名与应用名：

```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // 必须设置 OrganizationName 和 ApplicationName，用于持久化保存历史输入记录
    QCoreApplication::setOrganizationName(QStringLiteral("YourCompany"));
    QCoreApplication::setApplicationName(QStringLiteral("YourHMIApp"));

    QQmlApplicationEngine engine;
    engine.loadFromModule("YourModule", "Main");
    return QGuiApplication::exec();
}
```

### 第三步：在主窗口 QML 中挂载 `VirtualKeyboard`

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
            x: 100; y: 80; width: 300; height: 44
            placeholderText: "普通输入（默认跟随系统语言）"
        }

        // 开启历史记录记忆的输入框（如登录用户名、批次号）
        TextField {
            x: 100; y: 160; width: 300; height: 44
            placeholderText: "请输入操作员账号"
            KeyboardProp.enableHistory: true
            KeyboardProp.historyKey: "login_user"
        }

        // 密码框：自动识别 echoMode，强制英数模式、隐藏候选栏、严禁记录历史
        TextField {
            x: 100; y: 320; width: 300; height: 44
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

## 3. 附加属性 `KeyboardProp` 配置说明

你可以为任意 `TextInput` / `TextField` 附加 `KeyboardProp` 属性来微调行为：

| 附加属性 | 类型 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- |
| `KeyboardProp.enabled` | `bool` | `true` | 是否允许该输入框唤起虚拟键盘；设为 `false` 时点击该框不弹出软键盘 |
| `KeyboardProp.enableHistory` | `bool` | `false` | 是否为该输入框开启历史输入下拉推荐框（密码框下强制失效） |
| `KeyboardProp.historyKey` | `string` | `""` | 历史记录独立存储的键名（若不填则默认取控件的 `objectName`） |

> **注意**：当用户点击键盘右下角的 **`↵ 确定`** 键时，若当前输入框开启了 `KeyboardProp.enableHistory: true` 且非密码框，当前输入文本会自动去重并置顶写入对应 `historyKey` 的历史列表中（最多保留 10 条）。也可以在业务按钮（如“登录”按钮）中主动调用 `InputEngine.commitHistory("login_user", userField.text)` 保存。

---

## 4. 全局单例 `InputEngine` 接口参考

在 QML 任意位置可直接访问 `InputEngine` 单例，用于与上位机全局状态联动：

### 常用属性

| 属性名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `InputEngine.globalLanguage` | `string` | 上位机全局语言（`"zh_CN"` 默认开启中文拼音；`"en_US"` 默认进入英文模式并折叠候选栏） |
| `InputEngine.darkTheme` | `bool` | 键盘主题配色（`true` 为工控深色高对比度风格，`false` 为现代浅色风格） |
| `InputEngine.dictionaryReady` | `bool` | 后台线程词库是否已加载完成（只读） |
| `InputEngine.chineseMode` | `bool` | 当前是否处于中文拼音输入态 |
| `InputEngine.passwordMode` | `bool` | 当前焦点是否为密码框安全模式（只读） |

### 常用方法

- `InputEngine.commitHistory(key, value)`：手动保存一条历史记录到指定 `key`。
- `InputEngine.clearHistory(key)`：清空指定 `key` 的历史记录。
- `vKeyboard.closeKeyboard()`：主动收起虚拟键盘并复位页面推顶偏移。
