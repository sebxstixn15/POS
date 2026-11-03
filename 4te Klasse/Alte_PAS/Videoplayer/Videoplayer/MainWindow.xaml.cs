using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Threading;

namespace Videoplayer
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        DispatcherTimer timer = new DispatcherTimer();

        public MainWindow()
        {
            InitializeComponent();
            timer.Interval = TimeSpan.FromSeconds(1);
            timer.Tick += (s, e) => {
                if (MainPlayer.NaturalDuration.HasTimeSpan && !isDragging)
                {
                    TimelineSlider.Maximum = MainPlayer.NaturalDuration.TimeSpan.TotalSeconds;
                    TimelineSlider.Value = MainPlayer.Position.TotalSeconds;
                }
            };
            timer.Start();
        }

        private bool isDragging = false;
        private void Timeline_DragStarted(object s, DragStartedEventArgs e) => isDragging = true;
        private void Timeline_DragCompleted(object s, DragCompletedEventArgs e)
        {
            isDragging = false;
            MainPlayer.Position = TimeSpan.FromSeconds(TimelineSlider.Value);
        }

        private void BtnAddFile_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new Microsoft.Win32.OpenFileDialog { Filter = "Video Dateien|*.mp4;*.avi;*.mkv" };
            if (dialog.ShowDialog() == true)
            {
                lbPlaylist.Items.Add(new VideoItem { Title = dialog.SafeFileName, FilePath = new Uri(dialog.FileName) });
            }
        }

        private void PlaySelectedVideo(VideoItem item)
        {
            if (item == null) return;
            MainPlayer.Source = item.FilePath;
            MainPlayer.Play();

            if (!lbHistory.Items.Contains(item))
                lbHistory.Items.Insert(0, item);
        }

        private void lb_DoubleClick(object sender, MouseButtonEventArgs e)
        {
            var list = sender as ListBox;
            if (list?.SelectedItem is VideoItem video) PlaySelectedVideo(video);
        }

        private void MainPlayer_MediaEnded(object sender, RoutedEventArgs e)
        {
            int nextIndex = lbPlaylist.SelectedIndex + 1;
            if (nextIndex < lbPlaylist.Items.Count)
            {
                lbPlaylist.SelectedIndex = nextIndex;
                PlaySelectedVideo((VideoItem)lbPlaylist.SelectedItem);
            }
        }


        private void BtnAddFolder_Click(object sender, RoutedEventArgs e)
        {
            var dialog = new System.Windows.Forms.FolderBrowserDialog();
            if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
            {
                string[] files = Directory.GetFiles(dialog.SelectedPath, "*.*", SearchOption.TopDirectoryOnly);

                foreach (string file in files)
                {
                    string ext = System.IO.Path.GetExtension(file).ToLower();
                    if (ext == ".mp4" || ext == ".avi" || ext == ".wmv" || ext == ".mkv")
                    {
                        lbPlaylist.Items.Add(new VideoItem
                        {
                            Title = System.IO.Path.GetFileName(file),
                            FilePath = new Uri(file)
                        });
                    }
                }
            }
        }

        private void BtnPlay_Click(object sender, RoutedEventArgs e) => MainPlayer.Play();
        private void BtnPause_Click(object sender, RoutedEventArgs e) => MainPlayer.Pause();
    }
}