#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  create-csv-app.sh
#  Erstellt automatisch ein WPF CRUD-Projekt aus einer .csv Datei.
#
#  Verwendung:
#    ./create-csv-app.sh <Daten.csv> [ProjektName]
#
#  Was passiert:
#    1. Liest die Header der CSV-Datei aus.
#    2. Generiert ein C# Model passend zu den Spalten.
#    3. Nutzt CsvHelper (NuGet) für stabiles Lesen und Schreiben.
#    4. Erstellt ein WPF DataGrid, um die CSV direkt zu bearbeiten.
# ═══════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ $# -lt 1 ]; then
    echo -e "${RED}Fehler: Keine .csv Datei angegeben!${NC}"
    echo "Verwendung: $0 daten.csv [ProjektName]"
    exit 1
fi

CSV_FILE="$1"
if [ ! -f "$CSV_FILE" ]; then
    echo -e "${RED}Fehler: Datei '$CSV_FILE' nicht gefunden!${NC}"
    exit 1
fi

CSV_BASENAME=$(basename "$CSV_FILE" .csv)
PROJECT_NAME="${2:-${CSV_BASENAME}App}"

# Clean up class name
CLASS_NAME=$(echo "$CSV_BASENAME" | sed 's/[^a-zA-Z0-9]//g')
CLASS_NAME=$(echo "$CLASS_NAME" | cut -c1 | tr '[:lower:]' '[:upper:]')$(echo "$CLASS_NAME" | cut -c2-)
if [ -z "$CLASS_NAME" ]; then CLASS_NAME="CsvItem"; fi

echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}  WPF CSV App Generator${NC}"
echo -e "${BLUE}===================================================${NC}"
echo -e "  CSV Datei:     ${YELLOW}$CSV_FILE${NC}"
echo -e "  Projektname:   ${YELLOW}$PROJECT_NAME${NC}"
echo -e "  Model Klasse:  ${YELLOW}$CLASS_NAME${NC}"
echo ""

BASE_DIR="$PROJECT_NAME"
if [ -d "$BASE_DIR" ]; then
    echo -e "${RED}Fehler: Ordner '$BASE_DIR' existiert bereits!${NC}"
    exit 1
fi

# Detect Headers
HEADER_LINE=$(head -n 1 "$CSV_FILE" | tr -d '\r\n')
SEP=","
if [[ "$HEADER_LINE" == *";"* ]]; then SEP=";"; fi

# Split headers
declare -a HEADERS=()
declare -a PROPS=()

IFS=$'\n' read -r -d '' -a RAW_HEADERS < <(echo "$HEADER_LINE" | awk -F"$SEP" '{for(i=1;i<=NF;i++) print $i}' && printf '\0')

for raw in "${RAW_HEADERS[@]}"; do
    h=$(echo "$raw" | sed 's/"//g')
    
    # clean property name
    p=$(echo "$h" | sed 's/[^a-zA-Z0-9]//g')
    if [[ "$p" =~ ^[0-9] ]]; then p="Col_$p"; fi
    if [ -z "$p" ]; then p="Column${#HEADERS[@]}"; fi
    
    first=$(echo "$p" | cut -c1 | tr '[:lower:]' '[:upper:]')
    rest=$(echo "$p" | cut -c2-)
    p="${first}${rest}"
    
    HEADERS+=("$h")
    PROPS+=("$p")
done

echo -e "${GREEN}[1/5] Erstelle Verzeichnisstruktur...${NC}"
mkdir -p "$BASE_DIR/Models"
mkdir -p "$BASE_DIR/Services"

echo -e "${GREEN}[2/5] Kopiere CSV Datei...${NC}"
cp "$CSV_FILE" "$BASE_DIR/"

echo -e "${GREEN}[3/5] Generiere Model ($CLASS_NAME.cs)...${NC}"
{
    echo "using CsvHelper.Configuration.Attributes;"
    echo ""
    echo "namespace $PROJECT_NAME.Models"
    echo "{"
    echo "    public class $CLASS_NAME"
    echo "    {"
    for i in "${!HEADERS[@]}"; do
        h="${HEADERS[$i]}"
        p="${PROPS[$i]}"
        echo "        [Name(\"$h\")]"
        echo "        public string $p { get; set; } = string.Empty;"
        echo ""
    done
    echo "    }"
    echo "}"
} > "$BASE_DIR/Models/$CLASS_NAME.cs"

echo -e "${GREEN}[4/5] Generiere CsvDataService...${NC}"
{
    echo "using CsvHelper;"
    echo "using CsvHelper.Configuration;"
    echo "using System.Globalization;"
    echo "using System.IO;"
    echo "using System.Collections.Generic;"
    echo "using System.Linq;"
    echo "using $PROJECT_NAME.Models;"
    echo ""
    echo "namespace $PROJECT_NAME.Services"
    echo "{"
    echo "    public class CsvDataService"
    echo "    {"
    echo "        private readonly string _filePath;"
    echo "        private readonly CsvConfiguration _config;"
    echo ""
    echo "        public CsvDataService(string filePath)"
    echo "        {"
    echo "            _filePath = filePath;"
    echo "            _config = new CsvConfiguration(CultureInfo.InvariantCulture)"
    echo "            {"
    echo "                Delimiter = \"$SEP\","
    echo "                HasHeaderRecord = true"
    echo "            };"
    echo "        }"
    echo ""
    echo "        public List<$CLASS_NAME> Load()"
    echo "        {"
    echo "            if (!File.Exists(_filePath)) return new List<$CLASS_NAME>();"
    echo "            using var reader = new StreamReader(_filePath);"
    echo "            using var csv = new CsvReader(reader, _config);"
    echo "            return csv.GetRecords<$CLASS_NAME>().ToList();"
    echo "        }"
    echo ""
    echo "        public void Save(IEnumerable<$CLASS_NAME> items)"
    echo "        {"
    echo "            using var writer = new StreamWriter(_filePath);"
    echo "            using var csv = new CsvWriter(writer, _config);"
    echo "            csv.WriteRecords(items);"
    echo "        }"
    echo "    }"
    echo "}"
} > "$BASE_DIR/Services/CsvDataService.cs"

echo -e "${GREEN}[5/5] Generiere WPF Projekt und UI...${NC}"
# csproj
cat > "$BASE_DIR/$PROJECT_NAME.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="CsvHelper" Version="31.0.0" />
  </ItemGroup>
  <ItemGroup>
    <None Update="$(basename "$CSV_FILE")">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
EOF

cat > "$BASE_DIR/App.xaml" << EOF
<Application x:Class="$PROJECT_NAME.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
</Application>
EOF

cat > "$BASE_DIR/App.xaml.cs" << EOF
using System.Windows;
namespace $PROJECT_NAME { public partial class App : Application { } }
EOF

# MainWindow.xaml
DG_COLS=""
for p in "${PROPS[@]}"; do
    DG_COLS="$DG_COLS                    <DataGridTextColumn Header=\"$p\" Binding=\"{Binding $p}\" Width=\"*\"/>\n"
done

cat > "$BASE_DIR/MainWindow.xaml" << EOF
<Window x:Class="$PROJECT_NAME.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$PROJECT_NAME (CSV Editor)" Height="600" Width="900"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>
    <DockPanel>
        <Border DockPanel.Dock="Top" Background="#1B4332" Padding="14,10">
            <TextBlock Text="$PROJECT_NAME - $(basename "$CSV_FILE")" FontSize="18" FontWeight="Bold" Foreground="White"/>
        </Border>
        
        <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="8">
            <Button Content="💾 Speichern" FontWeight="Bold" Click="BtnSave_Click"/>
            <Separator Margin="8,0"/>
            <Button Content="➕ Neu" Click="BtnAdd_Click"/>
            <Button Content="❌ Löschen" Click="BtnDelete_Click"/>
        </StackPanel>

        <DataGrid x:Name="MainGrid" Margin="8" AutoGenerateColumns="False" CanUserAddRows="False" FontSize="13">
            <DataGrid.Columns>
$(echo -e "$DG_COLS")            </DataGrid.Columns>
        </DataGrid>
    </DockPanel>
</Window>
EOF

cat > "$BASE_DIR/MainWindow.xaml.cs" << EOF
using System;
using System.Collections.ObjectModel;
using System.Windows;
using $PROJECT_NAME.Models;
using $PROJECT_NAME.Services;

namespace $PROJECT_NAME
{
    public partial class MainWindow : Window
    {
        private readonly CsvDataService _service;
        public ObservableCollection<$CLASS_NAME> Items { get; set; }

        public MainWindow()
        {
            InitializeComponent();
            _service = new CsvDataService("$(basename "$CSV_FILE")");
            
            try {
                Items = new ObservableCollection<$CLASS_NAME>(_service.Load());
            } catch (Exception ex) {
                MessageBox.Show($"Fehler beim Laden der CSV: {ex.Message}");
                Items = new ObservableCollection<$CLASS_NAME>();
            }
            
            MainGrid.ItemsSource = Items;
        }

        private void BtnSave_Click(object sender, RoutedEventArgs e)
        {
            try {
                _service.Save(Items);
                MessageBox.Show("Erfolgreich gespeichert!", "Speichern", MessageBoxButton.OK, MessageBoxImage.Information);
            } catch (Exception ex) {
                MessageBox.Show($"Fehler beim Speichern: {ex.Message}", "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void BtnAdd_Click(object sender, RoutedEventArgs e)
        {
            Items.Add(new $CLASS_NAME());
        }

        private void BtnDelete_Click(object sender, RoutedEventArgs e)
        {
            if (MainGrid.SelectedItem is $CLASS_NAME item)
            {
                Items.Remove(item);
            }
        }
    }
}
EOF

echo ""
echo -e "${GREEN}✅ Projekt erfolgreich generiert in: $BASE_DIR${NC}"
echo -e "Nutzt CsvHelper für sicheres Lesen/Schreiben. Öffne in Visual Studio und baue das Projekt!"
echo ""
