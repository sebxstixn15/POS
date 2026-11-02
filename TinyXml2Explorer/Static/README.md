# TinyXML2 Explorer – statische Variante

Diese Qt-6-Widgets-Anwendung erfüllt nur die Grundaufgabe:

1. Eine XML-Datei wird mit einem `QFileDialog` ausgewählt.
2. TinyXML2 öffnet und liest die Datei.
3. Die XML-Tags erscheinen in einem `QTreeWidget`.
4. Beim Anklicken eines Tags werden rechts seine Attribute und sein Textinhalt angezeigt.

TinyXML2 wird in dieser Variante als statische Bibliothek (`STATIC`) gebaut und
direkt in die Anwendung gelinkt. Die Erweiterungen zum Bearbeiten und Speichern
von Attributen sind bewusst nicht enthalten.

## In Qt Creator

1. `CMakeLists.txt` über **Datei > Datei oder Projekt öffnen** auswählen.
2. Das installierte Qt-6.11.2-Kit wählen und das Projekt konfigurieren.
3. Ziel `TinyXml2Explorer` bauen und starten.
4. Mit **XML-Datei öffnen …** z. B. `beispiel.xml` auswählen.

Die statische Bibliothek entsteht beim Bauen als `libtinyxml2.a` (macOS/Linux)
bzw. `tinyxml2.lib` (Windows). Zur Laufzeit wird keine separate TinyXML2-Datei benötigt.

## Erklärung aller Dateien

### `CMakeLists.txt`

Das ist die Projektbeschreibung für CMake und Qt Creator. Sie legt C++17 fest,
sucht Qt 6 Widgets, baut `tinyxml2.cpp` als statische Bibliothek und verbindet
diese Bibliothek anschließend mit der Anwendung `TinyXml2Explorer`.

### `src/main.cpp`

Das ist der Startpunkt des Programms. Hier wird `QApplication` erzeugt, das
Hauptfenster erstellt und mit `show()` angezeigt. `app.exec()` startet die
Qt-Ereignisschleife und hält die Anwendung am Laufen.

### `src/mainwindow.h`

Diese Headerdatei beschreibt die Klasse `MainWindow`. Sie enthält die
Deklarationen der Funktionen und die Zeiger auf Baumansicht, Textfeld und
Dateianzeige. Außerdem wird hier das TinyXML2-Dokument gespeichert.

### `src/mainwindow.ui`

Diese Datei enthält die grafische Oberfläche. Sie lässt sich in Qt Creator im
Modus **Design** öffnen. Button, Beschriftungen, Baumansicht, Textfeld, Splitter
und Layouts wurden hier grafisch angeordnet und nicht in C++ erzeugt.

### `src/mainwindow.cpp`

Hier steckt die eigentliche Programmlogik:

- `openXmlFile()` zeigt den Dateidialog und lädt die ausgewählte Datei.
- `addElement()` fügt ein XML-Element und seine Kind-Elemente rekursiv in den Baum ein.
- `selectionChanged()` reagiert auf die Auswahl eines Baumeintrags.
- `showElementDetails()` zeigt Attribute und Textinhalt des gewählten Elements an.

### `third_party/tinyxml2/tinyxml2.h`

Die Headerdatei der externen TinyXML2-Bibliothek. Sie deklariert beispielsweise
`XMLDocument`, `XMLElement` und `XMLAttribute`.

### `third_party/tinyxml2/tinyxml2.cpp`

Die Implementierung von TinyXML2. CMake kompiliert diese Datei zur dynamischen
Bibliothek. An dieser Datei muss für die Aufgabe nichts geändert werden.

### `third_party/tinyxml2/LICENSE.txt`

Die Lizenz von TinyXML2. Sie wird mitgeliefert, weil TinyXML2 fremder Quellcode ist.

### `beispiel.xml`

Eine kleine XML-Datei mit Büchern, Titeln, Autoren und Attributen. Sie kann direkt
zum Testen im Dateidialog ausgewählt werden.

### `.gitignore`

Legt fest, welche automatisch erzeugten Dateien Git ignorieren soll, zum Beispiel
Build-Verzeichnisse und persönliche Qt-Creator-Einstellungen.
