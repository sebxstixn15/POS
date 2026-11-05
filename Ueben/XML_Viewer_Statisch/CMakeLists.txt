cmake_minimum_required(VERSION 3.16)
project(XML_Viewer_Statisch LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)

add_library(tinyxml2 STATIC tinyxml2/tinyxml2.cpp)
target_include_directories(tinyxml2 PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/tinyxml2)

add_executable(XML_Viewer_Statisch main.cpp mainwindow.cpp mainwindow.h mainwindow.ui)
target_link_libraries(XML_Viewer_Statisch PRIVATE Qt${QT_VERSION_MAJOR}::Widgets tinyxml2)
