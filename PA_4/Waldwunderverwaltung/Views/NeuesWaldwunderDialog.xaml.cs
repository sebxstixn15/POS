using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Windows;
using Microsoft.Win32;
using Waldwunderverwaltung.Models;
using Waldwunderverwaltung.Services;

namespace Waldwunderverwaltung.Views
{
    /// <summary>
    /// Dialog to create a new Waldwunder entry with associated images.
    /// </summary>
    public partial class NeuesWaldwunderDialog : Window
    {
        // Full source paths of selected images (before copying)
        private readonly List<string> _selectedImagePaths = new();

        public NeuesWaldwunderDialog()
        {
            InitializeComponent();

            // Populate Bundesland ComboBox
            cmbProvince.ItemsSource = System.Enum.GetValues(typeof(Bundesland));
            cmbProvince.SelectedIndex = 0;
        }

        // ── Image list management ──────────────────────────────────────────────

        private void BtnAddImages_Click(object sender, RoutedEventArgs e)
        {
            var dlg = new OpenFileDialog
            {
                Title = "Bilder auswählen",
                Filter = "Bilddateien|*.jpg;*.jpeg;*.png;*.bmp;*.gif;*.tif;*.tiff|Alle Dateien|*.*",
                Multiselect = true
            };

            if (dlg.ShowDialog() == true)
            {
                foreach (string path in dlg.FileNames)
                {
                    if (!_selectedImagePaths.Contains(path))
                    {
                        _selectedImagePaths.Add(path);
                        lstImages.Items.Add(Path.GetFileName(path));
                    }
                }
            }
        }

        private void BtnRemoveImage_Click(object sender, RoutedEventArgs e)
        {
            int idx = lstImages.SelectedIndex;
            if (idx >= 0)
            {
                _selectedImagePaths.RemoveAt(idx);
                lstImages.Items.RemoveAt(idx);
            }
        }

        // ── Buttons ───────────────────────────────────────────────────────────

        private void BtnRegistrieren_Click(object sender, RoutedEventArgs e)
        {
            if (!Validate()) return;

            double lat = double.Parse(txtLatitude.Text.Replace(',', '.'), CultureInfo.InvariantCulture);
            double lon = double.Parse(txtLongitude.Text.Replace(',', '.'), CultureInfo.InvariantCulture);

            using var db = new AppDbContext();
            db.Database.EnsureCreated();

            var service = new WaldwunderService(db);

            // Save Waldwunder record
            Waldwunder wunder = service.Create(
                name:        txtName.Text.Trim(),
                description: txtDescription.Text.Trim(),
                province:    (Bundesland)cmbProvince.SelectedItem,
                latitude:    lat,
                longitude:   lon,
                type:        txtType.Text.Trim()
            );

            // Copy selected images and save Bilder records
            foreach (string srcPath in _selectedImagePaths)
            {
                string storedName = BilderService.CopyToImagesFolder(srcPath);
                service.AddBild(wunder.Id!.Value, storedName);
            }

            DialogResult = true;
        }

        private void BtnCancel_Click(object sender, RoutedEventArgs e)
        {
            DialogResult = false;
        }

        // ── Validation ────────────────────────────────────────────────────────

        private bool Validate()
        {
            var errors = new List<string>();

            if (string.IsNullOrWhiteSpace(txtName.Text))
                errors.Add("Name darf nicht leer sein.");

            if (string.IsNullOrWhiteSpace(txtDescription.Text))
                errors.Add("Beschreibung darf nicht leer sein.");

            if (string.IsNullOrWhiteSpace(txtType.Text))
                errors.Add("Art darf nicht leer sein.");

            string latText = txtLatitude.Text.Replace(',', '.');
            string lonText = txtLongitude.Text.Replace(',', '.');

            if (!double.TryParse(latText, NumberStyles.Float, CultureInfo.InvariantCulture, out _))
                errors.Add("Latitude muss eine gültige Dezimalzahl sein (z.B. 48.13).");

            if (!double.TryParse(lonText, NumberStyles.Float, CultureInfo.InvariantCulture, out _))
                errors.Add("Longitude muss eine gültige Dezimalzahl sein (z.B. 16.69).");

            if (errors.Count > 0)
            {
                txtValidation.Text = string.Join("\n", errors);
                txtValidation.Visibility = Visibility.Visible;
                return false;
            }

            txtValidation.Visibility = Visibility.Collapsed;
            return true;
        }
    }
}
