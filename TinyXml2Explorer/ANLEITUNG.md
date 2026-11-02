# TinyXML2 Explorer – Anleitung

Der Ordner enthält dieselbe einfache Qt-Anwendung in zwei Varianten:

- `Dynamic`: TinyXML2 wird als dynamische Bibliothek gebaut.
- `Static`: TinyXML2 wird als statische Bibliothek gebaut.

Beide Programme können eine XML-Datei auswählen, sie mit TinyXML2 lesen, ihre
Elemente im `QTreeWidget` anzeigen und beim Anklicken Attribute und Textinhalt darstellen.
Die grafische Oberfläche befindet sich in `src/mainwindow.ui` und kann mit dem
grafischen Designer von Qt Creator bearbeitet werden.

## Voraussetzungen

- Qt 6 mit Qt Widgets
- Qt Creator
- CMake
- ein C++17-Compiler

## Dynamische Variante in Qt Creator starten

1. Qt Creator öffnen.
2. **Datei > Datei oder Projekt öffnen** auswählen.
3. `TinyXml2Explorer/Dynamic/CMakeLists.txt` öffnen.
4. Ein installiertes Qt-6-Kit auswählen und auf **Projekt konfigurieren** klicken.
5. Mit dem grünen Startknopf oder `Strg+R`/`Cmd+R` bauen und starten.
6. Im Programm **XML-Datei öffnen …** anklicken und `beispiel.xml` auswählen.

Beim Build entsteht zusätzlich zur Anwendung eine dynamische Bibliothek:

- macOS: `libtinyxml2.11.dylib`
- Linux: `libtinyxml2.so.11`
- Windows: `tinyxml2.dll`

Diese Bibliothek wird beim Start der Anwendung zur Laufzeit geladen.

## Statische Variante in Qt Creator starten

1. In Qt Creator **Datei > Datei oder Projekt öffnen** auswählen.
2. `TinyXml2Explorer/Static/CMakeLists.txt` öffnen.
3. Ein Qt-6-Kit auswählen und das Projekt konfigurieren.
4. Das Projekt bauen und starten.
5. Wieder die mitgelieferte `beispiel.xml` öffnen.

Beim Build entsteht zunächst `libtinyxml2.a` auf macOS/Linux beziehungsweise
`tinyxml2.lib` unter Windows. Der TinyXML2-Code wird anschließend fest in die
Anwendung gelinkt. Deshalb braucht das fertige Programm zur Laufzeit keine
separate TinyXML2-Bibliothek.

## Oberfläche grafisch bearbeiten

1. Im Projektbaum den Ordner `src` öffnen.
2. `mainwindow.ui` doppelt anklicken.
3. In Qt Creator zum Modus **Design** wechseln.
4. Widgets mit der Maus verschieben oder ihre Eigenschaften rechts bearbeiten.

Die Oberfläche besteht nur aus einem Öffnen-Button, einer Dateianzeige, einem
`QTreeWidget` und einem schreibgeschützten `QTextEdit`.

## Wichtige Dateien

- `CMakeLists.txt`: beschreibt Build, Qt-Abhängigkeit und Bibliothekstyp.
- `src/main.cpp`: startet die Qt-Anwendung.
- `src/mainwindow.ui`: grafisch erstellte Benutzeroberfläche.
- `src/mainwindow.h`: Deklaration des Hauptfensters.
- `src/mainwindow.cpp`: Dateidialog, XML-Laden und Baumdarstellung.
- `third_party/tinyxml2/`: TinyXML2 11.0.0 samt Lizenz.
- `beispiel.xml`: Testdatei für die Anwendung.

## Unterschied im CMake-Code

In der dynamischen Variante steht:

```cmake
add_library(tinyxml2 SHARED ...)
```

In der statischen Variante steht:

```cmake
add_library(tinyxml2 STATIC ...)
```

Der übrige Anwendungscode ist in beiden Varianten gleich.
