using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using Fluent;

namespace WPF_WordPad
{
    public partial class MainWindow : RibbonWindow
    {
        // ──────────────────────────────────────────────────────────
        // FIELDS
        // ──────────────────────────────────────────────────────────
        private string? _currentFilePath = null;
        private bool _isModified         = false;
        private double _zoomLevel        = 1.0;
        private const double ZoomStep    = 0.1;
        private const double ZoomMin     = 0.25;
        private const double ZoomMax     = 4.0;

        private readonly List<string> _recentFiles = new();
        private const int MaxRecentFiles = 8;
        private const string RecentFilesKey = "WPF_WordPad_RecentFiles";

        // Track SelectionChanged re-entrance to avoid infinite loops
        private bool _suppressSelectionChanged = false;

        // ──────────────────────────────────────────────────────────
        // CONSTRUCTOR & INIT
        // ──────────────────────────────────────────────────────────
        public MainWindow()
        {
            InitializeComponent();
            LoadFontFamilies();
            LoadRecentFiles();
        }

        private void Window_Loaded(object sender, RoutedEventArgs e)
        {
            UpdateTitle();
            UpdateStatusBar();
            richTextBox1.Focus();
        }

        private void LoadFontFamilies()
        {
            FontFamilyCombo.ItemsSource = Fonts.SystemFontFamilies
                                               .OrderBy(f => f.Source)
                                               .Select(f => f.Source);
            FontFamilyCombo.SelectedItem = "Segoe UI";
        }

        // ──────────────────────────────────────────────────────────
        // WINDOW TITLE & STATUS
        // ──────────────────────────────────────────────────────────
        private void UpdateTitle()
        {
            string name = _currentFilePath is null
                ? "Neue Datei"
                : Path.GetFileName(_currentFilePath);
            Title = $"{name}{(_isModified ? " *" : "")} – WPF WordPad";
            StatusFileName.Text = name;
            StatusModified.Text = _isModified ? "● Nicht gespeichert" : "";
        }

        private void UpdateStatusBar()
        {
            var text = GetAllText();
            int words = text.Trim().Length == 0
                ? 0
                : text.Split(new[] { ' ', '\n', '\r', '\t' },
                              StringSplitOptions.RemoveEmptyEntries).Length;
            StatusWords.Text = $"Wörter: {words}";
            StatusChars.Text = $"Zeichen: {text.Length}";
        }

        private string GetAllText()
        {
            return new TextRange(richTextBox1.Document.ContentStart,
                                 richTextBox1.Document.ContentEnd).Text;
        }

        // ──────────────────────────────────────────────────────────
        // FILE COMMANDS
        // ──────────────────────────────────────────────────────────
        private void New_Executed(object sender, ExecutedRoutedEventArgs e)
        {
            if (!ConfirmDiscard()) return;
            richTextBox1.Document.Blocks.Clear();
            _currentFilePath = null;
            _isModified = false;
            UpdateTitle();
            UpdateStatusBar();
        }

        private void Open_Executed(object sender, ExecutedRoutedEventArgs e)
        {
            if (!ConfirmDiscard()) return;
            OpenFileDialog dlg = new()
            {
                Filter = "XAML-Dokument (*.xaml)|*.xaml|Alle Dateien (*.*)|*.*",
                Title  = "Datei öffnen"
            };
            if (dlg.ShowDialog() != true) return;
            LoadFile(dlg.FileName);
        }

        private void Save_Executed(object sender, ExecutedRoutedEventArgs e)
        {
            if (_currentFilePath is null)
                SaveAs_Executed(sender, e);
            else
                SaveFile(_currentFilePath);
        }

        private void SaveAs_Executed(object sender, ExecutedRoutedEventArgs e)
        {
            SaveFileDialog dlg = new()
            {
                Filter           = "XAML-Dokument (*.xaml)|*.xaml|Alle Dateien (*.*)|*.*",
                Title            = "Speichern unter",
                DefaultExt       = "xaml",
                FileName         = _currentFilePath is null
                                   ? "Dokument"
                                   : Path.GetFileNameWithoutExtension(_currentFilePath)
            };
            if (dlg.ShowDialog() != true) return;
            SaveFile(dlg.FileName);
        }

        private void Print_Executed(object sender, ExecutedRoutedEventArgs e)
        {
            PrintDialog dlg = new();
            if (dlg.ShowDialog() != true) return;

            // Use DocumentPaginator to print the FlowDocument
            var doc = richTextBox1.Document;
            var size = new Size(dlg.PrintableAreaWidth, dlg.PrintableAreaHeight);

            // Clone and set page size
            FlowDocument copy = CopyFlowDocument(doc);
            copy.PageWidth  = size.Width;
            copy.PageHeight = size.Height;
            copy.ColumnWidth = size.Width;

            IDocumentPaginatorSource paginatorSource = copy;
            dlg.PrintDocument(paginatorSource.DocumentPaginator,
                              _currentFilePath is null ? "Neue Datei" : Path.GetFileName(_currentFilePath));
        }

        private void Close_Executed(object sender, ExecutedRoutedEventArgs e) => Close();

        // ──────────────────────────────────────────────────────────
        // LOAD / SAVE HELPERS
        // ──────────────────────────────────────────────────────────
        private void LoadFile(string path)
        {
            try
            {
                using FileStream fs = new(path, FileMode.Open, FileAccess.Read);
                TextRange range = new(richTextBox1.Document.ContentStart,
                                      richTextBox1.Document.ContentEnd);
                range.Load(fs, DataFormats.XamlPackage);
                _currentFilePath = path;
                _isModified = false;
                AddRecentFile(path);
                UpdateTitle();
                UpdateStatusBar();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Datei konnte nicht geladen werden:\n{ex.Message}",
                                "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void SaveFile(string path)
        {
            try
            {
                using FileStream fs = new(path, FileMode.Create, FileAccess.Write);
                TextRange range = new(richTextBox1.Document.ContentStart,
                                      richTextBox1.Document.ContentEnd);
                range.Save(fs, DataFormats.XamlPackage);
                _currentFilePath = path;
                _isModified = false;
                AddRecentFile(path);
                UpdateTitle();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Datei konnte nicht gespeichert werden:\n{ex.Message}",
                                "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private bool ConfirmDiscard()
        {
            if (!_isModified) return true;
            var result = MessageBox.Show(
                "Das Dokument wurde geändert. Möchten Sie die Änderungen speichern?",
                "Nicht gespeicherte Änderungen",
                MessageBoxButton.YesNoCancel,
                MessageBoxImage.Question);
            if (result == MessageBoxResult.Yes)
            {
                if (_currentFilePath is null)
                    SaveAs_Executed(this, null!);
                else
                    SaveFile(_currentFilePath);
                return !_isModified;
            }
            return result == MessageBoxResult.No;
        }

        private FlowDocument CopyFlowDocument(FlowDocument source)
        {
            // Serialize → deserialize into a fresh FlowDocument
            var range = new TextRange(source.ContentStart, source.ContentEnd);
            FlowDocument copy = new();
            using (var ms = new MemoryStream())
            {
                range.Save(ms, DataFormats.XamlPackage);
                ms.Seek(0, SeekOrigin.Begin);
                new TextRange(copy.ContentStart, copy.ContentEnd)
                    .Load(ms, DataFormats.XamlPackage);
            }
            return copy;
        }

        // ──────────────────────────────────────────────────────────
        // RECENT FILES
        // ──────────────────────────────────────────────────────────
        private void AddRecentFile(string path)
        {
            _recentFiles.Remove(path);
            _recentFiles.Insert(0, path);
            if (_recentFiles.Count > MaxRecentFiles)
                _recentFiles.RemoveAt(_recentFiles.Count - 1);
            RefreshRecentList();
            PersistRecentFiles();
        }

        private void RefreshRecentList()
        {
            RecentFilesMenu.Items.Clear();
            foreach (var path in _recentFiles)
            {
                var item = new System.Windows.Controls.MenuItem
                {
                    Header = Path.GetFileName(path),
                    Tag    = path
                };
                item.Click += (s, e) =>
                {
                    if (s is System.Windows.Controls.MenuItem mi &&
                        mi.Tag is string p)
                    {
                        if (!ConfirmDiscard()) return;
                        LoadFile(p);
                    }
                };
                RecentFilesMenu.Items.Add(item);
            }
        }

        private void LoadRecentFiles()
        {
            string raw = Microsoft.Win32.Registry.GetValue(
                @"HKEY_CURRENT_USER\Software\WPF_WordPad",
                RecentFilesKey, "") as string ?? "";
            foreach (var p in raw.Split('|', StringSplitOptions.RemoveEmptyEntries))
                if (File.Exists(p)) _recentFiles.Add(p);
            RefreshRecentList();
        }

        private void PersistRecentFiles()
        {
            try
            {
                var key = Microsoft.Win32.Registry.CurrentUser
                          .CreateSubKey(@"Software\WPF_WordPad");
                key?.SetValue(RecentFilesKey, string.Join("|", _recentFiles));
            }
            catch { /* Ignore registry errors */ }
        }

        private void RecentFilesList_MouseDoubleClick(object sender, MouseButtonEventArgs e)
        {
            // handled via RefreshRecentList click events
        }

        // ──────────────────────────────────────────────────────────
        // FORMAT: FONT FAMILY & SIZE
        // ──────────────────────────────────────────────────────────
        private void FontFamilyCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            if (FontFamilyCombo.SelectedItem is string fontName &&
                richTextBox1.Selection != null)
            {
                richTextBox1.Selection.ApplyPropertyValue(
                    TextElement.FontFamilyProperty,
                    new FontFamily(fontName));
                richTextBox1.Focus();
            }
        }

        private void FontSizeUpDown_ValueChanged(object sender, RoutedPropertyChangedEventArgs<object> e)
        {
            if (richTextBox1 is null || e.NewValue is null) return;
            if (e.NewValue is int size)
            {
                richTextBox1.Selection?.ApplyPropertyValue(
                    TextElement.FontSizeProperty, (double)size);
                richTextBox1.Focus();
            }
        }

        private void FontDialog_Click(object sender, RoutedEventArgs e)
        {
            // Use Win32 font dialog via System.Windows.Forms (add reference if not available)
            // Fallback: do nothing. For full font dialog support add UseWindowsForms=true
            // and a reference to System.Windows.Forms in the .csproj.
            MessageBox.Show("Schriftart-Dialog: Bitte Schriftart und Größe über die\n" +
                            "Dropdown-Menüs in der Ribbon-Leiste auswählen.",
                            "Info", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        // ──────────────────────────────────────────────────────────
        // FORMAT: BOLD / ITALIC / UNDERLINE (toggle state sync)
        // ──────────────────────────────────────────────────────────
        private void FormatButton_Click(object sender, RoutedEventArgs e)
        {
            richTextBox1.Focus();
        }

        private void BtnStrike_Click(object sender, RoutedEventArgs e)
        {
            var sel = richTextBox1.Selection;
            if (sel.IsEmpty) return;
            var current = sel.GetPropertyValue(Inline.TextDecorationsProperty)
                          as TextDecorationCollection;
            if (current != null && current.Contains(TextDecorations.Strikethrough[0]))
                sel.ApplyPropertyValue(Inline.TextDecorationsProperty, null);
            else
                sel.ApplyPropertyValue(Inline.TextDecorationsProperty,
                                       TextDecorations.Strikethrough);
            richTextBox1.Focus();
        }

        // ──────────────────────────────────────────────────────────
        // FORMAT: COLORS
        // ──────────────────────────────────────────────────────────
        private void ForeColorPicker_Changed(object sender, RoutedPropertyChangedEventArgs<System.Windows.Media.Color?> e)
        {
            if (e.NewValue.HasValue && richTextBox1?.Selection != null)
            {
                richTextBox1.Selection.ApplyPropertyValue(
                    TextElement.ForegroundProperty,
                    new SolidColorBrush(e.NewValue.Value));
            }
        }

        private void BackColorPicker_Changed(object sender, RoutedPropertyChangedEventArgs<System.Windows.Media.Color?> e)
        {
            if (e.NewValue.HasValue && richTextBox1?.Selection != null)
            {
                richTextBox1.Selection.ApplyPropertyValue(
                    TextElement.BackgroundProperty,
                    new SolidColorBrush(e.NewValue.Value));
            }
        }

        // ──────────────────────────────────────────────────────────
        // INSERT
        // ──────────────────────────────────────────────────────────
        private void InsertImage_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog dlg = new()
            {
                Filter = "Bilder (*.png;*.jpg;*.jpeg;*.bmp;*.gif)|*.png;*.jpg;*.jpeg;*.bmp;*.gif",
                Title  = "Bild einfügen"
            };
            if (dlg.ShowDialog() != true) return;

            try
            {
                BitmapImage bmp = new(new Uri(dlg.FileName));
                Image img = new()
                {
                    Source  = bmp,
                    MaxWidth  = 600,
                    MaxHeight = 400,
                    Stretch = Stretch.Uniform
                };

                var container = new InlineUIContainer(img, richTextBox1.CaretPosition);
                richTextBox1.CaretPosition = container.ElementEnd;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Bild konnte nicht eingefügt werden:\n{ex.Message}",
                                "Fehler", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void InsertDateTime_Click(object sender, RoutedEventArgs e)
        {
            string dt = DateTime.Now.ToString("dd.MM.yyyy HH:mm:ss");
            richTextBox1.CaretPosition.InsertTextInRun(dt);
            richTextBox1.Focus();
        }

        // ──────────────────────────────────────────────────────────
        // FIND & REPLACE
        // ──────────────────────────────────────────────────────────
        private void BtnFind_Click(object sender, RoutedEventArgs e)
        {
            FindPanel.Visibility = Visibility.Visible;
            ReplaceTextBox.Visibility = Visibility.Collapsed;
            FindTextBox.Focus();
        }

        private void BtnReplace_Click(object sender, RoutedEventArgs e)
        {
            FindPanel.Visibility = Visibility.Visible;
            ReplaceTextBox.Visibility = Visibility.Visible;
            FindTextBox.Focus();
        }

        private void CloseFind_Click(object sender, RoutedEventArgs e)
        {
            FindPanel.Visibility = Visibility.Collapsed;
            richTextBox1.Focus();
        }

        private void FindTextBox_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter) FindNext_Click(sender, e);
            if (e.Key == Key.Escape) CloseFind_Click(sender, e);
        }

        private void FindNext_Click(object sender, RoutedEventArgs e)
            => FindText(forward: true);

        private void FindPrev_Click(object sender, RoutedEventArgs e)
            => FindText(forward: false);

        private void FindText(bool forward)
        {
            string term = FindTextBox.Text;
            if (string.IsNullOrEmpty(term)) return;

            TextPointer start = forward
                ? richTextBox1.Selection.End
                : richTextBox1.Document.ContentStart;

            TextRange? found = FindInFlowDocument(richTextBox1.Document, term, start, forward);
            if (found != null)
            {
                richTextBox1.Selection.Select(found.Start, found.End);
                found.Start.GetCharacterRect(LogicalDirection.Forward);
                richTextBox1.Focus();
            }
            else
            {
                MessageBox.Show($"'{term}' wurde nicht gefunden.", "Suchen",
                                MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        private void Replace_Click(object sender, RoutedEventArgs e)
        {
            string term    = FindTextBox.Text;
            string replace = ReplaceTextBox.Text;
            if (string.IsNullOrEmpty(term)) return;

            if (!richTextBox1.Selection.IsEmpty &&
                richTextBox1.Selection.Text.Equals(term, StringComparison.OrdinalIgnoreCase))
            {
                richTextBox1.Selection.Text = replace;
            }
            FindText(forward: true);
        }

        private void ReplaceAll_Click(object sender, RoutedEventArgs e)
        {
            string term    = FindTextBox.Text;
            string replace = ReplaceTextBox.Text;
            if (string.IsNullOrEmpty(term)) return;

            int count = 0;
            TextPointer pos = richTextBox1.Document.ContentStart;
            while (true)
            {
                TextRange? found = FindInFlowDocument(richTextBox1.Document, term, pos, true);
                if (found == null) break;
                found.Text = replace;
                pos = found.End;
                count++;
            }
            MessageBox.Show($"{count} Ersetzung(en) vorgenommen.", "Alle ersetzen",
                            MessageBoxButton.OK, MessageBoxImage.Information);
        }

        /// <summary>Simple forward/backward text search within a FlowDocument.</summary>
        private static TextRange? FindInFlowDocument(
            FlowDocument doc, string term, TextPointer from, bool forward)
        {
            TextPointer current = forward ? from : doc.ContentEnd;
            while (current != null)
            {
                if (current.GetPointerContext(
                        forward ? LogicalDirection.Forward : LogicalDirection.Backward)
                    == TextPointerContext.Text)
                {
                    string run = current.GetTextInRun(
                        forward ? LogicalDirection.Forward : LogicalDirection.Backward);
                    int idx = forward
                        ? run.IndexOf(term, StringComparison.OrdinalIgnoreCase)
                        : run.LastIndexOf(term, StringComparison.OrdinalIgnoreCase);

                    if (idx >= 0)
                    {
                        TextPointer? start = current.GetPositionAtOffset(
                            forward ? idx : idx - run.Length + term.Length);
                        TextPointer? end   = start?.GetPositionAtOffset(term.Length);
                        if (start != null && end != null)
                            return new TextRange(start, end);
                    }
                }
                current = forward
                    ? current.GetNextContextPosition(LogicalDirection.Forward)
                    : current.GetNextContextPosition(LogicalDirection.Backward);
            }
            return null;
        }

        // ──────────────────────────────────────────────────────────
        // ZOOM
        // ──────────────────────────────────────────────────────────
        private void ZoomIn_Click(object sender, RoutedEventArgs e)
        {
            _zoomLevel = Math.Min(_zoomLevel + ZoomStep, ZoomMax);
            ApplyZoom();
        }

        private void ZoomOut_Click(object sender, RoutedEventArgs e)
        {
            _zoomLevel = Math.Max(_zoomLevel - ZoomStep, ZoomMin);
            ApplyZoom();
        }

        private void ZoomReset_Click(object sender, RoutedEventArgs e)
        {
            _zoomLevel = 1.0;
            ApplyZoom();
        }

        private void ApplyZoom()
        {
            richTextBox1.LayoutTransform = new ScaleTransform(_zoomLevel, _zoomLevel);
            StatusZoom.Text = $"Zoom: {(int)(_zoomLevel * 100)} %";
        }

        // ──────────────────────────────────────────────────────────
        // VIEW OPTIONS
        // ──────────────────────────────────────────────────────────
        private void ChkStatusBar_Changed(object sender, RoutedEventArgs e)
        {
            statusBar.Visibility = ChkStatusBar.IsChecked == true
                ? Visibility.Visible : Visibility.Collapsed;
        }

        private void ChkWordWrap_Changed(object sender, RoutedEventArgs e)
        {
            richTextBox1.Document.PageWidth = ChkWordWrap.IsChecked == true
                ? double.NaN : 2000;
        }

        private void ChkSpellCheck_Changed(object sender, RoutedEventArgs e)
        {
            SpellCheck.SetIsEnabled(richTextBox1, ChkSpellCheck.IsChecked == true);
        }

        // ──────────────────────────────────────────────────────────
        // RICHTEXTBOX EVENTS
        // ──────────────────────────────────────────────────────────
        private void RichTextBox_TextChanged(object sender, TextChangedEventArgs e)
        {
            if (!_isModified)
            {
                _isModified = true;
                UpdateTitle();
            }
            UpdateStatusBar();
        }

        private void RichTextBox_SelectionChanged(object sender, RoutedEventArgs e)
        {
            if (_suppressSelectionChanged) return;
            _suppressSelectionChanged = true;

            try
            {
                // ── Sync Bold/Italic/Underline toggle buttons ──
                object bold = richTextBox1.Selection
                                          .GetPropertyValue(TextElement.FontWeightProperty);
                BtnBold.IsChecked = bold is FontWeight fw && fw == FontWeights.Bold;

                object italic = richTextBox1.Selection
                                            .GetPropertyValue(TextElement.FontStyleProperty);
                BtnItalic.IsChecked = italic is FontStyle fs && fs == FontStyles.Italic;

                object deco = richTextBox1.Selection
                                          .GetPropertyValue(Inline.TextDecorationsProperty);
                BtnUnderline.IsChecked = deco is TextDecorationCollection tdc
                    && tdc.Count > 0
                    && tdc.Any(d => d.Location == TextDecorationLocation.Underline);

                // ── Sync Font Family ──
                object ff = richTextBox1.Selection
                                        .GetPropertyValue(TextElement.FontFamilyProperty);
                if (ff is FontFamily fontFamily)
                    FontFamilyCombo.SelectedItem = fontFamily.Source;

                // ── Sync Font Size ──
                object sz = richTextBox1.Selection
                                        .GetPropertyValue(TextElement.FontSizeProperty);
                if (sz is double size)
                    FontSizeUpDown.Value = (int)Math.Round(size);
            }
            finally
            {
                _suppressSelectionChanged = false;
            }
        }

        private void RichTextBox_PreviewKeyDown(object sender, KeyEventArgs e)
        {
            // Ctrl+S quick save
            if (e.Key == Key.S && Keyboard.Modifiers == ModifierKeys.Control)
            {
                if (_currentFilePath is null)
                    SaveAs_Executed(sender, null!);
                else
                    SaveFile(_currentFilePath);
                e.Handled = true;
            }
            // Ctrl+F find
            else if (e.Key == Key.F && Keyboard.Modifiers == ModifierKeys.Control)
            {
                BtnFind_Click(sender, e);
                e.Handled = true;
            }
            // Ctrl+H replace
            else if (e.Key == Key.H && Keyboard.Modifiers == ModifierKeys.Control)
            {
                BtnReplace_Click(sender, e);
                e.Handled = true;
            }
            // Ctrl+= Superscript  (same as Word)
            else if (e.Key == Key.OemPlus &&
                     Keyboard.Modifiers == (ModifierKeys.Control | ModifierKeys.Shift))
            {
                EditingCommands.ToggleSuperscript.Execute(null, richTextBox1);
                e.Handled = true;
            }
        }

        // ──────────────────────────────────────────────────────────
        // WINDOW CLOSING
        // ──────────────────────────────────────────────────────────
        private void Window_Closing(object sender,
            System.ComponentModel.CancelEventArgs e)
        {
            if (!ConfirmDiscard())
                e.Cancel = true;
        }
    }
}
