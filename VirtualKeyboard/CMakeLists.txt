cmake_minimum_required(VERSION 3.16)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Concurrent)

qt_add_library(VirtualKeyboard STATIC)

qt_add_qml_module(VirtualKeyboard
    URI VirtualKeyboard
    VERSION 1.0
    SOURCES
        KeyboardAttached.h
        KeyboardAttached.cpp
        InputEngine.h
        InputEngine.cpp
        pinyin/PinyinDecoder.h
        pinyin/PinyinDecoder.cpp
    QML_FILES
        VirtualKeyboard.qml
        CandidateBar.qml
        KeyButton.qml
    RESOURCES
        pinyin.txt
)

target_include_directories(VirtualKeyboard PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(VirtualKeyboard
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Quick
        Qt6::Concurrent
)
