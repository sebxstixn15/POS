cmake_minimum_required(VERSION 3.16)
project(UPN_Rechner LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOUIC ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)

add_executable(UPN_Rechner
    main.cpp
    mainwindow.cpp
    mainwindow.h
    mainwindow.ui
    rechner.cpp
    rechner.h
)

target_link_libraries(UPN_Rechner PRIVATE Qt${QT_VERSION_MAJOR}::Widgets)
