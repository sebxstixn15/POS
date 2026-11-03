#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  create-server-client.sh
#  Erstellt automatisch ein WPF Server-Client Projekt aus einer .cs Datei.
#
#  Verwendung:
#    ./create-server-client.sh <DeinModel.cs> [ProjektName]
#
#  Beispiel:
#    ./create-server-client.sh Message.cs MeinChat
#    ./create-server-client.sh ./Models/Player.cs GameNetwork
#
#  Was passiert:
#    1. Liest die .cs Datei ein (beliebiger Inhalt)
#    2. Extrahiert den Klassennamen automatisch
#    3. Erstellt ein komplettes WPF-Projekt mit:
#       - Shared Library (mit deiner .cs Datei + Netzwerk-Protokoll)
#       - WPF App (Server/Client Auswahl im UI)
#       - TCP Server der mehrere Clients akzeptiert
#       - TCP Client der sich verbinden und Objekte senden kann
# ═══════════════════════════════════════════════════════════════════

set -e

# ── Farben ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ── Argumente prüfen ──────────────────────────────────────────────
if [ $# -lt 1 ]; then
    echo -e "${RED}Fehler: Keine .cs Datei angegeben!${NC}"
    echo ""
    echo "Verwendung: $0 <DeinModel.cs> [ProjektName]"
    echo ""
    echo "Beispiele:"
    echo "  $0 Message.cs"
    echo "  $0 Message.cs MeinProjekt"
    echo "  $0 ./Models/Player.cs GameNetwork"
    exit 1
fi

CS_FILE="$1"
if [ ! -f "$CS_FILE" ]; then
    echo -e "${RED}Fehler: Datei '$CS_FILE' nicht gefunden!${NC}"
    exit 1
fi

if [[ ! "$CS_FILE" == *.cs ]]; then
    echo -e "${RED}Fehler: '$CS_FILE' ist keine .cs Datei!${NC}"
    exit 1
fi

# ── Klassennamen extrahieren ──────────────────────────────────────
# Sucht nach "public class XYZ" oder "public record XYZ" etc.
CLASS_NAME=$(grep -oE '(public\s+)?(partial\s+)?(class|record|struct)\s+[A-Za-z_][A-Za-z0-9_]*' "$CS_FILE" | head -1 | awk '{print $NF}')

if [ -z "$CLASS_NAME" ]; then
    echo -e "${RED}Fehler: Kein Klassenname in '$CS_FILE' gefunden!${NC}"
    echo "Die Datei muss mindestens eine 'public class', 'record' oder 'struct' enthalten."
    exit 1
fi

# ── Projektname bestimmen ─────────────────────────────────────────
PROJECT_NAME="${2:-ServerClient}"
CS_FILENAME=$(basename "$CS_FILE")

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Server-Client Projekt Generator${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  CS-Datei:      ${YELLOW}$CS_FILE${NC}"
echo -e "  Klassenname:   ${YELLOW}$CLASS_NAME${NC}"
echo -e "  Projektname:   ${YELLOW}$PROJECT_NAME${NC}"
echo ""

# ── Verzeichnisse erstellen ───────────────────────────────────────
BASE_DIR="$PROJECT_NAME"

if [ -d "$BASE_DIR" ]; then
    echo -e "${RED}Fehler: Ordner '$BASE_DIR' existiert bereits!${NC}"
    exit 1
fi

echo -e "${GREEN}[1/7] Erstelle Verzeichnisstruktur...${NC}"
mkdir -p "$BASE_DIR/$PROJECT_NAME.Shared/Models"
mkdir -p "$BASE_DIR/$PROJECT_NAME.Shared/Protocol"
mkdir -p "$BASE_DIR/$PROJECT_NAME.App/Network"

# ── .cs Datei kopieren (Namespace anpassen) ───────────────────────
echo -e "${GREEN}[2/7] Kopiere und passe $CS_FILENAME an...${NC}"

# Prüfen ob die Datei bereits einen Namespace hat
if grep -q 'namespace' "$CS_FILE"; then
    # Namespace ersetzen
    sed -E "s/namespace\s+[A-Za-z0-9_.]+/namespace $PROJECT_NAME.Shared.Models/" "$CS_FILE" > "$BASE_DIR/$PROJECT_NAME.Shared/Models/$CS_FILENAME"
else
    # Namespace hinzufügen
    {
        echo "namespace $PROJECT_NAME.Shared.Models"
        echo "{"
        cat "$CS_FILE"
        echo "}"
    } > "$BASE_DIR/$PROJECT_NAME.Shared/Models/$CS_FILENAME"
fi

SHARED_NS="$PROJECT_NAME.Shared"
APP_NS="$PROJECT_NAME.App"

# ── Shared Projekt ────────────────────────────────────────────────
echo -e "${GREEN}[3/7] Erstelle Shared Projekt...${NC}"

cat > "$BASE_DIR/$PROJECT_NAME.Shared/$PROJECT_NAME.Shared.csproj" << 'CSPROJ'
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>

</Project>
CSPROJ

# PacketType.cs
cat > "$BASE_DIR/$PROJECT_NAME.Shared/Protocol/PacketType.cs" << EOF
namespace $SHARED_NS.Protocol
{
    /// <summary>
    /// Die verschiedenen Pakettypen die über das Netzwerk gesendet werden.
    /// </summary>
    public enum PacketType
    {
        /// <summary>Client → Server: Objekt senden</summary>
        SendData,

        /// <summary>Server → Client(s): Objekt weiterleiten</summary>
        DataReceived,

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
EOF

# Packet.cs
cat > "$BASE_DIR/$PROJECT_NAME.Shared/Protocol/Packet.cs" << EOF
using Newtonsoft.Json;

namespace $SHARED_NS.Protocol
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
EOF

# ── App Projekt ───────────────────────────────────────────────────
echo -e "${GREEN}[4/7] Erstelle App Projekt...${NC}"

cat > "$BASE_DIR/$PROJECT_NAME.App/$PROJECT_NAME.App.csproj" << EOF
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\\$PROJECT_NAME.Shared\\$PROJECT_NAME.Shared.csproj" />
  </ItemGroup>

</Project>
EOF

# ── Network: TcpServer.cs ─────────────────────────────────────────
echo -e "${GREEN}[5/7] Erstelle Netzwerk-Layer...${NC}"

cat > "$BASE_DIR/$PROJECT_NAME.App/Network/TcpServer.cs" << EOF
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using $SHARED_NS.Models;
using $SHARED_NS.Protocol;

namespace $APP_NS.Network
{
    /// <summary>
    /// Der TCP-Server. Wartet auf neue Verbindungen und verwaltet alle verbundenen Clients.
    /// </summary>
    public class TcpServer
    {
        private TcpListener? _listener;
        private bool _running;

        private readonly List<ConnectedClient> _clients = new();
        private readonly object _lock = new();

        /// <summary>Wird aufgerufen wenn etwas geloggt werden soll.</summary>
        public event Action<string>? OnLog;

        /// <summary>Wird aufgerufen wenn ein $CLASS_NAME-Objekt empfangen wird.</summary>
        public event Action<$CLASS_NAME, string>? OnDataReceived;

        // ── Start / Stop ──────────────────────────────────────

        public void Start(int port)
        {
            _listener = new TcpListener(IPAddress.Any, port);
            _listener.Start();
            _running = true;
            Log(\$"Server gestartet auf Port {port}");
            Task.Run(AcceptConnections);
        }

        public void Stop()
        {
            _running = false;

            lock (_lock)
            {
                foreach (var c in _clients)
                    c.Close();
                _clients.Clear();
            }

            _listener?.Stop();
            Log("Server gestoppt.");
        }

        /// <summary>Wartet in einer Schleife auf neue Client-Verbindungen.</summary>
        private async Task AcceptConnections()
        {
            while (_running)
            {
                try
                {
                    var tcpClient = await _listener!.AcceptTcpClientAsync();
                    Log(\$"Neue Verbindung von {tcpClient.Client.RemoteEndPoint}");

                    var client = new ConnectedClient(tcpClient);
                    client.OnPacketReceived += packet => HandlePacket(client, packet);
                    client.OnDisconnected += () => HandleDisconnect(client);
                    client.StartReceiving();
                }
                catch
                {
                    if (!_running) break;
                }
            }
        }

        // ── Paket-Verarbeitung ────────────────────────────────

        private void HandlePacket(ConnectedClient client, Packet packet)
        {
            switch (packet.Type)
            {
                case PacketType.Connect:
                    HandleConnect(client, packet);
                    break;

                case PacketType.SendData:
                    HandleData(client, packet);
                    break;

                case PacketType.Disconnect:
                    HandleDisconnect(client);
                    break;
            }
        }

        private void HandleConnect(ConnectedClient client, Packet packet)
        {
            var name = packet.GetPayload<string>();
            if (string.IsNullOrWhiteSpace(name))
            {
                client.Send(Packet.Create(PacketType.Error, "Benutzername darf nicht leer sein."));
                return;
            }

            lock (_lock)
            {
                if (_clients.Any(c => c.Name == name))
                {
                    client.Send(Packet.Create(PacketType.Error, \$"Name '{name}' ist bereits vergeben."));
                    return;
                }
            }

            client.Name = name;

            lock (_lock)
                _clients.Add(client);

            client.Send(Packet.Create(PacketType.ConnectResponse, "Verbindung erfolgreich."));
            Log(\$"Client verbunden: {name} ({client.RemoteEndPoint})");

            BroadcastExcept(Packet.Create(PacketType.ClientJoined, name), client);
        }

        private void HandleData(ConnectedClient client, Packet packet)
        {
            var data = packet.GetPayload<$CLASS_NAME>();
            if (data == null || !client.IsConnected) return;

            Log(\$"Daten empfangen von {client.Name}: {data}");

            // Event für die Server-UI
            OnDataReceived?.Invoke(data, client.Name!);

            // An alle Clients weiterleiten (inkl. Absender)
            Broadcast(Packet.Create(PacketType.DataReceived, data));
        }

        private void HandleDisconnect(ConnectedClient client)
        {
            if (client.Name == null) return;

            var name = client.Name;
            lock (_lock)
                _clients.Remove(client);

            client.Close();
            Log(\$"Client getrennt: {name}");

            Broadcast(Packet.Create(PacketType.ClientLeft, name));
        }

        // ── Broadcast ─────────────────────────────────────────

        private void Broadcast(Packet packet)
        {
            lock (_lock)
                foreach (var c in _clients.Where(c => c.IsConnected))
                    c.Send(packet);
        }

        private void BroadcastExcept(Packet packet, ConnectedClient except)
        {
            lock (_lock)
                foreach (var c in _clients.Where(c => c.IsConnected && c != except))
                    c.Send(packet);
        }

        // ── Logging ───────────────────────────────────────────

        public void Log(string message)
        {
            var line = \$"[{DateTime.Now:HH:mm:ss}] {message}";
            OnLog?.Invoke(line);
        }

        public int ClientCount
        {
            get { lock (_lock) return _clients.Count; }
        }
    }

    /// <summary>
    /// Repräsentiert einen verbundenen Client auf der Server-Seite.
    /// </summary>
    public class ConnectedClient
    {
        private readonly TcpClient _tcpClient;
        private readonly StreamReader _reader;
        private readonly StreamWriter _writer;
        private readonly object _sendLock = new();
        private bool _running;

        public string? Name { get; set; }
        public bool IsConnected => Name != null;
        public string? RemoteEndPoint => _tcpClient.Client.RemoteEndPoint?.ToString();

        public event Action<Packet>? OnPacketReceived;
        public event Action? OnDisconnected;

        public ConnectedClient(TcpClient client)
        {
            _tcpClient = client;
            _tcpClient.NoDelay = true;

            var stream = client.GetStream();
            _reader = new StreamReader(stream, Encoding.UTF8);
            _writer = new StreamWriter(stream, Encoding.UTF8) { AutoFlush = true };
        }

        public void StartReceiving()
        {
            _running = true;
            Task.Run(ReceiveLoop);
        }

        private async Task ReceiveLoop()
        {
            try
            {
                string? line;
                while (_running && (line = await _reader.ReadLineAsync()) != null)
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var packet = Packet.FromJson(line);
                    if (packet != null)
                        OnPacketReceived?.Invoke(packet);
                }
            }
            catch (IOException) { }
            catch (Exception) { }
            finally
            {
                _running = false;
                OnDisconnected?.Invoke();
            }
        }

        public void Send(Packet packet)
        {
            try
            {
                lock (_sendLock)
                    _writer.WriteLine(packet.ToJson());
            }
            catch { }
        }

        public void Close()
        {
            _running = false;
            try { _tcpClient.Close(); } catch { }
        }
    }
}
EOF

# ── Network: ServerConnection.cs ──────────────────────────────────
cat > "$BASE_DIR/$PROJECT_NAME.App/Network/ServerConnection.cs" << EOF
using System;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using $SHARED_NS.Protocol;

namespace $APP_NS.Network
{
    /// <summary>
    /// Die Verbindung vom Client zum Server.
    /// </summary>
    public class ServerConnection
    {
        private TcpClient? _client;
        private StreamReader? _reader;
        private StreamWriter? _writer;
        private readonly object _writeLock = new();
        private bool _running;
        private bool _intentionalDisconnect;

        public event Action<Packet>? PacketReceived;
        public event Action? Disconnected;
        public bool IsConnected => _client?.Connected ?? false;

        public async Task ConnectAsync(string host, int port)
        {
            _intentionalDisconnect = false;
            _client = new TcpClient();
            _client.NoDelay = true;
            await _client.ConnectAsync(host, port);

            var stream = _client.GetStream();
            _reader = new StreamReader(stream, Encoding.UTF8);
            _writer = new StreamWriter(stream, Encoding.UTF8) { AutoFlush = true };
            _running = true;
            _ = Task.Run(ReceiveLoop);
        }

        private async Task ReceiveLoop()
        {
            try
            {
                string? line;
                while (_running && (line = await _reader!.ReadLineAsync()) != null)
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var packet = Packet.FromJson(line);
                    if (packet != null)
                        PacketReceived?.Invoke(packet);
                }
            }
            catch (IOException) { }
            catch (Exception) { }
            finally
            {
                _running = false;
                if (!_intentionalDisconnect)
                    Disconnected?.Invoke();
            }
        }

        public void Send(Packet packet)
        {
            try
            {
                lock (_writeLock)
                    _writer?.WriteLine(packet.ToJson());
            }
            catch { }
        }

        public void Disconnect()
        {
            _intentionalDisconnect = true;
            _running = false;
            try { _client?.Close(); } catch { }
        }
    }
}
EOF

# ── WPF: App.xaml ─────────────────────────────────────────────────
echo -e "${GREEN}[6/7] Erstelle WPF Oberfläche...${NC}"

cat > "$BASE_DIR/$PROJECT_NAME.App/App.xaml" << EOF
<Application x:Class="$APP_NS.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources>
    </Application.Resources>
</Application>
EOF

cat > "$BASE_DIR/$PROJECT_NAME.App/App.xaml.cs" << EOF
using System.Windows;

namespace $APP_NS
{
    public partial class App : Application
    {
    }
}
EOF

# ── WPF: MainWindow.xaml ──────────────────────────────────────────
cat > "$BASE_DIR/$PROJECT_NAME.App/MainWindow.xaml" << EOF
<Window x:Class="$APP_NS.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$PROJECT_NAME – Server/Client" Height="650" Width="850"
        WindowStartupLocation="CenterScreen"
        Closing="Window_Closing">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="4,3"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="VerticalAlignment" Value="Center"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
    </Window.Resources>

    <Grid>
        <!-- ════════════════════════════════════════════════════
             PANEL 1: Startbildschirm – Auswahl Server oder Client
             ════════════════════════════════════════════════════ -->
        <Grid x:Name="PnlStart">
            <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                <TextBlock Text="🖧 $PROJECT_NAME"
                           FontSize="24" FontWeight="Bold"
                           HorizontalAlignment="Center" Margin="0,0,0,20"/>

                <TextBlock Text="Wähle den Modus:"
                           FontSize="14" HorizontalAlignment="Center" Margin="0,0,0,10"/>

                <ComboBox x:Name="CmbMode" Width="250" FontSize="14"
                          Padding="8,6" Margin="0,0,0,15"
                          SelectedIndex="0">
                    <ComboBoxItem Content="🖥️ Als Server starten"/>
                    <ComboBoxItem Content="💻 Als Client starten"/>
                </ComboBox>

                <Button x:Name="BtnStartMode" Content="▶ Starten"
                        FontSize="16" FontWeight="Bold"
                        Padding="20,10" HorizontalAlignment="Center"
                        Click="BtnStartMode_Click"/>
            </StackPanel>
        </Grid>

        <!-- ════════════════════════════════════════════════════
             PANEL 2: Server-Ansicht
             ════════════════════════════════════════════════════ -->
        <DockPanel x:Name="PnlServer" Margin="8" Visibility="Collapsed">
            <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0,0,0,8">
                <Label Content="🖥️ SERVER" FontWeight="Bold" FontSize="16" Foreground="DarkBlue"/>
                <Separator Margin="8,0"/>
                <Label Content="Port:"/>
                <TextBox x:Name="TxtServerPort" Text="5000" Width="70"/>
                <Button x:Name="BtnServerStart" Content="▶ Starten" Click="BtnServerStart_Click"/>
                <Button x:Name="BtnServerStop" Content="⏹ Stoppen" Click="BtnServerStop_Click" IsEnabled="False"/>
                <Separator Margin="8,0"/>
                <Label x:Name="LblServerStatus" Content="Gestoppt" Foreground="Red" FontWeight="Bold"/>
            </StackPanel>

            <StatusBar DockPanel.Dock="Bottom">
                <StatusBarItem>
                    <TextBlock x:Name="TxtServerStats" Text="Verbundene Clients: 0"/>
                </StatusBarItem>
            </StatusBar>

            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <GroupBox Grid.Row="0" Header="📋 Server-Protokoll">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <ListBox x:Name="LstServerLog" Grid.Row="0"
                                 FontFamily="Consolas" FontSize="12"
                                 ScrollViewer.VerticalScrollBarVisibility="Auto"/>
                        <Button Grid.Row="1" Content="Log leeren"
                                HorizontalAlignment="Right" Margin="0,4,0,0"
                                Click="BtnClearServerLog_Click"/>
                    </Grid>
                </GroupBox>

                <GridSplitter Grid.Row="1" Height="5" HorizontalAlignment="Stretch"
                              Background="LightGray" ResizeDirection="Rows"/>

                <GroupBox Grid.Row="2" Header="📨 Empfangene $CLASS_NAME-Objekte">
                    <ListBox x:Name="LstServerData"
                             FontFamily="Consolas" FontSize="12"
                             ScrollViewer.VerticalScrollBarVisibility="Auto"/>
                </GroupBox>
            </Grid>
        </DockPanel>

        <!-- ════════════════════════════════════════════════════
             PANEL 3: Client-Ansicht
             ════════════════════════════════════════════════════ -->
        <DockPanel x:Name="PnlClient" Margin="8" Visibility="Collapsed">
            <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0,0,0,8">
                <Label Content="💻 CLIENT" FontWeight="Bold" FontSize="16" Foreground="DarkGreen"/>
                <Separator Margin="8,0"/>
                <Label Content="Host:"/>
                <TextBox x:Name="TxtClientHost" Text="127.0.0.1" Width="110"/>
                <Label Content="Port:"/>
                <TextBox x:Name="TxtClientPort" Text="5000" Width="60"/>
                <Label Content="Name:"/>
                <TextBox x:Name="TxtClientName" Text="" Width="100"/>
                <Button x:Name="BtnClientConnect" Content="🔗 Verbinden" Click="BtnClientConnect_Click"/>
                <Button x:Name="BtnClientDisconnect" Content="✂ Trennen" Click="BtnClientDisconnect_Click" IsEnabled="False"/>
                <Separator Margin="8,0"/>
                <Label x:Name="LblClientStatus" Content="Getrennt" Foreground="Red" FontWeight="Bold"/>
            </StackPanel>

            <Grid DockPanel.Dock="Bottom" Margin="0,8,0,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name="TxtClientInput" Grid.Column="0"
                         FontSize="13" Padding="6,4"
                         KeyDown="TxtClientInput_KeyDown"
                         IsEnabled="False"/>
                <Button x:Name="BtnClientSend" Grid.Column="1"
                        Content="📤 Senden" FontWeight="Bold"
                        Click="BtnClientSend_Click" IsEnabled="False"/>
            </Grid>

            <GroupBox Header="📨 Empfangene Daten">
                <ListBox x:Name="LstClientData"
                         FontFamily="Consolas" FontSize="12"
                         ScrollViewer.VerticalScrollBarVisibility="Auto"/>
            </GroupBox>
        </DockPanel>
    </Grid>
</Window>
EOF

# ── WPF: MainWindow.xaml.cs ───────────────────────────────────────
cat > "$BASE_DIR/$PROJECT_NAME.App/MainWindow.xaml.cs" << EOF
using System;
using System.Windows;
using System.Windows.Input;
using Newtonsoft.Json;
using ${APP_NS}.Network;
using ${SHARED_NS}.Models;
using ${SHARED_NS}.Protocol;

namespace $APP_NS
{
    public partial class MainWindow : Window
    {
        // ── Server-Felder ─────────────────────────────────────
        private TcpServer? _server;

        // ── Client-Felder ─────────────────────────────────────
        private ServerConnection? _connection;
        private string? _clientName;

        public MainWindow()
        {
            InitializeComponent();
        }

        // ══════════════════════════════════════════════════════
        //  STARTBILDSCHIRM
        // ══════════════════════════════════════════════════════

        private void BtnStartMode_Click(object sender, RoutedEventArgs e)
        {
            PnlStart.Visibility = Visibility.Collapsed;

            if (CmbMode.SelectedIndex == 0)
            {
                PnlServer.Visibility = Visibility.Visible;
                Title = "$PROJECT_NAME – SERVER";
            }
            else
            {
                PnlClient.Visibility = Visibility.Visible;
                Title = "$PROJECT_NAME – CLIENT";
            }
        }

        // ══════════════════════════════════════════════════════
        //  SERVER
        // ══════════════════════════════════════════════════════

        private void BtnServerStart_Click(object sender, RoutedEventArgs e)
        {
            if (!int.TryParse(TxtServerPort.Text, out int port) || port < 1 || port > 65535)
            {
                MessageBox.Show("Ungültiger Port (1–65535).", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                _server = new TcpServer();
                _server.OnLog += AppendServerLog;
                _server.OnDataReceived += (data, senderName) =>
                {
                    Dispatcher.Invoke(() =>
                    {
                        var json = JsonConvert.SerializeObject(data, Formatting.None);
                        LstServerData.Items.Add(\$"[{DateTime.Now:HH:mm:ss}] von {senderName}: {json}");
                        LstServerData.ScrollIntoView(LstServerData.Items[^1]);
                    });
                };
                _server.Start(port);

                LblServerStatus.Content = \$"Läuft auf Port {port}";
                LblServerStatus.Foreground = System.Windows.Media.Brushes.Green;
                BtnServerStart.IsEnabled = false;
                BtnServerStop.IsEnabled = true;
                TxtServerPort.IsEnabled = false;
            }
            catch (Exception ex)
            {
                MessageBox.Show(\$"Fehler beim Starten: {ex.Message}", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void BtnServerStop_Click(object sender, RoutedEventArgs e)
        {
            _server?.Stop();
            _server = null;

            LblServerStatus.Content = "Gestoppt";
            LblServerStatus.Foreground = System.Windows.Media.Brushes.Red;
            BtnServerStart.IsEnabled = true;
            BtnServerStop.IsEnabled = false;
            TxtServerPort.IsEnabled = true;
        }

        private void AppendServerLog(string message)
        {
            Dispatcher.Invoke(() =>
            {
                LstServerLog.Items.Add(message);
                LstServerLog.ScrollIntoView(LstServerLog.Items[^1]);
                TxtServerStats.Text = \$"Verbundene Clients: {_server?.ClientCount ?? 0}";
            });
        }

        private void BtnClearServerLog_Click(object sender, RoutedEventArgs e)
        {
            LstServerLog.Items.Clear();
        }

        // ══════════════════════════════════════════════════════
        //  CLIENT
        // ══════════════════════════════════════════════════════

        private async void BtnClientConnect_Click(object sender, RoutedEventArgs e)
        {
            var host = TxtClientHost.Text.Trim();
            var name = TxtClientName.Text.Trim();

            if (string.IsNullOrWhiteSpace(name))
            {
                MessageBox.Show("Bitte einen Benutzernamen eingeben.", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (!int.TryParse(TxtClientPort.Text, out int port) || port < 1 || port > 65535)
            {
                MessageBox.Show("Ungültiger Port (1–65535).", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                _connection = new ServerConnection();
                _connection.PacketReceived += OnClientPacketReceived;
                _connection.Disconnected += () =>
                {
                    Dispatcher.Invoke(() =>
                    {
                        SetClientConnected(false);
                        LstClientData.Items.Add("[System] Verbindung zum Server verloren.");
                    });
                };

                await _connection.ConnectAsync(host, port);
                _clientName = name;
                _connection.Send(Packet.Create(PacketType.Connect, name));
                LstClientData.Items.Add("[System] Verbindung wird hergestellt...");
            }
            catch (Exception ex)
            {
                MessageBox.Show(\$"Verbindung fehlgeschlagen: {ex.Message}", "Fehler",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private void OnClientPacketReceived(Packet packet)
        {
            Dispatcher.Invoke(() =>
            {
                switch (packet.Type)
                {
                    case PacketType.ConnectResponse:
                        var response = packet.GetPayload<string>();
                        LstClientData.Items.Add(\$"[Server] {response}");
                        SetClientConnected(true);
                        break;

                    case PacketType.DataReceived:
                        var data = packet.GetPayload<$CLASS_NAME>();
                        if (data != null)
                        {
                            var json = JsonConvert.SerializeObject(data, Formatting.None);
                            LstClientData.Items.Add(\$"[{DateTime.Now:HH:mm:ss}] {json}");
                        }
                        break;

                    case PacketType.ClientJoined:
                        var joinedName = packet.GetPayload<string>();
                        LstClientData.Items.Add(\$"[System] {joinedName} hat sich verbunden.");
                        break;

                    case PacketType.ClientLeft:
                        var leftName = packet.GetPayload<string>();
                        LstClientData.Items.Add(\$"[System] {leftName} hat sich getrennt.");
                        break;

                    case PacketType.Error:
                        var error = packet.GetPayload<string>();
                        LstClientData.Items.Add(\$"[Fehler] {error}");
                        _connection?.Disconnect();
                        SetClientConnected(false);
                        break;
                }

                if (LstClientData.Items.Count > 0)
                    LstClientData.ScrollIntoView(LstClientData.Items[^1]);
            });
        }

        private void SetClientConnected(bool connected)
        {
            BtnClientConnect.IsEnabled = !connected;
            BtnClientDisconnect.IsEnabled = connected;
            TxtClientHost.IsEnabled = !connected;
            TxtClientPort.IsEnabled = !connected;
            TxtClientName.IsEnabled = !connected;
            TxtClientInput.IsEnabled = connected;
            BtnClientSend.IsEnabled = connected;

            LblClientStatus.Content = connected ? "Verbunden" : "Getrennt";
            LblClientStatus.Foreground = connected
                ? System.Windows.Media.Brushes.Green
                : System.Windows.Media.Brushes.Red;

            if (connected)
                TxtClientInput.Focus();
        }

        private void BtnClientSend_Click(object sender, RoutedEventArgs e)
        {
            SendClientData();
        }

        private void TxtClientInput_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Enter)
                SendClientData();
        }

        /// <summary>
        /// Erstellt ein $CLASS_NAME-Objekt aus dem Textfeld und sendet es.
        /// Das Textfeld wird als JSON interpretiert.
        /// Falls kein gültiges JSON, wird versucht ein Objekt mit dem Text zu erstellen.
        /// </summary>
        private void SendClientData()
        {
            var text = TxtClientInput.Text.Trim();
            if (string.IsNullOrWhiteSpace(text) || _connection == null) return;

            $CLASS_NAME? obj = null;

            // Versuche JSON zu parsen
            try
            {
                obj = JsonConvert.DeserializeObject<$CLASS_NAME>(text);
            }
            catch
            {
                // Kein gültiges JSON – erstelle neues Objekt mit Standardwerten
                // Der Benutzer kann JSON im Textfeld eingeben um alle Properties zu setzen
                MessageBox.Show(
                    "Bitte gültiges JSON eingeben, z.B.:\\n" +
                    JsonConvert.SerializeObject(new $CLASS_NAME(), Formatting.Indented),
                    "Ungültiges Format", MessageBoxButton.OK, MessageBoxImage.Information);
                return;
            }

            if (obj != null)
            {
                _connection.Send(Packet.Create(PacketType.SendData, obj));
                TxtClientInput.Clear();
            }
        }

        private void BtnClientDisconnect_Click(object sender, RoutedEventArgs e)
        {
            _connection?.Send(Packet.Create(PacketType.Disconnect));
            _connection?.Disconnect();
            _connection = null;
            SetClientConnected(false);
            LstClientData.Items.Add("[System] Verbindung getrennt.");
        }

        // ══════════════════════════════════════════════════════
        //  WINDOW CLOSING
        // ══════════════════════════════════════════════════════

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            _server?.Stop();
            _connection?.Disconnect();
        }
    }
}
EOF

# ── Solution-Datei ────────────────────────────────────────────────
echo -e "${GREEN}[7/7] Erstelle Solution-Datei...${NC}"

# Generiere GUIDs
GUID_SHARED=$(python3 -c "import uuid; print(str(uuid.uuid4()).upper())" 2>/dev/null || echo "AAAA1111-AAAA-AAAA-AAAA-AAAAAAAAAAAA")
GUID_APP=$(python3 -c "import uuid; print(str(uuid.uuid4()).upper())" 2>/dev/null || echo "BBBB2222-BBBB-BBBB-BBBB-BBBBBBBBBBBB")

cat > "$BASE_DIR/$PROJECT_NAME.sln" << EOF

Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "$PROJECT_NAME.Shared", "$PROJECT_NAME.Shared\\$PROJECT_NAME.Shared.csproj", "{$GUID_SHARED}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "$PROJECT_NAME.App", "$PROJECT_NAME.App\\$PROJECT_NAME.App.csproj", "{$GUID_APP}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{$GUID_SHARED}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{$GUID_SHARED}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{$GUID_SHARED}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{$GUID_SHARED}.Release|Any CPU.Build.0 = Release|Any CPU
		{$GUID_APP}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{$GUID_APP}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{$GUID_APP}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{$GUID_APP}.Release|Any CPU.Build.0 = Release|Any CPU
	EndGlobalSection
EndGlobal
EOF

# ── Fertig! ───────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Projekt erfolgreich erstellt!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  📁 ${YELLOW}$BASE_DIR/${NC}"
echo -e "     ├── $PROJECT_NAME.sln"
echo -e "     ├── ${YELLOW}$PROJECT_NAME.Shared/${NC}"
echo -e "     │   ├── Models/${YELLOW}$CS_FILENAME${NC}  ← Dein Datenmodell"
echo -e "     │   └── Protocol/  (Packet + PacketType)"
echo -e "     └── ${YELLOW}$PROJECT_NAME.App/${NC}"
echo -e "         ├── Network/   (TcpServer + ServerConnection)"
echo -e "         └── MainWindow (Server/Client Auswahl)"
echo ""
echo -e "  Öffne in Visual Studio: ${GREEN}$BASE_DIR/$PROJECT_NAME.sln${NC}"
echo ""
echo -e "  ${YELLOW}Hinweis:${NC} Der Client sendet $CLASS_NAME-Objekte als JSON."
echo -e "  Eingabe-Beispiel: $(python3 -c "print('{\"Property\": \"Wert\"}')" 2>/dev/null || echo '{"Property": "Wert"}')"
echo ""
