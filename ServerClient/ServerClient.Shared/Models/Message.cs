using System;

namespace ServerClient.Shared.Models
{
    /// <summary>
    /// Das Datenmodell für eine Nachricht, die zwischen Client und Server verschickt wird.
    /// </summary>
    public class Message
    {
        /// <summary>Der Benutzername des Absenders.</summary>
        public string SenderName { get; set; } = "";

        /// <summary>Der Inhalt der Nachricht.</summary>
        public string Content { get; set; } = "";

        /// <summary>Zeitstempel wann die Nachricht gesendet wurde.</summary>
        public DateTime Timestamp { get; set; } = DateTime.Now;

        public override string ToString()
            => $"[{Timestamp:HH:mm:ss}] {SenderName}: {Content}";
    }
}
