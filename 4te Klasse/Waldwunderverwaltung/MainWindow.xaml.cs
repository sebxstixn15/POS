using System.Collections.Generic;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using Waldwunderverwaltung.Models;
using Waldwunderverwaltung.Services;
using Waldwunderverwaltung.Views;

namespace Waldwunderverwaltung
{
    /// <summary>
    /// Main application window – search, map, and navigation hub.
    /// </summary>
    public partial class MainWindow : Window
    {
        // Austria geographic bounds (given in the task)
        private const double LatTop    = 49.063175;
        private const double LatBottom = 46.308597;
        private const double LonLeft   =  9.362383;
        private const double LonRight  = 17.231941;

        private const double MarkerSize = 14;

        private readonly AppDbContext      _db;
        private readonly WaldwunderService _service;

        // Currently displayed search results
        private List<Waldwunder> _currentResults = new();

        // Map markers: keeps Ellipse → Waldwunder mapping for click handling
        private readonly Dictionary<Ellipse, Waldwunder> _markerMap = new();

        public MainWindow()
        {
            InitializeComponent();

            _db = new AppDbContext();
            _db.Database.EnsureCreated();
            _service = new WaldwunderService(_db);

            DrawMapBackground();
            UpdateStatus("Bereit. Bitte Suche starten.");
        }

        // ── Menu ──────────────────────────────────────────────────────────────

        private void MnuNeuesWaldwunder_Click(object sender, RoutedEventArgs e)
        {
            var dlg = new NeuesWaldwunderDialog { Owner = this };
            if (dlg.ShowDialog() == true)
                UpdateStatus("Neues Waldwunder wurde erfolgreich gespeichert.");
        }

        private void MnuBeenden_Click(object sender, RoutedEventArgs e) => Close();

        // ── Search ────────────────────────────────────────────────────────────

        private void SearchMode_Changed(object sender, RoutedEventArgs e)
        {
            if (ortPanel == null) return; // guard against InitializeComponent calls

            bool isOrt = rbOrt.IsChecked == true;
            ortPanel.Visibility      = isOrt ? Visibility.Visible   : Visibility.Collapsed;
            txtSuchbegriff.Visibility = isOrt ? Visibility.Collapsed : Visibility.Visible;
        }

        private void TxtSuchbegriff_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
                ExecuteSearch();
        }

        private void BtnSuchen_Click(object sender, RoutedEventArgs e) => ExecuteSearch();

        private void ExecuteSearch()
        {
            List<Waldwunder> results;

            if (rbStichwort.IsChecked == true)
            {
                string kw = txtSuchbegriff.Text.Trim();
                results = _service.SearchByKeyword(kw);
            }
            else if (rbArt.IsChecked == true)
            {
                string art = txtSuchbegriff.Text.Trim();
                results = _service.SearchByType(art);
            }
            else // Ort
            {
                string latTxt = txtLat.Text.Replace(',', '.');
                string lonTxt = txtLon.Text.Replace(',', '.');

                if (!double.TryParse(latTxt, NumberStyles.Float, CultureInfo.InvariantCulture, out double lat) ||
                    !double.TryParse(lonTxt, NumberStyles.Float, CultureInfo.InvariantCulture, out double lon))
                {
                    UpdateStatus("❌ Bitte gültige Dezimalwerte für Latitude und Longitude eingeben.");
                    return;
                }
                results = _service.SearchByLocation(lat, lon);
            }

            _currentResults = results;
            lstResults.Items.Clear();
            foreach (var w in results)
                lstResults.Items.Add(w);

            PlotMarkers(results);
            UpdateStatus($"{results.Count} Waldwunder gefunden.");
        }

        // ── List selection ────────────────────────────────────────────────────

        private void LstResults_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            btnAnzeigen.IsEnabled = lstResults.SelectedItem != null;
            HighlightMarker(lstResults.SelectedItem as Waldwunder);
        }

        // ── Anzeigen ──────────────────────────────────────────────────────────

        private void BtnAnzeigen_Click(object sender, RoutedEventArgs e)
        {
            if (lstResults.SelectedItem is Waldwunder selected)
            {
                var dlg = new WaldwunderDetailDialog(selected) { Owner = this };
                dlg.ShowDialog();
            }
        }

        // ── Map rendering ─────────────────────────────────────────────────────

        private void MapCanvas_SizeChanged(object sender, SizeChangedEventArgs e)
        {
            DrawMapBackground();
            PlotMarkers(_currentResults);
        }

        /// <summary>No-op: background is the satellite image set in XAML.</summary>
        private void DrawMapBackground() { }

        /// <summary>Plots Waldwunder markers on the canvas for each search result.</summary>
        private void PlotMarkers(List<Waldwunder> wunders)
        {
            // Remove old markers
            for (int i = mapCanvas.Children.Count - 1; i >= 0; i--)
            {
                if (mapCanvas.Children[i] is Ellipse)
                    mapCanvas.Children.RemoveAt(i);
            }
            _markerMap.Clear();

            double w = mapCanvas.ActualWidth;
            double h = mapCanvas.ActualHeight;
            if (w < 10 || h < 10) return;

            foreach (var wunder in wunders)
            {
                (double cx, double cy) = LatLonToCanvas(wunder.Latitude, wunder.Longitude, w, h);

                // White glow ring behind the marker
                var glow = new Ellipse
                {
                    Width  = MarkerSize + 6,
                    Height = MarkerSize + 6,
                    Fill   = new SolidColorBrush(Color.FromArgb(180, 255, 255, 255)),
                    IsHitTestVisible = false
                };
                Canvas.SetLeft(glow, cx - (MarkerSize + 6) / 2);
                Canvas.SetTop(glow,  cy - (MarkerSize + 6) / 2);
                mapCanvas.Children.Add(glow);

                var marker = new Ellipse
                {
                    Width  = MarkerSize,
                    Height = MarkerSize,
                    Fill   = new SolidColorBrush(Color.FromRgb(0xE8, 0x3A, 0x1A)),
                    Stroke = Brushes.White,
                    StrokeThickness = 2,
                    Cursor = Cursors.Hand,
                    ToolTip = $"{wunder.Name}\n{wunder.Province} · {wunder.Type}\nLat {wunder.Latitude:F4} / Lon {wunder.Longitude:F4}"
                };

                Canvas.SetLeft(marker, cx - MarkerSize / 2);
                Canvas.SetTop(marker,  cy - MarkerSize / 2);

                marker.MouseDown += (s, e) =>
                {
                    if (s is Ellipse el && _markerMap.TryGetValue(el, out var w2))
                        lstResults.SelectedItem = w2;
                };

                marker.MouseEnter += (s, e) =>
                {
                    if (s is Ellipse el)
                        el.Fill = new SolidColorBrush(Color.FromRgb(0xFF, 0xA5, 0x00));
                };

                marker.MouseLeave += (s, e) =>
                {
                    if (s is Ellipse el)
                    {
                        bool isSelected = lstResults.SelectedItem is Waldwunder sw &&
                                          _markerMap.TryGetValue(el, out var mw) &&
                                          mw == sw;
                        el.Fill = isSelected
                            ? new SolidColorBrush(Color.FromRgb(0xFF, 0xA5, 0x00))
                            : new SolidColorBrush(Color.FromRgb(0xE8, 0x3A, 0x1A));
                    }
                };

                mapCanvas.Children.Add(marker);
                _markerMap[marker] = wunder;
            }
        }

        /// <summary>Highlights the marker for the currently selected Waldwunder.</summary>
        private void HighlightMarker(Waldwunder? selected)
        {
            foreach (var (ellipse, wunder) in _markerMap)
            {
                ellipse.Fill = wunder == selected
                    ? new SolidColorBrush(Color.FromRgb(0xFF, 0x6B, 0x35))   // orange = selected
                    : new SolidColorBrush(Color.FromRgb(0x1B, 0x43, 0x32));  // dark green = normal
                ellipse.Width  = wunder == selected ? MarkerSize * 1.4 : MarkerSize;
                ellipse.Height = wunder == selected ? MarkerSize * 1.4 : MarkerSize;

                // Reposition to keep centered after size change
                double w = mapCanvas.ActualWidth;
                double h = mapCanvas.ActualHeight;
                (double cx, double cy) = LatLonToCanvas(wunder.Latitude, wunder.Longitude, w, h);
                Canvas.SetLeft(ellipse, cx - ellipse.Width  / 2);
                Canvas.SetTop(ellipse,  cy - ellipse.Height / 2);
            }
        }

        // ── Coordinate conversion ─────────────────────────────────────────────

        private static (double x, double y) LatLonToCanvas(
            double lat, double lon, double canvasW, double canvasH)
        {
            double x = (lon - LonLeft)  / (LonRight - LonLeft)  * canvasW;
            double y = (1 - (lat - LatBottom) / (LatTop - LatBottom)) * canvasH;
            return (x, y);
        }

        // ── Helpers ───────────────────────────────────────────────────────────

        private void UpdateStatus(string message) => txtStatus.Text = message;

        protected override void OnClosed(System.EventArgs e)
        {
            _db.Dispose();
            base.OnClosed(e);
        }
    }
}