using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Waldwunderverwaltung.Models;
using Waldwunderverwaltung.Services;

namespace Waldwunderverwaltung.Views
{
    /// <summary>
    /// Shows all data and images of a selected Waldwunder.
    /// </summary>
    public partial class WaldwunderDetailDialog : Window
    {
        public WaldwunderDetailDialog(Waldwunder wunder)
        {
            InitializeComponent();
            PopulateFields(wunder);
            LoadImages(wunder);
        }

        private void PopulateFields(Waldwunder wunder)
        {
            Title = $"Waldwunder – {wunder.Name}";
            txtTitle.Text = $"🌲 {wunder.Name}";
            txtDescription.Text = wunder.Description;
            txtProvince.Text = wunder.Province.ToString();
            txtType.Text = wunder.Type;
            txtLatitude.Text = wunder.Latitude.ToString("F6");
            txtLongitude.Text = wunder.Longitude.ToString("F6");
            txtId.Text = wunder.Id?.ToString() ?? "—";
        }

        private void LoadImages(Waldwunder wunder)
        {
            imagePanel.Children.Clear();

            if (wunder.Bilder == null || wunder.Bilder.Count == 0)
            {
                imagePanel.Children.Add(new TextBlock
                {
                    Text = "Keine Bilder vorhanden.",
                    Foreground = Brushes.Gray,
                    VerticalAlignment = VerticalAlignment.Center,
                    Margin = new Thickness(8)
                });
                return;
            }

            foreach (Bilder bild in wunder.Bilder)
            {
                string imagePath = BilderService.GetImagePath(bild.Name);

                if (!File.Exists(imagePath))
                    continue;

                try
                {
                    var bi = new BitmapImage();
                    bi.BeginInit();
                    bi.CacheOption = BitmapCacheOption.OnLoad;
                    bi.UriSource = new Uri(imagePath, UriKind.Absolute);
                    bi.DecodePixelHeight = 200;
                    bi.EndInit();

                    var border = new Border
                    {
                        Margin = new Thickness(4),
                        CornerRadius = new CornerRadius(6),
                        BorderBrush = new SolidColorBrush(Color.FromRgb(0xC8, 0xD8, 0xC8)),
                        BorderThickness = new Thickness(1),
                        ToolTip = bild.Name
                    };

                    var img = new Image
                    {
                        Source = bi,
                        Height = 200,
                        Stretch = Stretch.Uniform
                    };
                    RenderOptions.SetBitmapScalingMode(img, BitmapScalingMode.HighQuality);

                    border.Child = img;

                    imagePanel.Children.Add(border);
                }
                catch
                {
                    // Skip unreadable images silently
                }
            }
        }

        private void BtnClose_Click(object sender, RoutedEventArgs e) => Close();
    }
}
