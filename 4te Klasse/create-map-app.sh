#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  create-map-app.sh
#  Erstellt automatisch ein WPF Projekt für eine Map-App mit Markern.
# ═══════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ $# -lt 5 ]; then
    echo -e "${RED}Fehler: Zu wenige Argumente!${NC}"
    echo "Verwendung: $0 <Bild.jpg|png> <LonLeft> <LonRight> <LatBottom> <LatTop> [ProjektName]"
    exit 1
fi

MAP_IMAGE="$1"
LON_LEFT="$2"
LON_RIGHT="$3"
LAT_BOTTOM="$4"
LAT_TOP="$5"
PROJECT_NAME="${6:-MapMarkerApp}"
BASE_DIR="$PROJECT_NAME"

if [ ! -f "$MAP_IMAGE" ]; then
    echo -e "${RED}Fehler: Bilddatei '$MAP_IMAGE' nicht gefunden!${NC}"
    exit 1
fi

IMAGE_NAME=$(basename "$MAP_IMAGE")

if [ -d "$BASE_DIR" ]; then
    echo -e "${RED}Fehler: Ordner '$BASE_DIR' existiert bereits!${NC}"
    exit 1
fi

echo -e "${GREEN}[1/3] Erstelle Verzeichnisstruktur und kopiere Bild...${NC}"
mkdir -p "$BASE_DIR"
cp "$MAP_IMAGE" "$BASE_DIR/$IMAGE_NAME"

echo -e "${GREEN}[2/3] Generiere WPF Projekt ($PROJECT_NAME)...${NC}"

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
    <Resource Include="$IMAGE_NAME" />
  </ItemGroup>
</Project>
EOF

# App.xaml
cat > "$BASE_DIR/App.xaml" << EOF
<Application x:Class="$PROJECT_NAME.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
</Application>
EOF

# App.xaml.cs
cat > "$BASE_DIR/App.xaml.cs" << EOF
using System.Windows;
namespace $PROJECT_NAME { public partial class App : Application { } }
EOF

# MainWindow.xaml
cat > "$BASE_DIR/MainWindow.xaml" << EOF
<Window x:Class="$PROJECT_NAME.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$PROJECT_NAME" Height="600" Width="800"
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
            <!-- MapCanvas -->
            <Canvas x:Name="MapCanvas" ClipToBounds="True" SizeChanged="MapCanvas_SizeChanged">
                <Canvas.Background>
                    <ImageBrush ImageSource="$IMAGE_NAME" Stretch="Fill"/>
                </Canvas.Background>
            </Canvas>
        </Border>
    </Grid>
</Window>
EOF

# MainWindow.xaml.cs
cat > "$BASE_DIR/MainWindow.xaml.cs" << EOF
using System;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;

namespace $PROJECT_NAME
{
    public partial class MainWindow : Window
    {
        // Dynamisch generierte Koordinaten-Grenzen basierend auf Parametern
        private const double LatTop    = $LAT_TOP;
        private const double LatBottom = $LAT_BOTTOM;
        private const double LonLeft   = $LON_LEFT;
        private const double LonRight  = $LON_RIGHT;
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
EOF

echo -e "${GREEN}[3/3] Fertig! Projekt wurde in ./$BASE_DIR erstellt.${NC}"
echo "Zum Starten:"
echo "cd $BASE_DIR && dotnet run"
