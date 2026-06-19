<#
.SYNOPSIS
    Erstellt automatisch ein WPF CRUD-Projekt aus einer SQLite .db Datei.

.DESCRIPTION
    Liest eine SQLite Datenbank, analysiert alle Tabellen und Spalten,
    und generiert ein komplettes WPF-Projekt mit Models, Services (CRUD),
    AppDbContext und DataGrid-basiertem MainWindow.

.EXAMPLE
    .\create-db-app.ps1 Waldwunder.db
    .\create-db-app.ps1 shop.db ShopVerwaltung
    .\create-db-app.ps1 students.db Studentenverwaltung
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$DbFile,

    [Parameter(Position=1)]
    [string]$ProjectName
)

# ── Pruefungen ────────────────────────────────────────────────────
if (-not (Test-Path $DbFile)) {
    Write-Host "Fehler: Datei '$DbFile' nicht gefunden!" -ForegroundColor Red
    exit 1
}

# sqlite3 suchen oder .NET Fallback verwenden
$sqlite3 = $null
$useDotnet = $false

if (Get-Command "sqlite3" -ErrorAction SilentlyContinue) {
    $sqlite3 = "sqlite3"
} elseif (Get-Command "sqlite3.exe" -ErrorAction SilentlyContinue) {
    $sqlite3 = "sqlite3.exe"
} else {
    # Kein sqlite3 installiert. Wir nutzen dotnet, was für WPF ohnehin installiert ist!
    if (Get-Command "dotnet" -ErrorAction SilentlyContinue) {
        $useDotnet = $true
    } else {
        Write-Host "Fehler: Weder 'sqlite3' noch 'dotnet' gefunden! Bitte .NET SDK installieren." -ForegroundColor Red
        exit 1
    }
}

# Projektname bestimmen
$DbBasename = [System.IO.Path]::GetFileNameWithoutExtension($DbFile)
if (-not $ProjectName) { $ProjectName = "${DbBasename}App" }
$DbFilename = [System.IO.Path]::GetFileName($DbFile)
$DbFullPath = (Resolve-Path $DbFile).Path

Write-Host "===================================================" -ForegroundColor Blue
Write-Host "  WPF CRUD App Generator (aus SQLite .db)" -ForegroundColor Blue
Write-Host "===================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  Datenbank:     $DbFile" -ForegroundColor Yellow
Write-Host "  Projektname:   $ProjectName" -ForegroundColor Yellow
Write-Host ""

# ── Tabellen auslesen ─────────────────────────────────────────────
$allTables = @()
$schemaLines = @()

if ($useDotnet) {
    Write-Host "Info: Lese Schema via lokales .NET (sqlite3 nicht installiert)..." -ForegroundColor Cyan
    $origPath = Get-Location
    $tempDir = Join-Path $env:TEMP "DbReader_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    Set-Location $tempDir
    & dotnet new console -n DbReader -f net8.0 > $null
    & dotnet add package Microsoft.Data.Sqlite > $null

    $csCode = @"
using System;
using Microsoft.Data.Sqlite;

class Program {
    static void Main(string[] args) {
        using var conn = new SqliteConnection($"Data Source={args[0]}");
        conn.Open();
        
        var cmd = conn.CreateCommand();
        cmd.CommandText = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'";
        using var reader = cmd.ExecuteReader();
        while (reader.Read()) {
            var table = reader.GetString(0);
            Console.WriteLine($"TABLE|{table}");
            
            var cmd2 = conn.CreateCommand();
            cmd2.CommandText = $"PRAGMA table_info('{table}')";
            using var r2 = cmd2.ExecuteReader();
            while (r2.Read()) {
                Console.WriteLine($"COL|{table}|{r2[0]}|{r2[1]}|{r2[2]}|{r2[3]}|{(r2.IsDBNull(4) ? "" : r2[4])}|{r2[5]}");
            }
            
            var cmd3 = conn.CreateCommand();
            cmd3.CommandText = $"PRAGMA foreign_key_list('{table}')";
            using var r3 = cmd3.ExecuteReader();
            while (r3.Read()) {
                Console.WriteLine($"FK|{table}|{r3[2]}|{r3[3]}|{r3[4]}");
            }
        }
    }
}
"@
    Set-Content -Path "Program.cs" -Value $csCode
    $schemaLines = & dotnet run -- "$DbFullPath"
    Set-Location $origPath
    Remove-Item -Path $tempDir -Recurse -Force

    $allTables = $schemaLines | Where-Object { $_ -like "TABLE|*" } | ForEach-Object { ($_ -split '\|')[1] } | Sort-Object
} else {
    $allTables = & $sqlite3 $DbFullPath ".tables" | ForEach-Object { $_ -split '\s+' } | Where-Object { $_ -ne '' -and $_ -ne 'sqlite_sequence' } | Sort-Object
}

if ($allTables.Count -eq 0) {
    Write-Host "Fehler: Keine Tabellen in der Datenbank gefunden!" -ForegroundColor Red
    exit 1
}

# ── Hilfsfunktionen ───────────────────────────────────────────────
function ConvertTo-PascalCase([string]$name) {
    # Erster Buchstabe gross, Rest beibehalten
    if ($name.Length -eq 0) { return $name }
    return $name.Substring(0,1).ToUpper() + $name.Substring(1)
}

function ConvertTo-CSharpType([string]$sqlType) {
    $upper = $sqlType.ToUpper().Trim()
    switch -Wildcard ($upper) {
        "INTEGER"   { return "int" }
        "INT"       { return "int" }
        "SMALLINT"  { return "int" }
        "BIGINT"    { return "long" }
        "REAL"      { return "double" }
        "DOUBLE"    { return "double" }
        "FLOAT"     { return "double" }
        "NUMERIC"   { return "double" }
        "DECIMAL"   { return "double" }
        "TEXT"      { return "string" }
        "VARCHAR*"  { return "string" }
        "CHAR*"     { return "string" }
        "NVARCHAR*" { return "string" }
        "CLOB"      { return "string" }
        "BLOB"      { return "byte[]" }
        "BOOLEAN"   { return "bool" }
        "BOOL"      { return "bool" }
        "DATE"      { return "DateTime" }
        "DATETIME"  { return "DateTime" }
        "TIMESTAMP" { return "DateTime" }
        ""          { return "string" }
        default     { return "string" }
    }
}

# ── Tabellen-Info sammeln ─────────────────────────────────────────
Write-Host "Gefundene Tabellen:" -ForegroundColor Green

$tableInfos = @()
foreach ($table in $allTables) {
    Write-Host "  $table" -ForegroundColor Cyan

    $columns = @()
    $fks = @()

    if ($useDotnet) {
        # Filtere die vorab geladenen Schema-Infos
        $colLines = $schemaLines | Where-Object { $_ -like "COL|$table|*" }
        foreach ($line in $colLines) {
            $parts = $line -split '\|'
            $columns += @{
                Cid = $parts[2]
                Name = $parts[3]
                Type = $parts[4]
                NotNull = $parts[5]
                Default = $parts[6]
                IsPK = ($parts[7] -eq "1")
            }
            $ctype = ConvertTo-CSharpType $parts[4]
            Write-Host "    $($parts[3]) ($($parts[4])) -> $ctype"
        }

        $fkLines = $schemaLines | Where-Object { $_ -like "FK|$table|*" }
        foreach ($line in $fkLines) {
            $parts = $line -split '\|'
            $fks += @{
                Table = $parts[2]
                From = $parts[3]
                To = $parts[4]
            }
        }
    } else {
        # Spalten holen mit sqlite3: cid|name|type|notnull|dflt_value|pk
        $colLines = & $sqlite3 $DbFullPath "PRAGMA table_info($table);"
        foreach ($line in $colLines) {
            if (-not $line) { continue }
            $parts = $line -split '\|'
            $columns += @{
                Cid = $parts[0]
                Name = $parts[1]
                Type = $parts[2]
                NotNull = $parts[3]
                Default = $parts[4]
                IsPK = ($parts[5] -eq "1")
            }
            $ctype = ConvertTo-CSharpType $parts[2]
            Write-Host "    $($parts[1]) ($($parts[2])) -> $ctype"
        }

        # Foreign Keys holen mit sqlite3
        $fkLines = & $sqlite3 $DbFullPath "PRAGMA foreign_key_list($table);"
        foreach ($line in $fkLines) {
            if (-not $line) { continue }
            $parts = $line -split '\|'
            $fks += @{
                Table = $parts[2]
                From = $parts[3]
                To = $parts[4]
            }
        }
    }

    $className = ConvertTo-PascalCase $table
    $tableInfos += @{
        TableName = $table
        ClassName = $className
        Columns = $columns
        ForeignKeys = $fks
    }
}

Write-Host ""

# ── Ordner pruefen ────────────────────────────────────────────────
$BaseDir = $ProjectName
if (Test-Path $BaseDir) {
    Write-Host "Fehler: Ordner '$BaseDir' existiert bereits!" -ForegroundColor Red
    exit 1
}

# ── Verzeichnisse erstellen ───────────────────────────────────────
Write-Host "[1/6] Erstelle Verzeichnisstruktur..." -ForegroundColor Green
New-Item -ItemType Directory -Path "$BaseDir\Models" -Force | Out-Null
New-Item -ItemType Directory -Path "$BaseDir\Services" -Force | Out-Null

# ── Datenbank kopieren ────────────────────────────────────────────
Write-Host "[2/6] Kopiere Datenbank..." -ForegroundColor Green
Copy-Item $DbFullPath "$BaseDir\"

# ── Model-Klassen generieren ─────────────────────────────────────
Write-Host "[3/6] Generiere Model-Klassen..." -ForegroundColor Green

foreach ($ti in $tableInfos) {
    $table = $ti.TableName
    $class = $ti.ClassName
    Write-Host "  Models\$class.cs <- Tabelle '$table'" -ForegroundColor Cyan

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("using System;")
    [void]$sb.AppendLine("using System.Collections.Generic;")
    [void]$sb.AppendLine("using System.ComponentModel.DataAnnotations;")
    [void]$sb.AppendLine("using System.ComponentModel.DataAnnotations.Schema;")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("namespace $ProjectName.Models")
    [void]$sb.AppendLine("{")
    [void]$sb.AppendLine("    [Table(`"$table`")]")
    [void]$sb.AppendLine("    public class $class")
    [void]$sb.AppendLine("    {")

    foreach ($col in $ti.Columns) {
        $csharpType = ConvertTo-CSharpType $col.Type
        $propName = ConvertTo-PascalCase $col.Name

        if ($col.IsPK) {
            [void]$sb.AppendLine("        [Key]")
            if ($csharpType -eq "int") { $csharpType = "int?" }
        }

        # FK pruefen
        $fk = $ti.ForeignKeys | Where-Object { $_.From -eq $col.Name }
        if ($fk) {
            $fkClass = ConvertTo-PascalCase $fk.Table
            [void]$sb.AppendLine("        [ForeignKey(`"$fkClass`")]")
            if ($csharpType -eq "int" -or $csharpType -eq "double") { $csharpType = "int?" }
        }

        if ($csharpType -eq "string") {
            [void]$sb.AppendLine("        public string $propName { get; set; } = string.Empty;")
        } elseif ($csharpType -eq "byte[]") {
            [void]$sb.AppendLine("        public byte[]? $propName { get; set; }")
        } else {
            [void]$sb.AppendLine("        public $csharpType $propName { get; set; }")
        }
        [void]$sb.AppendLine("")

        # Navigation Property fuer FK
        if ($fk) {
            $fkClass = ConvertTo-PascalCase $fk.Table
            [void]$sb.AppendLine("        public virtual ${fkClass}? $fkClass { get; set; }")
            [void]$sb.AppendLine("")
        }
    }

    # Inverse Navigation Properties
    foreach ($otherTi in $tableInfos) {
        if ($otherTi.TableName -eq $table) { continue }
        $otherFk = $otherTi.ForeignKeys | Where-Object { $_.Table -eq $table }
        if ($otherFk) {
            $otherClass = $otherTi.ClassName
            [void]$sb.AppendLine("        public virtual ICollection<$otherClass> ${otherClass}s { get; set; } = new List<$otherClass>();")
            [void]$sb.AppendLine("")
        }
    }

    # ToString
    $firstTextCol = $ti.Columns | Where-Object { (ConvertTo-CSharpType $_.Type) -eq "string" -and -not $_.IsPK } | Select-Object -First 1
    if ($firstTextCol) {
        $prop = ConvertTo-PascalCase $firstTextCol.Name
        [void]$sb.AppendLine("        public override string ToString() => `$`"{$prop}`";")
    } else {
        [void]$sb.AppendLine("        public override string ToString() => `"$class`";")
    }

    [void]$sb.AppendLine("    }")
    [void]$sb.AppendLine("}")

    Set-Content -Path "$BaseDir\Models\$class.cs" -Value $sb.ToString()
}

# ── AppDbContext ──────────────────────────────────────────────────
Write-Host "[4/6] Generiere AppDbContext..." -ForegroundColor Green

$dbSets = ($tableInfos | ForEach-Object { "        public DbSet<$($_.ClassName)> $($_.ClassName)s { get; set; }" }) -join "`n"

@"
using Microsoft.EntityFrameworkCore;
using $ProjectName.Models;

namespace $ProjectName
{
    public class AppDbContext : DbContext
    {
$dbSets

        protected override void OnConfiguring(DbContextOptionsBuilder options)
            => options.UseSqlite("Data Source=$DbFilename");
    }
}
"@ | Set-Content "$BaseDir\AppDbContext.cs"

# ── Service-Klassen ───────────────────────────────────────────────
Write-Host "[5/6] Generiere Service-Klassen..." -ForegroundColor Green

foreach ($ti in $tableInfos) {
    $class = $ti.ClassName
    $classLower = $class.ToLower()
    Write-Host "  Services\${class}Service.cs" -ForegroundColor Cyan

    # PK finden
    $pkCol = $ti.Columns | Where-Object { $_.IsPK } | Select-Object -First 1
    $pkProp = if ($pkCol) { ConvertTo-PascalCase $pkCol.Name } else { "Id" }

    # Include-Chain fuer Navigation Properties
    $includeChain = ""
    foreach ($otherTi in $tableInfos) {
        if ($otherTi.TableName -eq $ti.TableName) { continue }
        $otherFk = $otherTi.ForeignKeys | Where-Object { $_.Table -eq $ti.TableName }
        if ($otherFk) {
            $includeChain += ".Include(x => x.$($otherTi.ClassName)s)"
        }
    }

    # Create-Parameter (nicht-PK Spalten)
    $nonPkCols = $ti.Columns | Where-Object { -not $_.IsPK }
    $createParams = ($nonPkCols | ForEach-Object {
        $ct = ConvertTo-CSharpType $_.Type
        "$ct $($_.Name)"
    }) -join ", "
    $createAssigns = ($nonPkCols | ForEach-Object {
        $prop = ConvertTo-PascalCase $_.Name
        "                $prop = $($_.Name)"
    }) -join ",`n"

    # Text-Spalten fuer Suche
    $textCols = $ti.Columns | Where-Object { (ConvertTo-CSharpType $_.Type) -eq "string" -and -not $_.IsPK }
    $searchMethod = ""
    if ($textCols) {
        $whereParts = ($textCols | ForEach-Object {
            $prop = ConvertTo-PascalCase $_.Name
            "x.$prop.Contains(keyword)"
        }) -join " || "
        $searchMethod = @"

        public List<$class> Search(string keyword) =>
            _db.${class}s${includeChain}
               .Where(x => $whereParts)
               .ToList();
"@
    }

    @"
using System.Collections.Generic;
using System.Linq;
using Microsoft.EntityFrameworkCore;
using $ProjectName.Models;

namespace $ProjectName.Services
{
    public class ${class}Service
    {
        private readonly AppDbContext _db;

        public ${class}Service(AppDbContext db) { _db = db; }

        // CREATE
        public $class Create($createParams)
        {
            var item = new $class
            {
$createAssigns
            };
            _db.${class}s.Add(item);
            _db.SaveChanges();
            return item;
        }

        // READ
        public List<$class> GetAll() =>
            _db.${class}s${includeChain}.ToList();

        public ${class}? GetById(int id) =>
            _db.${class}s${includeChain}.FirstOrDefault(x => x.$pkProp == id);
$searchMethod
        // UPDATE
        public bool Update($class item)
        {
            _db.${class}s.Update(item);
            return _db.SaveChanges() > 0;
        }

        // DELETE
        public bool Delete(int id)
        {
            var item = _db.${class}s.Find(id);
            if (item == null) return false;
            _db.${class}s.Remove(item);
            return _db.SaveChanges() > 0;
        }
    }
}
"@ | Set-Content "$BaseDir\Services\${class}Service.cs"
}

# ── WPF Projekt ───────────────────────────────────────────────────
Write-Host "[6/6] Generiere WPF Projekt und UI..." -ForegroundColor Green

# .csproj
@"
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
    <None Update="$DbFilename">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
"@ | Set-Content "$BaseDir\$ProjectName.csproj"

# App.xaml
@"
<Application x:Class="$ProjectName.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources />
</Application>
"@ | Set-Content "$BaseDir\App.xaml"

@"
using System.Windows;
namespace $ProjectName { public partial class App : Application { } }
"@ | Set-Content "$BaseDir\App.xaml.cs"

# ── MainWindow.xaml (Tabs pro Tabelle) ────────────────────────────
$tabItems = ""
foreach ($ti in $tableInfos) {
    $class = $ti.ClassName

    # DataGrid Columns
    $dgCols = ""
    foreach ($col in $ti.Columns) {
        $ct = ConvertTo-CSharpType $col.Type
        if ($ct -eq "byte[]") { continue }
        $prop = ConvertTo-PascalCase $col.Name
        $dgCols += "                            <DataGridTextColumn Header=`"$prop`" Binding=`"{Binding $prop}`" Width=`"*`"/>`n"
    }

    $tabItems += @"

                <TabItem Header="$class">
                    <DockPanel Margin="8">
                        <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0,0,0,8">
                            <TextBox x:Name="TxtSearch$class" Width="250" Padding="6,4" FontSize="13" VerticalContentAlignment="Center" KeyDown="TxtSearch_KeyDown" Tag="$class"/>
                            <Button Content="Suchen" Padding="12,6" Margin="4" Click="BtnSearch_Click" Tag="$class"/>
                            <Button Content="Alle laden" Padding="12,6" Margin="4" Click="BtnLoadAll_Click" Tag="$class"/>
                            <Separator Margin="8,0"/>
                            <Button Content="+ Neu" Padding="12,6" Margin="4" Click="BtnAdd_Click" Tag="$class" FontWeight="Bold"/>
                            <Button Content="X Loeschen" Padding="12,6" Margin="4" Click="BtnDelete_Click" Tag="$class"/>
                        </StackPanel>
                        <StatusBar DockPanel.Dock="Bottom"><StatusBarItem><TextBlock x:Name="TxtStatus$class" Text="Bereit."/></StatusBarItem></StatusBar>
                        <DataGrid x:Name="Grid$class" AutoGenerateColumns="False" CanUserAddRows="False" IsReadOnly="False" SelectionMode="Single" FontSize="13" RowEditEnding="DataGrid_RowEditEnding" Tag="$class">
                            <DataGrid.Columns>
$dgCols                            </DataGrid.Columns>
                        </DataGrid>
                    </DockPanel>
                </TabItem>
"@
}

@"
<Window x:Class="$ProjectName.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$ProjectName" Height="700" Width="1000"
        WindowStartupLocation="CenterScreen" Loaded="Window_Loaded">
    <Window.Resources>
        <Style TargetType="Button"><Setter Property="Cursor" Value="Hand"/><Setter Property="FontSize" Value="13"/></Style>
    </Window.Resources>
    <DockPanel>
        <Border DockPanel.Dock="Top" Background="#1B4332" Padding="14,10">
            <TextBlock Text="$ProjectName" FontSize="18" FontWeight="Bold" Foreground="White"/>
        </Border>
        <TabControl Margin="8" FontSize="13">$tabItems
        </TabControl>
    </DockPanel>
</Window>
"@ | Set-Content "$BaseDir\MainWindow.xaml"

# ── MainWindow.xaml.cs ────────────────────────────────────────────
$serviceFields = ($tableInfos | ForEach-Object {
    $cl = $_.ClassName
    $lower = $cl.ToLower()
    "        private ${cl}Service _${lower}Service = null!;"
}) -join "`n"

$initServices = ($tableInfos | ForEach-Object {
    $cl = $_.ClassName
    $lower = $cl.ToLower()
    "            _${lower}Service = new ${cl}Service(db);"
}) -join "`n"

$loadCalls = ($tableInfos | ForEach-Object { "            Load$($_.ClassName)();" }) -join "`n"

$loadMethods = ($tableInfos | ForEach-Object {
    $cl = $_.ClassName
    $lower = $cl.ToLower()
    @"
        private void Load$cl()
        {
            var data = _${lower}Service.GetAll();
            Grid$cl.ItemsSource = data;
            TxtStatus$cl.Text = `$"{data.Count} Eintraege geladen.";
        }
"@
}) -join "`n`n"

$loadAllCases = ($tableInfos | ForEach-Object { "                case `"$($_.ClassName)`": Load$($_.ClassName)(); break;" }) -join "`n"

$searchCases = ($tableInfos | ForEach-Object {
    $cl = $_.ClassName
    $lower = $cl.ToLower()
    $textCols = $_.Columns | Where-Object { (ConvertTo-CSharpType $_.Type) -eq "string" -and -not $_.IsPK }
    if ($textCols) {
        @"
                case "$cl":
                {
                    var keyword = TxtSearch$cl.Text.Trim();
                    if (string.IsNullOrEmpty(keyword)) { Load$cl(); break; }
                    var results = _${lower}Service.Search(keyword);
                    Grid$cl.ItemsSource = results;
                    TxtStatus$cl.Text = `$"{results.Count} Treffer fuer '{keyword}'.";
                    break;
                }
"@
    } else {
        "                case `"$cl`": Load$cl(); break;"
    }
}) -join "`n"

$addCases = ($tableInfos | ForEach-Object {
    $cl = $_.ClassName
    @"
                case "$cl":
                    _db.${cl}s.Add(new $cl());
                    _db.SaveChanges();
                    Load$cl();
                    TxtStatus$cl.Text = "Neuer Eintrag erstellt.";
                    break;
"@
}) -join "`n"

$deleteCases = ($tableInfos | ForEach-Object {
    $cl = $_.ClassName
    $lower = $cl.ToLower()
    $pkCol = $_.Columns | Where-Object { $_.IsPK } | Select-Object -First 1
    $pkProp = if ($pkCol) { ConvertTo-PascalCase $pkCol.Name } else { "Id" }
    @"
                case "$cl":
                    if (Grid$cl.SelectedItem is $cl ${lower}Sel && ${lower}Sel.$pkProp.HasValue)
                    {
                        if (MessageBox.Show(`$"Eintrag #{${lower}Sel.$pkProp} loeschen?", "Loeschen", MessageBoxButton.YesNo, MessageBoxImage.Warning) == MessageBoxResult.Yes)
                        {
                            _${lower}Service.Delete(${lower}Sel.$pkProp.Value);
                            Load$cl();
                            TxtStatus$cl.Text = "Eintrag geloescht.";
                        }
                    }
                    break;
"@
}) -join "`n"

$updateCases = ($tableInfos | ForEach-Object {
    $cl = $_.ClassName
    $lower = $cl.ToLower()
    @"
                    case "$cl":
                        if (e.Row.Item is $cl ${lower}Item) _${lower}Service.Update(${lower}Item);
                        break;
"@
}) -join "`n"

@"
using System;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using $ProjectName.Services;
using $ProjectName.Models;

namespace $ProjectName
{
    public partial class MainWindow : Window
    {
        private AppDbContext _db = null!;
$serviceFields

        public MainWindow() { InitializeComponent(); }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            _db = new AppDbContext();
$initServices
$loadCalls
        }

$loadMethods

        private void BtnLoadAll_Click(object sender, RoutedEventArgs e)
        {
            var tag = (sender as Button)?.Tag?.ToString();
            switch (tag)
            {
$loadAllCases
            }
        }

        private void BtnSearch_Click(object sender, RoutedEventArgs e)
        {
            var tag = (sender as Button)?.Tag?.ToString();
            switch (tag)
            {
$searchCases
            }
        }

        private void TxtSearch_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter) BtnSearch_Click(sender, e);
        }

        private void BtnAdd_Click(object sender, RoutedEventArgs e)
        {
            var tag = (sender as Button)?.Tag?.ToString();
            switch (tag)
            {
$addCases
            }
        }

        private void BtnDelete_Click(object sender, RoutedEventArgs e)
        {
            var tag = (sender as Button)?.Tag?.ToString();
            switch (tag)
            {
$deleteCases
            }
        }

        private void DataGrid_RowEditEnding(object sender, DataGridRowEditEndingEventArgs e)
        {
            if (e.EditAction != DataGridEditAction.Commit) return;
            Dispatcher.BeginInvoke(new Action(() =>
            {
                var tag = (sender as DataGrid)?.Tag?.ToString();
                switch (tag)
                {
$updateCases
                }
            }));
        }
    }
}
"@ | Set-Content "$BaseDir\MainWindow.xaml.cs"

# ── Fertig ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "===================================================" -ForegroundColor Blue
Write-Host "  Projekt erfolgreich erstellt!" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  Ordner: $BaseDir\" -ForegroundColor Yellow
Write-Host ""
foreach ($ti in $tableInfos) {
    Write-Host "    Models\$($ti.ClassName).cs" -ForegroundColor Cyan
    Write-Host "    Services\$($ti.ClassName)Service.cs (CRUD)" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "  Features:" -ForegroundColor Green
Write-Host "    - Model-Klassen mit [Table], [Key], [ForeignKey]"
Write-Host "    - AppDbContext mit DbSets"
Write-Host "    - Service-Klassen mit Create/Read/Search/Update/Delete"
Write-Host "    - WPF MainWindow mit DataGrid (Tab pro Tabelle)"
Write-Host "    - Inline-Bearbeitung + Suche + Hinzufuegen + Loeschen"
Write-Host ""
Write-Host "  Oeffne in Visual Studio und fuehre 'dotnet restore' aus."
Write-Host ""
