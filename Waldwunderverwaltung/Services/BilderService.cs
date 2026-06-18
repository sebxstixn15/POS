using System.IO;

namespace Waldwunderverwaltung.Services
{
    /// <summary>
    /// Manages copying image files into the application's Images folder,
    /// automatically renaming files to avoid name collisions.
    /// </summary>
    public static class BilderService
    {
        public static readonly string ImagesFolder =
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Images");

        /// <summary>
        /// Copies a source image file into the Images folder.
        /// If a file with the same name already exists, appends _1, _2, ... until unique.
        /// </summary>
        /// <param name="sourcePath">Full path to the source image file.</param>
        /// <returns>The (possibly renamed) filename stored in the Images folder.</returns>
        public static string CopyToImagesFolder(string sourcePath)
        {
            Directory.CreateDirectory(ImagesFolder);

            string filename = Path.GetFileName(sourcePath);
            string destPath = Path.Combine(ImagesFolder, filename);

            if (File.Exists(destPath))
            {
                string nameWithoutExt = Path.GetFileNameWithoutExtension(filename);
                string ext = Path.GetExtension(filename);
                int counter = 1;
                do
                {
                    filename = $"{nameWithoutExt}_{counter}{ext}";
                    destPath = Path.Combine(ImagesFolder, filename);
                    counter++;
                } while (File.Exists(destPath));
            }

            File.Copy(sourcePath, destPath);
            return filename;
        }

        /// <summary>
        /// Returns the full path for an image stored in the Images folder.
        /// </summary>
        public static string GetImagePath(string filename) =>
            Path.Combine(ImagesFolder, filename);
    }
}
