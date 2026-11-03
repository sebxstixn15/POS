using System;
using System.Collections.Generic;
using System.Text;

namespace Videoplayer
{
    public class VideoItem
    {
        public string Title { get; set; }
        public Uri FilePath { get; set; }

        // Überschreiben von ToString für die Anzeige, falls kein Template da ist
        public override string ToString() => Title;
    }
}
