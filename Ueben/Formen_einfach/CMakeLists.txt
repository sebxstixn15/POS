cmake_minimum_required(VERSION 3.16)
project(Formen_einfach LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOUIC ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)

add_executable(Formen_einfach
    main.cpp
    mainwindow.cpp
    mainwindow.h
    mainwindow.ui
    formen.h
    rechteck.cpp
    quadrat.cpp
    kreis.cpp
    kreissegment.cpp
    trapez.cpp
    parallelogramm.cpp
    dreieck.cpp
    sechseck.cpp
    raute.cpp
    polygon.cpp
    stern.cpp
    ellipse.cpp
    varianten.h
    varianten.cpp
    bekannteformen.h
    halbkreis.cpp
    viertelkreis.cpp
    ring.cpp
    fuenfeck.cpp
    achteck.cpp
    drachenviereck.cpp
    kreisbogen.cpp
    kreisabschnitt.cpp
    variante_gleichseitigesdreieck.cpp
    variante_rechtwinkligesdreieck.cpp
    variante_gleichschenkligrechtwinkligesdreieck.cpp
    variante_spitzwinkligesdreieck.cpp
    variante_stumpfwinkligesdreieck.cpp
    variante_goldenesdreieck.cpp
)

target_link_libraries(Formen_einfach PRIVATE Qt${QT_VERSION_MAJOR}::Widgets)
