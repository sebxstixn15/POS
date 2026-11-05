cmake_minimum_required(VERSION 3.16)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(Formen_Plugin LANGUAGES CXX)
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
    find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)
endif()

if(NOT TARGET Formen_Factory)
    add_subdirectory(../Formen_Factory ${CMAKE_CURRENT_BINARY_DIR}/Formen_Factory)
endif()

add_library(Formen_Plugin SHARED
    circle.cpp circle.h
    square.cpp square.h
    register.cpp register.h)
target_compile_definitions(Formen_Plugin PRIVATE PLUGIN_LIBRARY)
target_link_libraries(Formen_Plugin PRIVATE Formen_Factory)
set_target_properties(Formen_Plugin PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/plugins
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin/plugins)
