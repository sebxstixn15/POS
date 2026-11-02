cmake_minimum_required(VERSION 3.21)
project(TinyXml2ExplorerDynamic VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

add_library(tinyxml2 SHARED
    third_party/tinyxml2/tinyxml2.cpp
    third_party/tinyxml2/tinyxml2.h
)
target_include_directories(tinyxml2 PUBLIC third_party/tinyxml2)
target_compile_definitions(tinyxml2 PRIVATE TINYXML2_EXPORT)
target_compile_definitions(tinyxml2 INTERFACE TINYXML2_IMPORT)
set_target_properties(tinyxml2 PROPERTIES
    VERSION 11.0.0
    SOVERSION 11
    WINDOWS_EXPORT_ALL_SYMBOLS ON
)

qt_add_executable(TinyXml2Explorer
    src/main.cpp
    src/mainwindow.cpp
    src/mainwindow.h
    src/mainwindow.ui
)
target_link_libraries(TinyXml2Explorer PRIVATE Qt6::Widgets tinyxml2)

set_target_properties(TinyXml2Explorer PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

install(TARGETS TinyXml2Explorer tinyxml2
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
)
