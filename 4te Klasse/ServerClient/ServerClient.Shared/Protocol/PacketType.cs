namespace ServerClient.Shared.Protocol
{
    /// <summary>
    /// Die verschiedenen Pakettypen die über das Netzwerk gesendet werden.
    /// </summary>
    public enum PacketType
    {
        /// <summary>Client → Server: Nachricht senden</summary>
        SendMessage,

        /// <summary>Server → Client(s): Nachricht weiterleiten</summary>
        MessageReceived,

        /// <summary>Client → Server: Verbindung mit Benutzername herstellen</summary>
        Connect,

        /// <summary>Server → Client: Verbindung bestätigt</summary>
        ConnectResponse,

        /// <summary>Client → Server: Verbindung trennen</summary>
        Disconnect,

        /// <summary>Server → alle: Ein Client hat sich verbunden</summary>
        ClientJoined,

        /// <summary>Server → alle: Ein Client hat sich getrennt</summary>
        ClientLeft,

        /// <summary>Server → Client: Fehlermeldung</summary>
        Error
    }
}
