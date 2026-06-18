<#
.SYNOPSIS
    Erstellt ein WPF CRUD-Projekt aus einer .csv Datei.
    
.DESCRIPTION
    Liest die erste Zeile der CSV aus, leitet die Spaltennamen ab
    und erstellt ein WPF Projekt mit CsvHelper (NuGet), einem DataGrid
    und den nötigen Speicher-Funktionen.
#>
param([Parameter(Mandatory=$true)][string]$CsvFile, [string]$ProjectName)

if (-not (Test-Path $CsvFile)) {
    Write-Host "Fehler: CSV Datei nicht gefunden!" -ForegroundColor Red; exit 1
}

$CsvBasename = [System.IO.Path]::GetFileNameWithoutExtension($CsvFile)
if (-not $ProjectName) { $ProjectName = "${CsvBasename}App" }
$ClassName = $CsvBasename -replace '[^a-zA-Z0-9]',''
if ($ClassName.Length -eq 0) { $ClassName = "CsvItem" }
$ClassName = $ClassName.Substring(0,1).ToUpper() + $ClassName.Substring(1)

$BaseDir = $ProjectName
if (Test-Path $BaseDir) { Write-Host "Fehler: Ordner existiert bereits!" -ForegroundColor Red; exit 1 }

$firstLine = Get-Content $CsvFile -TotalCount 1
$separator = ","
if ($firstLine -match ";") { $separator = ";" }

$rawHeaders = $firstLine -split $separator
$headers = @()
$props = @()

foreach ($raw in $rawHeaders) {
    $h = $raw -replace '"',''
    $p = $h -replace '[^a-zA-Z0-9]',''
    if ($p -match '^[0-9]') { $p = "Col_$p" }
    if ([string]::IsNullOrWhiteSpace($p)) { $p = "Column$($headers.Count)" }
    $p = $p.Substring(0,1).ToUpper() + $p.Substring(1)
    
    $headers += $h
    $props += $p
}

Write-Host "===================================================" -ForegroundColor Blue
Write-Host "  WPF CSV App Generator" -ForegroundColor Blue
Write-Host "===================================================" -ForegroundColor Blue
Write-Host "CSV:      $CsvFile" -ForegroundColor Yellow
Write-Host "Trenner:  '$separator'" -ForegroundColor Yellow
Write-Host "Projekt:  $ProjectName" -ForegroundColor Yellow
Write-Host "Klasse:   $ClassName" -ForegroundColor Yellow

Write-Host "[1/5] Erstelle Struktur..." -ForegroundColor Green
New-Item -ItemType Directory -Path "$BaseDir\Models" -Force | Out-Null
New-Item -ItemType Directory -Path "$BaseDir\Services" -Force | Out-Null

Write-Host "[2/5] Kopiere CSV Datei..." -ForegroundColor Green
Copy-Item $CsvFile "$BaseDir\"

Write-Host "[3/5] Generiere Model..." -ForegroundColor Green
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("using CsvHelper.Configuration.Attributes;")
[void]$sb.AppendLine("namespace $ProjectName.Models {")
[void]$sb.AppendLine("    public class $ClassName {")
for ($i=0; $i -lt $headers.Count; $i++) {
    [void]$sb.AppendLine("        [Name(`"$($headers[$i])`")]")
    [void]$sb.AppendLine("        public string $($props[$i]) { get; set; } = string.Empty;")
}
[void]$sb.AppendLine("    }")
[void]$sb.AppendLine("}")
Set-Content "$BaseDir\Models\$ClassName.cs" $sb.ToString()

Write-Host "[4/5] Generiere CsvDataService..." -ForegroundColor Green
@"
using CsvHelper;
using CsvHelper.Configuration;
using System.Globalization;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using $ProjectName.Models;

namespace $ProjectName.Services {
    public class CsvDataService {
        private readonly string _filePath;
        private readonly CsvConfiguration _config;
        
        public CsvDataService(string filePath) {
            _filePath = filePath;
            _config = new CsvConfiguration(CultureInfo.InvariantCulture) {
                Delimiter = "$separator",
                HasHeaderRecord = true
            };
        }
        
        public List<$ClassName> Load() {
            if (!File.Exists(_filePath)) return new List<$ClassName>();
            using var reader = new StreamReader(_filePath);
            using var csv = new CsvReader(reader, _config);
            return csv.GetRecords<$ClassName>().ToList();
        }
        
        public void Save(IEnumerable<$ClassName> items) {
            using var writer = new StreamWriter(_filePath);
            using var csv = new CsvWriter(writer, _config);
            csv.WriteRecords(items);
        }
    }
}
"@ | Set-Content "$BaseDir\Services\CsvDataService.cs"

Write-Host "[5/5] Generiere WPF Projekt..." -ForegroundColor Green
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
    <PackageReference Include="CsvHelper" Version="31.0.0" />
  </ItemGroup>
  <ItemGroup>
    <None Update="$([System.IO.Path]::GetFileName($CsvFile))">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
"@ | Set-Content "$BaseDir\$ProjectName.csproj"

@"
<Application x:Class="$ProjectName.App" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" StartupUri="MainWindow.xaml" />
"@ | Set-Content "$BaseDir\App.xaml"

@"
using System.Windows;
namespace $ProjectName { public partial class App : Application { } }
"@ | Set-Content "$BaseDir\App.xaml.cs"

$dgCols = ""
foreach ($p in $props) {
    $dgCols += "                    <DataGridTextColumn Header=`"$p`" Binding=`"{Binding $p}`" Width=`"*`"/>`n"
}

@"
<Window x:Class="$ProjectName.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$ProjectName (CSV Editor)" Height="600" Width="900" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style TargetType="Button"><Setter Property="Padding" Value="12,6"/><Setter Property="Margin" Value="4"/><Setter Property="Cursor" Value="Hand"/></Style>
    </Window.Resources>
    <DockPanel>
        <Border DockPanel.Dock="Top" Background="#1B4332" Padding="14,10">
            <TextBlock Text="$ProjectName - $([System.IO.Path]::GetFileName($CsvFile))" FontSize="18" FontWeight="Bold" Foreground="White"/>
        </Border>
        <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="8">
            <Button Content="💾 Speichern" FontWeight="Bold" Click="BtnSave_Click"/>
            <Separator Margin="8,0"/>
            <Button Content="➕ Neu" Click="BtnAdd_Click"/>
            <Button Content="❌ Löschen" Click="BtnDelete_Click"/>
        </StackPanel>
        <DataGrid x:Name="MainGrid" Margin="8" AutoGenerateColumns="False" CanUserAddRows="False" FontSize="13">
            <DataGrid.Columns>
$dgCols            </DataGrid.Columns>
        </DataGrid>
    </DockPanel>
</Window>
"@ | Set-Content "$BaseDir\MainWindow.xaml"

@"
using System;
using System.Collections.ObjectModel;
using System.Windows;
using $ProjectName.Models;
using $ProjectName.Services;

namespace $ProjectName
{
    public partial class MainWindow : Window
    {
        private readonly CsvDataService _service;
        public ObservableCollection<$ClassName> Items { get; set; }

        public MainWindow()
        {
            InitializeComponent();
            _service = new CsvDataService("$([System.IO.Path]::GetFileName($CsvFile))");
            try {
                Items = new ObservableCollection<$ClassName>(_service.Load());
            } catch (Exception ex) {
                MessageBox.Show($"Fehler beim Laden: {ex.Message}");
                Items = new ObservableCollection<$ClassName>();
            }
            MainGrid.ItemsSource = Items;
        }

        private void BtnSave_Click(object sender, RoutedEventArgs e)
        {
            try {
                _service.Save(Items);
                MessageBox.Show("Erfolgreich gespeichert!", "Erfolg", MessageBoxButton.OK, MessageBoxImage.Information);
            } catch (Exception ex) {
                MessageBox.Show($"Fehler: {ex.Message}", "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
        private void BtnAdd_Click(object sender, RoutedEventArgs e) { Items.Add(new $ClassName()); }
        private void BtnDelete_Click(object sender, RoutedEventArgs e) { if (MainGrid.SelectedItem is $ClassName item) Items.Remove(item); }
    }
}
"@ | Set-Content "$BaseDir\MainWindow.xaml.cs"

Write-Host "✅ Fertig! Öffne die Solution in Visual Studio." -ForegroundColor Green
