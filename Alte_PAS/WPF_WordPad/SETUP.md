# WPF WordPad – Setup & Starten

## Voraussetzungen
- **Windows 10/11**
- **.NET 8 SDK** → https://dotnet.microsoft.com/download/dotnet/8.0
- **Visual Studio 2022** (empfohlen) oder VS Code mit C#-Extension

---

## Projekt öffnen & starten

### Option A – Visual Studio 2022
1. Doppelklick auf **`WPF_WordPad.csproj`**
2. NuGet-Pakete werden automatisch wiederhergestellt
3. **F5** drücken → Projekt wird gebaut und gestartet

### Option B – Kommandozeile
```bash
cd WPF_WordPad
dotnet restore
dotnet run
```

---

## Icons hinzufügen (optional)
- Lade kostenlose Icons von https://icons8.com oder https://materialdesignicons.com
- Benötigte Dateinamen: siehe `Icons/README_ICONS.txt`
- Alle Icons als **32×32 PNG** in den Ordner `Icons/` legen
- Das Projekt kompiliert auch ohne Icons (dann erscheinen nur Labels, keine Bilder)

---

## Projektstruktur
```
WPF_WordPad/
├── WPF_WordPad.csproj        ← Projektdatei (.NET 8, WPF)
├── App.xaml / App.xaml.cs    ← Application-Einstiegspunkt
├── MainWindow.xaml           ← UI: Fluent Ribbon + RichTextBox
├── MainWindow.xaml.cs        ← Code-Behind: alle Aktionen
├── Themes/
│   └── Styles.xaml           ← WPF Styles + Trigger (einheitliches Design)
└── Icons/
    ├── README_ICONS.txt      ← Anleitung zu Icons
    └── *.png                 ← (selbst hinzufügen)
```

---

## Funktionen

| Bereich | Funktion |
|---------|----------|
| **Datei** | Neu, Öffnen, Speichern (XAML-Format), Speichern unter, Drucken, Zuletzt geöffnet |
| **Bearbeiten** | Kopieren, Ausschneiden, Einfügen, Rückgängig, Wiederholen, Alles auswählen |
| **Format** | Fett, Kursiv, Unterstrichen, Durchgestrichen, Hoch-/Tiefgestellt |
| **Format** | Schriftart (Dropdown), Schriftgröße (Spinner), Schriftfarbe, Hintergrundfarbe |
| **Format** | Links/Zentriert/Rechts/Blocksatz, Aufzählungsliste, Nummerierte Liste, Einzug |
| **Einfügen** | Bild (PNG/JPG/BMP), Datum & Uhrzeit |
| **Ansicht** | Zoom +/−/100%, Statusleiste, Zeilenumbruch, Rechtschreibprüfung |
| **Suchen** | Suchen & Ersetzen (Panel unten), Vorwärts/Rückwärts, Alle ersetzen |
| **Statusleiste** | Dateiname, Wörter, Zeichen, Zoom, Geändert-Indikator |
| **Tastenkürzel** | Ctrl+S (Speichern), Ctrl+F (Suchen), Ctrl+H (Ersetzen) |

---

## NuGet-Pakete
| Paket | Verwendung |
|-------|-----------|
| `Fluent.Ribbon` 10.0.3 | Ribbon-Steuerlement (Office-ähnlich) |
| `Extended.Wpf.Toolkit` 4.6.1 | `IntegerUpDown` (Schriftgröße), `ColorPicker` (Farben) |
