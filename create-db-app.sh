#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  create-db-app.sh
#  Erstellt automatisch ein WPF CRUD-Projekt aus einer SQLite .db Datei.
#
#  Verwendung:
#    ./create-db-app.sh <Datenbank.db> [ProjektName]
#
#  Beispiel:
#    ./create-db-app.sh Waldwunder.db Waldwunderverwaltung
#    ./create-db-app.sh shop.db ShopVerwaltung
#    ./create-db-app.sh students.db Studentenverwaltung
#
#  Was passiert:
#    1. Liest die .db Datei ein und analysiert alle Tabellen/Spalten
#    2. Generiert für jede Tabelle:
#       - Model-Klasse (Models/TabellenName.cs)
#       - Service-Klasse (Services/TabellenNameService.cs) mit CRUD
#    3. Erstellt AppDbContext.cs mit allen DbSets
#    4. Erstellt WPF MainWindow mit DataGrid + CRUD-Buttons
#    5. Kopiert die .db Datei ins Projekt
#
#  Voraussetzungen:
#    - sqlite3 muss installiert sein
# ═══════════════════════════════════════════════════════════════════

set -e

# ── Farben ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Argumente prüfen ──────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo -e "${RED}Fehler: Keine .db Datei angegeben!${NC}"
    echo ""
    echo "Verwendung: $0 <Datenbank.db> [ProjektName]"
    echo ""
    echo "Beispiele:"
    echo "  $0 shop.db"
    echo "  $0 shop.db ShopVerwaltung"
    exit 1
fi

DB_FILE="$1"
if [ ! -f "$DB_FILE" ]; then
    echo -e "${RED}Fehler: Datei '$DB_FILE' nicht gefunden!${NC}"
    exit 1
fi

if ! command -v sqlite3 &> /dev/null; then
    echo -e "${YELLOW}Info: sqlite3 ist nicht installiert! Erstelle temporären .NET Reader...${NC}"
    if ! command -v dotnet &> /dev/null; then
        echo -e "${RED}Fehler: Weder 'sqlite3' noch 'dotnet' gefunden! Bitte installieren.${NC}"
        exit 1
    fi

    TEMP_SQLITE_DIR=$(mktemp -d)
    pushd "$TEMP_SQLITE_DIR" > /dev/null
    dotnet new console -f net8.0 > /dev/null
    dotnet add package Microsoft.Data.Sqlite > /dev/null
    cat > Program.cs << 'EOF'
using System;
using Microsoft.Data.Sqlite;
class Program {
    static void Main(string[] args) {
        using var conn = new SqliteConnection($"Data Source={args[0]}");
        conn.Open();
        if (args[1] == ".tables") {
            var cmd = conn.CreateCommand();
            cmd.CommandText = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'";
            using var reader = cmd.ExecuteReader();
            while (reader.Read()) Console.Write(reader.GetString(0) + " ");
            Console.WriteLine();
        } else {
            var cmd = conn.CreateCommand();
            cmd.CommandText = args[1];
            using var reader = cmd.ExecuteReader();
            while (reader.Read()) {
                var cols = new string[reader.FieldCount];
                for(int i=0; i<reader.FieldCount; i++) cols[i] = reader.IsDBNull(i) ? "" : reader.GetValue(i).ToString();
                Console.WriteLine(string.Join("|", cols));
            }
        }
    }
}
EOF
    dotnet build > /dev/null
    popd > /dev/null

    # Wrapper Funktion, die sqlite3 imitiert
    sqlite3() {
        dotnet run --project "$TEMP_SQLITE_DIR" --no-build -- "$1" "$2"
    }

    # Aufräumen bei Beenden
    trap 'rm -rf "$TEMP_SQLITE_DIR"' EXIT
fi

# ── Projektname bestimmen ─────────────────────────────────────────
DB_BASENAME=$(basename "$DB_FILE" .db)
PROJECT_NAME="${2:-${DB_BASENAME}App}"

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  WPF CRUD App Generator (aus SQLite .db)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Datenbank:     ${YELLOW}$DB_FILE${NC}"
echo -e "  Projektname:   ${YELLOW}$PROJECT_NAME${NC}"
echo ""

# ── Tabellen auslesen ─────────────────────────────────────────────
# Filtere interne SQLite-Tabellen heraus
TABLES=$(sqlite3 "$DB_FILE" ".tables" | tr -s ' ' '\n' | grep -v '^$' | grep -v 'sqlite_sequence' | sort)

if [ -z "$TABLES" ]; then
    echo -e "${RED}Fehler: Keine Tabellen in der Datenbank gefunden!${NC}"
    exit 1
fi

echo -e "${GREEN}Gefundene Tabellen:${NC}"
for t in $TABLES; do
    COLS=$(sqlite3 "$DB_FILE" "PRAGMA table_info($t);" | awk -F'|' '{printf "  %s (%s)\n", $2, $3}')
    echo -e "  ${CYAN}$t${NC}"
    echo "$COLS"
done
echo ""

# ── Prüfen ob Ordner existiert ────────────────────────────────────
BASE_DIR="$PROJECT_NAME"
if [ -d "$BASE_DIR" ]; then
    echo -e "${RED}Fehler: Ordner '$BASE_DIR' existiert bereits!${NC}"
    exit 1
fi

# ── Hilfsfunktionen ───────────────────────────────────────────────

# Konvertiert einen SQLite-Typ in einen C#-Typ
sqlite_to_csharp_type() {
    local sql_type
    sql_type=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case "$sql_type" in
        INTEGER|INT|SMALLINT|TINYINT|MEDIUMINT|BIGINT)
            echo "int"
            ;;
        REAL|DOUBLE|FLOAT|NUMERIC|DECIMAL)
            echo "double"
            ;;
        TEXT|VARCHAR*|CHAR*|CLOB|NVARCHAR*|NCHAR*|"")
            echo "string"
            ;;
        BLOB)
            echo "byte[]"
            ;;
        BOOLEAN|BOOL)
            echo "bool"
            ;;
        DATE|DATETIME|TIMESTAMP)
            echo "DateTime"
            ;;
        *)
            echo "string"
            ;;
    esac
}

# Konvertiert Tabellennamen zu PascalCase Klassennamen
to_pascal_case() {
    echo "$1" | sed -E 's/(^|_)([a-z])/\U\2/g'
}

# Erster Buchstabe groß
capitalize() {
    echo "$1" | sed 's/^./\U&/'
}

# Alles kleinschreiben (für Variablennamen)
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# ── Verzeichnisse erstellen ───────────────────────────────────────
echo -e "${GREEN}[1/6] Erstelle Verzeichnisstruktur...${NC}"
mkdir -p "$BASE_DIR/Models"
mkdir -p "$BASE_DIR/Services"

# ── Datenbank kopieren ────────────────────────────────────────────
echo -e "${GREEN}[2/6] Kopiere Datenbank...${NC}"
cp "$DB_FILE" "$BASE_DIR/"

# ── Model-Klassen generieren ─────────────────────────────────────
echo -e "${GREEN}[3/6] Generiere Model-Klassen...${NC}"

# Sammle alle Tabellennamen und Klassennamen
declare -a TABLE_NAMES=()
declare -a CLASS_NAMES=()

for TABLE in $TABLES; do
    CLASS_NAME=$(to_pascal_case "$TABLE")
    TABLE_NAMES+=("$TABLE")
    CLASS_NAMES+=("$CLASS_NAME")

    echo -e "  ${CYAN}Models/$CLASS_NAME.cs${NC} ← Tabelle '$TABLE'"

    # Spalten-Infos holen: cid|name|type|notnull|dflt_value|pk
    COLUMNS=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);")

    # Foreign Keys holen
    FK_INFO=$(sqlite3 "$DB_FILE" "PRAGMA foreign_key_list($TABLE);")

    # Model-Datei schreiben
    {
        echo "using System;"
        echo "using System.Collections.Generic;"
        echo "using System.ComponentModel.DataAnnotations;"
        echo "using System.ComponentModel.DataAnnotations.Schema;"
        echo ""
        echo "namespace $PROJECT_NAME.Models"
        echo "{"
        echo "    [Table(\"$TABLE\")]"
        echo "    public class $CLASS_NAME"
        echo "    {"

        while IFS='|' read -r CID COL_NAME COL_TYPE NOT_NULL DEFAULT_VAL IS_PK; do
            [ -z "$CID" ] && continue

            CSHARP_TYPE=$(sqlite_to_csharp_type "$COL_TYPE")
            PROP_NAME=$(capitalize "$COL_NAME")

            # Primary Key?
            if [ "$IS_PK" = "1" ]; then
                echo "        [Key]"
                if [ "$CSHARP_TYPE" = "int" ]; then
                    CSHARP_TYPE="int?"
                fi
            fi

            # Foreign Key prüfen
            FK_TABLE=""
            if [ -n "$FK_INFO" ]; then
                FK_TABLE=$(echo "$FK_INFO" | awk -F'|' -v col="$COL_NAME" '$4 == col {print $3}')
            fi

            if [ -n "$FK_TABLE" ]; then
                FK_CLASS=$(to_pascal_case "$FK_TABLE")
                echo "        [ForeignKey(\"$FK_CLASS\")]"
                # Nullable für FK
                if [ "$CSHARP_TYPE" = "int" ]; then
                    CSHARP_TYPE="int?"
                fi
            fi

            # Property schreiben
            if [ "$CSHARP_TYPE" = "string" ]; then
                echo "        public string $PROP_NAME { get; set; } = string.Empty;"
            elif [ "$CSHARP_TYPE" = "byte[]" ]; then
                echo "        public byte[]? $PROP_NAME { get; set; }"
            elif [ "$CSHARP_TYPE" = "DateTime" ]; then
                echo "        public DateTime $PROP_NAME { get; set; }"
            else
                echo "        public $CSHARP_TYPE $PROP_NAME { get; set; }"
            fi
            echo ""

            # Navigation Property für FK
            if [ -n "$FK_TABLE" ]; then
                FK_CLASS=$(to_pascal_case "$FK_TABLE")
                echo "        // Navigation Property → $FK_CLASS"
                echo "        public virtual $FK_CLASS? $FK_CLASS { get; set; }"
                echo ""
            fi

        done <<< "$COLUMNS"

        # Inverse Navigation Properties (andere Tabellen die auf diese verweisen)
        for OTHER_TABLE in $TABLES; do
            if [ "$OTHER_TABLE" = "$TABLE" ]; then continue; fi
            OTHER_FK=$(sqlite3 "$DB_FILE" "PRAGMA foreign_key_list($OTHER_TABLE);" | awk -F'|' -v tbl="$TABLE" '$3 == tbl {print $3}')
            if [ -n "$OTHER_FK" ]; then
                OTHER_CLASS=$(to_pascal_case "$OTHER_TABLE")
                echo "        // Navigation Property: Collection von $OTHER_CLASS"
                echo "        public virtual ICollection<$OTHER_CLASS> ${OTHER_CLASS}s { get; set; } = new List<$OTHER_CLASS>();"
                echo ""
            fi
        done

        echo "        public override string ToString()"

        # Finde die erste Text-Spalte für ToString()
        FIRST_TEXT_COL=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);" | awk -F'|' 'toupper($3) ~ /TEXT|VARCHAR|CHAR/ {print $2; exit}')
        FIRST_PK_COL=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);" | awk -F'|' '$6 == 1 {print $2; exit}')

        if [ -n "$FIRST_TEXT_COL" ]; then
            FIRST_TEXT_PROP=$(capitalize "$FIRST_TEXT_COL")
            echo "            => \$\"{$FIRST_TEXT_PROP}\";"
        elif [ -n "$FIRST_PK_COL" ]; then
            FIRST_PK_PROP=$(capitalize "$FIRST_PK_COL")
            echo "            => \$\"$CLASS_NAME #{$FIRST_PK_PROP}\";"
        else
            echo "            => \"$CLASS_NAME\";"
        fi

        echo "    }"
        echo "}"
    } > "$BASE_DIR/Models/$CLASS_NAME.cs"
done

# ── AppDbContext generieren ───────────────────────────────────────
echo -e "${GREEN}[4/6] Generiere AppDbContext...${NC}"

DB_FILENAME=$(basename "$DB_FILE")

{
    echo "using Microsoft.EntityFrameworkCore;"
    echo "using $PROJECT_NAME.Models;"
    echo ""
    echo "namespace $PROJECT_NAME"
    echo "{"
    echo "    public class AppDbContext : DbContext"
    echo "    {"

    # DbSets
    for i in "${!TABLE_NAMES[@]}"; do
        CLASS="${CLASS_NAMES[$i]}"
        echo "        public DbSet<$CLASS> ${CLASS}s { get; set; }"
    done

    echo ""
    echo "        protected override void OnConfiguring(DbContextOptionsBuilder options)"
    echo "            => options.UseSqlite(\"Data Source=$DB_FILENAME\");"
    echo "    }"
    echo "}"
} > "$BASE_DIR/AppDbContext.cs"

# ── Service-Klassen generieren ────────────────────────────────────
echo -e "${GREEN}[5/6] Generiere Service-Klassen...${NC}"

for i in "${!TABLE_NAMES[@]}"; do
    TABLE="${TABLE_NAMES[$i]}"
    CLASS="${CLASS_NAMES[$i]}"

    echo -e "  ${CYAN}Services/${CLASS}Service.cs${NC}"

    # Finde PK-Spalte
    PK_COL=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);" | awk -F'|' '$6 == 1 {print $2; exit}')
    PK_PROP=$(capitalize "${PK_COL:-id}")
    PK_TYPE="int"

    # Finde alle nicht-PK Spalten für Create-Methode
    CREATE_PARAMS=""
    CREATE_ASSIGNS=""
    COLUMNS_INFO=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);" | awk -F'|' '$6 != 1')

    while IFS='|' read -r CID COL_NAME COL_TYPE NOT_NULL DEFAULT_VAL IS_PK; do
        [ -z "$CID" ] && continue
        CSHARP_TYPE=$(sqlite_to_csharp_type "$COL_TYPE")
        PROP_NAME=$(capitalize "$COL_NAME")

        # FK prüfen für Typ-Anpassung
        FK_TABLE=$(echo "$FK_INFO" | awk -F'|' -v col="$COL_NAME" '$4 == col {print $3}')
        if [ -n "$FK_TABLE" ]; then
            if [ "$CSHARP_TYPE" = "int" ] || [ "$CSHARP_TYPE" = "double" ]; then
                CSHARP_TYPE="int?"
            fi
        fi

        # Komma hinzufügen wenn nicht der erste Parameter
        if [ -n "$CREATE_PARAMS" ]; then
            CREATE_PARAMS="$CREATE_PARAMS, "
        fi

        if [ "$CSHARP_TYPE" = "string" ]; then
            CREATE_PARAMS="${CREATE_PARAMS}string ${COL_NAME}"
        else
            CREATE_PARAMS="${CREATE_PARAMS}${CSHARP_TYPE} ${COL_NAME}"
        fi

        CREATE_ASSIGNS="${CREATE_ASSIGNS}                $PROP_NAME = $COL_NAME,\n"

    done <<< "$COLUMNS_INFO"

    # Hat Navigation Properties? (für Include)
    HAS_NAV=false
    INCLUDE_CHAIN=""
    for OTHER_TABLE in $TABLES; do
        if [ "$OTHER_TABLE" = "$TABLE" ]; then continue; fi
        OTHER_FK=$(sqlite3 "$DB_FILE" "PRAGMA foreign_key_list($OTHER_TABLE);" | awk -F'|' -v tbl="$TABLE" '$3 == tbl {print $3}')
        if [ -n "$OTHER_FK" ]; then
            OTHER_CLASS=$(to_pascal_case "$OTHER_TABLE")
            HAS_NAV=true
            INCLUDE_CHAIN="${INCLUDE_CHAIN}.Include(x => x.${OTHER_CLASS}s)"
        fi
    done

    GETALL_EXPR="${CLASS}s${INCLUDE_CHAIN}.ToList()"

    {
        echo "using System.Collections.Generic;"
        echo "using System.Linq;"
        echo "using Microsoft.EntityFrameworkCore;"
        echo "using $PROJECT_NAME.Models;"
        echo ""
        echo "namespace $PROJECT_NAME.Services"
        echo "{"
        echo "    public class ${CLASS}Service"
        echo "    {"
        echo "        private readonly AppDbContext _db;"
        echo ""
        echo "        public ${CLASS}Service(AppDbContext db)"
        echo "        {"
        echo "            _db = db;"
        echo "        }"
        echo ""

        # CREATE
        echo "        // ── CREATE ──────────────────────────────────────────"
        echo ""
        echo "        public $CLASS Create($CREATE_PARAMS)"
        echo "        {"
        echo "            var item = new $CLASS"
        echo "            {"
        echo -e "$CREATE_ASSIGNS            };"
        echo "            _db.${CLASS}s.Add(item);"
        echo "            _db.SaveChanges();"
        echo "            return item;"
        echo "        }"
        echo ""

        # READ
        echo "        // ── READ ────────────────────────────────────────────"
        echo ""
        echo "        /// <summary>Gibt alle $CLASS-Einträge zurück.</summary>"
        echo "        public List<$CLASS> GetAll() =>"
        echo "            _db.${GETALL_EXPR};"
        echo ""
        echo "        /// <summary>Gibt einen $CLASS nach ID zurück.</summary>"
        echo "        public $CLASS? GetById($PK_TYPE id) =>"
        echo "            _db.${CLASS}s${INCLUDE_CHAIN}.FirstOrDefault(x => x.$PK_PROP == id);"
        echo ""

        # Suche nach Text-Spalten
        TEXT_COLS=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);" | awk -F'|' 'toupper($3) ~ /TEXT|VARCHAR|CHAR/ && $6 != 1 {print $2}')
        if [ -n "$TEXT_COLS" ]; then
            # Baue die Where-Klausel
            WHERE_PARTS=""
            for TC in $TEXT_COLS; do
                TC_PROP=$(capitalize "$TC")
                if [ -n "$WHERE_PARTS" ]; then
                    WHERE_PARTS="$WHERE_PARTS || "
                fi
                WHERE_PARTS="${WHERE_PARTS}x.$TC_PROP.Contains(keyword)"
            done

            echo "        /// <summary>Sucht $CLASS nach Stichwort in Text-Spalten.</summary>"
            echo "        public List<$CLASS> Search(string keyword) =>"
            echo "            _db.${CLASS}s${INCLUDE_CHAIN}"
            echo "               .Where(x => $WHERE_PARTS)"
            echo "               .ToList();"
            echo ""
        fi

        # UPDATE
        echo "        // ── UPDATE ──────────────────────────────────────────"
        echo ""
        echo "        public bool Update($CLASS item)"
        echo "        {"
        echo "            _db.${CLASS}s.Update(item);"
        echo "            return _db.SaveChanges() > 0;"
        echo "        }"
        echo ""

        # DELETE
        echo "        // ── DELETE ──────────────────────────────────────────"
        echo ""
        echo "        public bool Delete($PK_TYPE id)"
        echo "        {"
        echo "            var item = _db.${CLASS}s.Find(id);"
        echo "            if (item == null) return false;"
        echo "            _db.${CLASS}s.Remove(item);"
        echo "            return _db.SaveChanges() > 0;"
        echo "        }"

        echo "    }"
        echo "}"
    } > "$BASE_DIR/Services/${CLASS}Service.cs"
done

# ── WPF Projekt generieren ────────────────────────────────────────
echo -e "${GREEN}[6/6] Generiere WPF Projekt und UI...${NC}"

# .csproj
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
    <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="8.0.11" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.11" />
  </ItemGroup>

  <ItemGroup>
    <None Update="$DB_FILENAME">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>

</Project>
EOF

# App.xaml
cat > "$BASE_DIR/App.xaml" << EOF
<Application x:Class="$PROJECT_NAME.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
    </Application.Resources>
</Application>
EOF

cat > "$BASE_DIR/App.xaml.cs" << EOF
using System.Windows;

namespace $PROJECT_NAME
{
    public partial class App : Application
    {
    }
}
EOF

# ── MainWindow.xaml generieren ────────────────────────────────────
# Erstelle Tabs pro Tabelle

TAB_ITEMS=""
for i in "${!CLASS_NAMES[@]}"; do
    CLASS="${CLASS_NAMES[$i]}"
    TABLE="${TABLE_NAMES[$i]}"

    # DataGrid Columns für diese Tabelle
    DG_COLUMNS=""
    COL_DATA=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);")
    while IFS='|' read -r CID COL_NAME COL_TYPE NOT_NULL DEFAULT_VAL IS_PK; do
        [ -z "$CID" ] && continue
        PROP_NAME=$(capitalize "$COL_NAME")
        CSHARP_TYPE=$(sqlite_to_csharp_type "$COL_TYPE")

        # BLOB-Spalten nicht anzeigen
        if [ "$CSHARP_TYPE" = "byte[]" ]; then continue; fi

        DG_COLUMNS="$DG_COLUMNS                            <DataGridTextColumn Header=\"$PROP_NAME\" Binding=\"{Binding $PROP_NAME}\" Width=\"*\"/>\n"
    done <<< "$COL_DATA"

    TAB_ITEMS="$TAB_ITEMS
                <TabItem Header=\"📋 $CLASS\">
                    <DockPanel Margin=\"8\">
                        <!-- Toolbar -->
                        <StackPanel DockPanel.Dock=\"Top\" Orientation=\"Horizontal\" Margin=\"0,0,0,8\">
                            <TextBox x:Name=\"TxtSearch$CLASS\" Width=\"250\" Padding=\"6,4\" FontSize=\"13\"
                                     VerticalContentAlignment=\"Center\"
                                     KeyDown=\"TxtSearch_KeyDown\" Tag=\"$CLASS\"/>
                            <Button Content=\"🔍 Suchen\" Padding=\"12,6\" Margin=\"4\"
                                    Click=\"BtnSearch_Click\" Tag=\"$CLASS\"/>
                            <Button Content=\"📋 Alle laden\" Padding=\"12,6\" Margin=\"4\"
                                    Click=\"BtnLoadAll_Click\" Tag=\"$CLASS\"/>
                            <Separator Margin=\"8,0\"/>
                            <Button Content=\"➕ Neu\" Padding=\"12,6\" Margin=\"4\"
                                    Click=\"BtnAdd_Click\" Tag=\"$CLASS\" FontWeight=\"Bold\"/>
                            <Button Content=\"❌ Löschen\" Padding=\"12,6\" Margin=\"4\"
                                    Click=\"BtnDelete_Click\" Tag=\"$CLASS\"/>
                        </StackPanel>

                        <!-- Status -->
                        <StatusBar DockPanel.Dock=\"Bottom\">
                            <StatusBarItem>
                                <TextBlock x:Name=\"TxtStatus$CLASS\" Text=\"Bereit.\"/>
                            </StatusBarItem>
                        </StatusBar>

                        <!-- DataGrid -->
                        <DataGrid x:Name=\"Grid$CLASS\"
                                  AutoGenerateColumns=\"False\"
                                  CanUserAddRows=\"False\"
                                  IsReadOnly=\"False\"
                                  SelectionMode=\"Single\"
                                  FontSize=\"13\"
                                  RowEditEnding=\"DataGrid_RowEditEnding\"
                                  Tag=\"$CLASS\">
                            <DataGrid.Columns>
$DG_COLUMNS                            </DataGrid.Columns>
                        </DataGrid>
                    </DockPanel>
                </TabItem>"
done

cat > "$BASE_DIR/MainWindow.xaml" << EOF
<Window x:Class="$PROJECT_NAME.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$PROJECT_NAME" Height="700" Width="1000"
        WindowStartupLocation="CenterScreen"
        Loaded="Window_Loaded">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
    </Window.Resources>

    <DockPanel>
        <!-- Titel -->
        <Border DockPanel.Dock="Top" Background="#1B4332" Padding="14,10">
            <TextBlock Text="📊 $PROJECT_NAME" FontSize="18" FontWeight="Bold"
                       Foreground="White"/>
        </Border>

        <!-- Tabs pro Tabelle -->
        <TabControl Margin="8" FontSize="13">
$TAB_ITEMS
        </TabControl>
    </DockPanel>
</Window>
EOF

# ── MainWindow.xaml.cs generieren ─────────────────────────────────

# Service-Felder
SERVICE_FIELDS=""
for CLASS in "${CLASS_NAMES[@]}"; do
    CLASS_LOWER=$(to_lower "$CLASS")
    SERVICE_FIELDS="${SERVICE_FIELDS}        private ${CLASS}Service _${CLASS_LOWER}Service = null!;\n"
done

# Init Services
INIT_SERVICES=""
for CLASS in "${CLASS_NAMES[@]}"; do
    CLASS_LOWER=$(to_lower "$CLASS")
    INIT_SERVICES="${INIT_SERVICES}            _${CLASS_LOWER}Service = new ${CLASS}Service(_db);\n"
done

# Using-Statements für Services
SERVICE_USINGS="using $PROJECT_NAME.Services;\nusing $PROJECT_NAME.Models;"

{
    echo "using System;"
    echo "using System.Linq;"
    echo "using System.Windows;"
    echo "using System.Windows.Controls;"
    echo "using System.Windows.Input;"
    echo -e "$SERVICE_USINGS"
    echo ""
    echo "namespace $PROJECT_NAME"
    echo "{"
    echo "    public partial class MainWindow : Window"
    echo "    {"
    echo "        private AppDbContext _db = null!;"
    echo -e "$SERVICE_FIELDS"
    echo ""
    echo "        public MainWindow()"
    echo "        {"
    echo "            InitializeComponent();"
    echo "        }"
    echo ""
    echo "        private void Window_Loaded(object sender, RoutedEventArgs e)"
    echo "        {"
    echo "            _db = new AppDbContext();"
    echo -e "$INIT_SERVICES"
    echo "            // Alle Tabellen laden"

    for CLASS in "${CLASS_NAMES[@]}"; do
        echo "            Load${CLASS}();"
    done

    echo "        }"
    echo ""

    # Load-Methoden
    for CLASS in "${CLASS_NAMES[@]}"; do
        echo "        private void Load${CLASS}()"
        echo "        {"
        CLASS_LOWER=$(to_lower "$CLASS")
        echo "            var data = _${CLASS_LOWER}Service.GetAll();"
        echo "            Grid${CLASS}.ItemsSource = data;"
        echo "            TxtStatus${CLASS}.Text = \$\"{data.Count} Einträge geladen.\";"
        echo "        }"
        echo ""
    done

    # Event Handler: Alle laden
    echo "        private void BtnLoadAll_Click(object sender, RoutedEventArgs e)"
    echo "        {"
    echo "            var tag = (sender as Button)?.Tag?.ToString();"
    echo "            switch (tag)"
    echo "            {"
    for CLASS in "${CLASS_NAMES[@]}"; do
        echo "                case \"$CLASS\": Load${CLASS}(); break;"
    done
    echo "            }"
    echo "        }"
    echo ""

    # Event Handler: Suchen
    echo "        private void BtnSearch_Click(object sender, RoutedEventArgs e)"
    echo "        {"
    echo "            var tag = (sender as Button)?.Tag?.ToString();"
    echo "            switch (tag)"
    echo "            {"
    for i in "${!CLASS_NAMES[@]}"; do
        CLASS="${CLASS_NAMES[$i]}"
        TABLE="${TABLE_NAMES[$i]}"

        # Prüfe ob Tabelle Text-Spalten hat
        HAS_TEXT=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);" | awk -F'|' 'toupper($3) ~ /TEXT|VARCHAR|CHAR/ && $6 != 1 {print $2; exit}')

        if [ -n "$HAS_TEXT" ]; then
            echo "                case \"$CLASS\":"
            echo "                {"
            echo "                    var keyword = TxtSearch${CLASS}.Text.Trim();"
            echo "                    if (string.IsNullOrEmpty(keyword)) { Load${CLASS}(); break; }"
            CLASS_LOWER=$(to_lower "$CLASS")
            echo "                    var results = _${CLASS_LOWER}Service.Search(keyword);"
            echo "                    Grid${CLASS}.ItemsSource = results;"
            echo "                    TxtStatus${CLASS}.Text = \$\"{results.Count} Treffer für '{keyword}'.\";"
            echo "                    break;"
            echo "                }"
        else
            echo "                case \"$CLASS\": Load${CLASS}(); break;"
        fi
    done
    echo "            }"
    echo "        }"
    echo ""

    # Enter-Taste für Suche
    echo "        private void TxtSearch_KeyDown(object sender, KeyEventArgs e)"
    echo "        {"
    echo "            if (e.Key == Key.Enter)"
    echo "                BtnSearch_Click(sender, e);"
    echo "        }"
    echo ""

    # Event Handler: Neu
    echo "        private void BtnAdd_Click(object sender, RoutedEventArgs e)"
    echo "        {"
    echo "            var tag = (sender as Button)?.Tag?.ToString();"
    echo "            switch (tag)"
    echo "            {"
    for i in "${!CLASS_NAMES[@]}"; do
        CLASS="${CLASS_NAMES[$i]}"
        TABLE="${TABLE_NAMES[$i]}"

        echo "                case \"$CLASS\":"
        echo "                {"
        echo "                    var item = new $CLASS();"
        echo "                    _db.${CLASS}s.Add(item);"
        echo "                    _db.SaveChanges();"
        echo "                    Load${CLASS}();"
        echo "                    TxtStatus${CLASS}.Text = \"Neuer Eintrag erstellt. Bearbeite die Zeile direkt im DataGrid.\";"
        echo "                    break;"
        echo "                }"
    done
    echo "            }"
    echo "        }"
    echo ""

    # Event Handler: Löschen
    echo "        private void BtnDelete_Click(object sender, RoutedEventArgs e)"
    echo "        {"
    echo "            var tag = (sender as Button)?.Tag?.ToString();"
    echo "            switch (tag)"
    echo "            {"
    for i in "${!CLASS_NAMES[@]}"; do
        CLASS="${CLASS_NAMES[$i]}"
        TABLE="${TABLE_NAMES[$i]}"
        PK_COL=$(sqlite3 "$DB_FILE" "PRAGMA table_info($TABLE);" | awk -F'|' '$6 == 1 {print $2; exit}')
        PK_PROP=$(capitalize "${PK_COL:-id}")

        echo "                case \"$CLASS\":"
        echo "                {"
        echo "                    if (Grid${CLASS}.SelectedItem is $CLASS selected && selected.$PK_PROP.HasValue)"
        echo "                    {"
        echo "                        var result = MessageBox.Show("
        echo "                            \$\"Eintrag #{selected.$PK_PROP} wirklich löschen?\","
        echo "                            \"Löschen bestätigen\", MessageBoxButton.YesNo, MessageBoxImage.Warning);"
        echo "                        if (result == MessageBoxResult.Yes)"
        echo "                        {"
        CLASS_LOWER=$(to_lower "$CLASS")
        echo "                            _${CLASS_LOWER}Service.Delete(selected.$PK_PROP.Value);"
        echo "                            Load${CLASS}();"
        echo "                            TxtStatus${CLASS}.Text = \"Eintrag gelöscht.\";"
        echo "                        }"
        echo "                    }"
        echo "                    break;"
        echo "                }"
    done
    echo "            }"
    echo "        }"
    echo ""

    # Event Handler: Zeile bearbeitet → Update
    echo "        private void DataGrid_RowEditEnding(object sender, DataGridRowEditEndingEventArgs e)"
    echo "        {"
    echo "            if (e.EditAction != DataGridEditAction.Commit) return;"
    echo ""
    echo "            // Dispatcher verwenden um nach dem Commit zu speichern"
    echo "            Dispatcher.BeginInvoke(new Action(() =>"
    echo "            {"
    echo "                var tag = (sender as DataGrid)?.Tag?.ToString();"
    echo "                switch (tag)"
    echo "                {"
    for CLASS in "${CLASS_NAMES[@]}"; do
        echo "                    case \"$CLASS\":"
        CLASS_LOWER=$(to_lower "$CLASS")
        echo "                        if (e.Row.Item is $CLASS ${CLASS_LOWER}Item)"
        echo "                            _${CLASS_LOWER}Service.Update(${CLASS_LOWER}Item);"
        echo "                        break;"
    done
    echo "                }"
    echo "            }));"
    echo "        }"

    echo "    }"
    echo "}"
} > "$BASE_DIR/MainWindow.xaml.cs"

# ── Fertig! ───────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Projekt erfolgreich erstellt!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📁 ${YELLOW}$BASE_DIR/${NC}"
echo -e "     ├── $PROJECT_NAME.csproj"
echo -e "     ├── AppDbContext.cs"
echo -e "     ├── App.xaml / App.xaml.cs"
echo -e "     ├── MainWindow.xaml / MainWindow.xaml.cs"
echo -e "     ├── ${YELLOW}$DB_FILENAME${NC}  ← Kopie deiner Datenbank"
echo -e "     ├── ${YELLOW}Models/${NC}"
for CLASS in "${CLASS_NAMES[@]}"; do
    echo -e "     │   └── $CLASS.cs"
done
echo -e "     └── ${YELLOW}Services/${NC}"
for CLASS in "${CLASS_NAMES[@]}"; do
    echo -e "         └── ${CLASS}Service.cs  (CRUD)"
done
echo ""
echo -e "  ${GREEN}Generierte Features:${NC}"
echo -e "    ✅ Model-Klassen mit [Table], [Key], [ForeignKey] Attributen"
echo -e "    ✅ AppDbContext mit DbSets für alle Tabellen"
echo -e "    ✅ Service-Klassen mit Create/Read/Search/Update/Delete"
echo -e "    ✅ WPF MainWindow mit DataGrid (Tab pro Tabelle)"
echo -e "    ✅ Inline-Bearbeitung + Suche + Hinzufügen + Löschen"
echo ""
echo -e "  Öffne in Visual Studio und führe 'dotnet restore' aus."
echo ""
