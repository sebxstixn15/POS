cmake_minimum_required(VERSION 3.16)

project(libMath_S LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core)

add_library(libMath_S STATIC
  libmath_s.cpp
  libmath_s.h
)

target_include_directories(libMath_S PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(libMath_S PRIVATE Qt${QT_VERSION_MAJOR}::Core)

target_compile_definitions(libMath_S PRIVATE LIBMATH_S_LIBRARY)

if(MSVC)
    target_compile_options(libMath_S PRIVATE /bigobj)
endif()
