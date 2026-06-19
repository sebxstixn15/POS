param (
    [Parameter(Mandatory=$true, Position=0)][string]$MapImage,
    [Parameter(Mandatory=$true, Position=1)][double]$LonLeft,
    [Parameter(Mandatory=$true, Position=2)][double]$LonRight,
    [Parameter(Mandatory=$true, Position=3)][double]$LatBottom,
    [Parameter(Mandatory=$true, Position=4)][double]$LatTop,
    [Parameter(Position=5)][string]$ProjectName = "MapMarkerApp"
)

if (-not (Test-Path $MapImage)) {
    Write-Host "Fehler: Bilddatei '$MapImage' nicht gefunden!" -ForegroundColor Red
    exit 1
}

$ImageName = [System.IO.Path]::GetFileName($MapImage)

# ═══════════════════════════════════════════════════════════════════
#  create-map-app.ps1
#  Erstellt automatisch ein WPF Projekt für eine Map-App mit Markern.
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  WPF Map App Generator" -ForegroundColor Cyan
Write-Host "==================================================="
Write-Host "  Projektname:   $ProjectName" -ForegroundColor Yellow
Write-Host ""

$BaseDir = $ProjectName

if (Test-Path $BaseDir) {
    Write-Host "Fehler: Ordner '$BaseDir' existiert bereits!" -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Erstelle Verzeichnisstruktur und kopiere Bild..." -ForegroundColor Green
New-Item -ItemType Directory -Path "$BaseDir" | Out-Null
Copy-Item $MapImage "$BaseDir\$ImageName"

Write-Host "[2/3] Generiere Projektdateien..." -ForegroundColor Green

# csproj
$csproj = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
"@
Set-Content -Path "$BaseDir\$ProjectName.csproj" -Value $csproj -Encoding UTF8

$csproj += @"
  <ItemGroup>
    <None Update="$ImageName">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
"@
# Den originalen csproj string modifizieren war falsch, ich mach es sauber:
$csproj = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <None Update="$ImageName">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
"@
Set-Content -Path "$BaseDir\$ProjectName.csproj" -Value $csproj -Encoding UTF8

# App.xaml
$appXaml = @"
<Application x:Class="$ProjectName.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
</Application>
"@
Set-Content -Path "$BaseDir\App.xaml" -Value $appXaml -Encoding UTF8

# App.xaml.cs
$appXamlCs = @"
using System.Windows;
namespace $ProjectName { public partial class App : Application { } }
"@
Set-Content -Path "$BaseDir\App.xaml.cs" -Value $appXamlCs -Encoding UTF8

# MainWindow.xaml
$mainWindowXaml = @"
<Window x:Class="$ProjectName.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$ProjectName" Height="600" Width="800"
        WindowStartupLocation="CenterScreen">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="10" HorizontalAlignment="Center">
            <TextBlock Text="Latitude:" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBox x:Name="txtLat" Width="100" Text="47.5" VerticalContentAlignment="Center" Margin="0,0,15,0"/>
            
            <TextBlock Text="Longitude:" VerticalAlignment="Center" Margin="0,0,5,0"/>
            <TextBox x:Name="txtLon" Width="100" Text="13.5" VerticalContentAlignment="Center" Margin="0,0,15,0"/>
            
            <Button Content="Set Marker" Width="100" Padding="5" Click="BtnSetMarker_Click"/>
        </StackPanel>

        <Border Grid.Row="1" Background="#E0E0E0" Margin="10">
            <!-- MapCanvas mit Bild als Hintergrund -->
            <Canvas x:Name="MapCanvas" ClipToBounds="True" SizeChanged="MapCanvas_SizeChanged">
                <Canvas.Background>
                    <ImageBrush ImageSource="$ImageName" Stretch="Fill"/>
                </Canvas.Background>
            </Canvas>
        </Border>
    </Grid>
</Window>
"@
Set-Content -Path "$BaseDir\MainWindow.xaml" -Value $mainWindowXaml -Encoding UTF8

# MainWindow.xaml.cs
$mainWindowXamlCs = @"
using System;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;

namespace $ProjectName
{
    public partial class MainWindow : Window
    {
        // Dynamisch generierte Koordinaten-Grenzen basierend auf Parametern
        private const double LatTop    = $($LatTop.ToString([System.Globalization.CultureInfo]::InvariantCulture));
        private const double LatBottom = $($LatBottom.ToString([System.Globalization.CultureInfo]::InvariantCulture));
        private const double LonLeft   = $($LonLeft.ToString([System.Globalization.CultureInfo]::InvariantCulture));
        private const double LonRight  = $($LonRight.ToString([System.Globalization.CultureInfo]::InvariantCulture));
        private const double MarkerSize = 14;

        public MainWindow()
        {
            InitializeComponent();
        }

        private void BtnSetMarker_Click(object sender, RoutedEventArgs e)
        {
            string latTxt = txtLat.Text.Replace(',', '.');
            string lonTxt = txtLon.Text.Replace(',', '.');

            if (double.TryParse(latTxt, NumberStyles.Float, CultureInfo.InvariantCulture, out double lat) &&
                double.TryParse(lonTxt, NumberStyles.Float, CultureInfo.InvariantCulture, out double lon))
            {
                DrawMarker(lat, lon);
            }
            else
            {
                MessageBox.Show("Bitte gültige Koordinaten eingeben.", "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void MapCanvas_SizeChanged(object sender, SizeChangedEventArgs e)
        {
            // Wenn sich die Größe ändert, Marker neu zeichnen
            BtnSetMarker_Click(this, new RoutedEventArgs());
        }

        private void DrawMarker(double lat, double lon)
        {
            MapCanvas.Children.Clear();

            double w = MapCanvas.ActualWidth;
            double h = MapCanvas.ActualHeight;
            if (w < 10 || h < 10) return;

            (double cx, double cy) = LatLonToCanvas(lat, lon, w, h);

            // Weißer Rand (Glow)
            var glow = new Ellipse
            {
                Width = MarkerSize + 6,
                Height = MarkerSize + 6,
                Fill = new SolidColorBrush(Color.FromArgb(180, 255, 255, 255)),
                IsHitTestVisible = false
            };
            Canvas.SetLeft(glow, cx - (MarkerSize + 6) / 2);
            Canvas.SetTop(glow, cy - (MarkerSize + 6) / 2);
            MapCanvas.Children.Add(glow);

            // Marker zeichnen
            var marker = new Ellipse
            {
                Width = MarkerSize,
                Height = MarkerSize,
                Fill = new SolidColorBrush(Color.FromRgb(0xE8, 0x3A, 0x1A)),
                Stroke = Brushes.White,
                StrokeThickness = 2
            };

            Canvas.SetLeft(marker, cx - MarkerSize / 2);
            Canvas.SetTop(marker, cy - MarkerSize / 2);

            MapCanvas.Children.Add(marker);
        }

        private static (double x, double y) LatLonToCanvas(double lat, double lon, double canvasW, double canvasH)
        {
            double x = (lon - LonLeft) / (LonRight - LonLeft) * canvasW;
            double y = (1 - (lat - LatBottom) / (LatTop - LatBottom)) * canvasH;
            return (x, y);
        }
    }
}
"@
Set-Content -Path "$BaseDir\MainWindow.xaml.cs" -Value $mainWindowXamlCs -Encoding UTF8

Write-Host ""
Write-Host "[3/3] Fertig! Projekt wurde in ./$BaseDir erstellt." -ForegroundColor Green
Write-Host "Zum Starten:"
Write-Host "cd $BaseDir"
Write-Host "dotnet run"
Write-Host ""
