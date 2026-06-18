using Newtonsoft.Json;

namespace ServerClient.Shared.Protocol
{
    /// <summary>
    /// Ein Paket das über TCP gesendet wird.
    /// Jede Zeile im Netzwerk-Stream ist ein serialisiertes Packet (JSON).
    /// </summary>
    public class Packet
    {
        public PacketType Type { get; set; }

        /// <summary>Der eigentliche Inhalt – als JSON-String verpackt.</summary>
        public string? Payload { get; set; }

        /// <summary>Erstellt ein Paket mit dem angegebenen Typ und Payload.</summary>
        public static Packet Create<T>(PacketType type, T payload) => new()
        {
            Type = type,
            Payload = JsonConvert.SerializeObject(payload)
        };

        /// <summary>Erstellt ein Paket ohne Payload.</summary>
        public static Packet Create(PacketType type) => new()
        {
            Type = type
        };

        /// <summary>Serialisiert das Paket zu JSON.</summary>
        public string ToJson() => JsonConvert.SerializeObject(this);

        /// <summary>Deserialisiert ein Paket aus JSON.</summary>
        public static Packet? FromJson(string json) =>
            JsonConvert.DeserializeObject<Packet>(json);

        /// <summary>Liest den Payload aus und wandelt ihn in den gewünschten Typ um.</summary>
        public T? GetPayload<T>() =>
            Payload == null ? default : JsonConvert.DeserializeObject<T>(Payload);
    }
}
