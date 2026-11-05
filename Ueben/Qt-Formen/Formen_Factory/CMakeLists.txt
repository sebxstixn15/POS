cmake_minimum_required(VERSION 3.16)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    project(Formen_Factory LANGUAGES CXX)
    set(CMAKE_CXX_STANDARD 17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
    find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)
endif()

add_library(Formen_Factory SHARED factory.cpp factory.h form.cpp form.h)
target_compile_definitions(Formen_Factory PRIVATE FORMEN_LIBRARY)
target_include_directories(Formen_Factory PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(Formen_Factory PUBLIC Qt${QT_VERSION_MAJOR}::Widgets)
set_target_properties(Formen_Factory PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
