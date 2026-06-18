<#
.SYNOPSIS
    Erstellt automatisch ein WPF Server-Client Projekt aus einer .cs Datei.

.DESCRIPTION
    Liest eine .cs Datei ein, extrahiert den Klassennamen und generiert ein
    komplettes WPF-Projekt mit Server/Client Auswahl, TCP-Netzwerk und
    Shared Library.

.EXAMPLE
    .\create-server-client.ps1 Message.cs
    .\create-server-client.ps1 Message.cs MeinProjekt
    .\create-server-client.ps1 .\Models\Player.cs GameNetwork
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$CsFile,

    [Parameter(Position=1)]
    [string]$ProjectName = "ServerClient"
)

# ── Prüfungen ─────────────────────────────────────────────────────
if (-not (Test-Path $CsFile)) {
    Write-Host "Fehler: Datei '$CsFile' nicht gefunden!" -ForegroundColor Red
    exit 1
}

if (-not $CsFile.EndsWith(".cs")) {
    Write-Host "Fehler: '$CsFile' ist keine .cs Datei!" -ForegroundColor Red
    exit 1
}

# ── Klassennamen extrahieren ──────────────────────────────────────
$content = Get-Content $CsFile -Raw
$match = [regex]::Match($content, '(?:public\s+)?(?:partial\s+)?(?:class|record|struct)\s+([A-Za-z_][A-Za-z0-9_]*)')
if (-not $match.Success) {
    Write-Host "Fehler: Kein Klassenname in '$CsFile' gefunden!" -ForegroundColor Red
    exit 1
}
$ClassName = $match.Groups[1].Value
$CsFilename = [System.IO.Path]::GetFileName($CsFile)

Write-Host "===================================================" -ForegroundColor Blue
Write-Host "  Server-Client Projekt Generator" -ForegroundColor Blue
Write-Host "===================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  CS-Datei:      $CsFile" -ForegroundColor Yellow
Write-Host "  Klassenname:   $ClassName" -ForegroundColor Yellow
Write-Host "  Projektname:   $ProjectName" -ForegroundColor Yellow
Write-Host ""

# ── Ordner prüfen ─────────────────────────────────────────────────
$BaseDir = $ProjectName
if (Test-Path $BaseDir) {
    Write-Host "Fehler: Ordner '$BaseDir' existiert bereits!" -ForegroundColor Red
    exit 1
}

$SharedNs = "$ProjectName.Shared"
$AppNs = "$ProjectName.App"

# ── Verzeichnisse erstellen ───────────────────────────────────────
Write-Host "[1/7] Erstelle Verzeichnisstruktur..." -ForegroundColor Green
New-Item -ItemType Directory -Path "$BaseDir\$ProjectName.Shared\Models" -Force | Out-Null
New-Item -ItemType Directory -Path "$BaseDir\$ProjectName.Shared\Protocol" -Force | Out-Null
New-Item -ItemType Directory -Path "$BaseDir\$ProjectName.App\Network" -Force | Out-Null

# ── .cs Datei kopieren ────────────────────────────────────────────
Write-Host "[2/7] Kopiere und passe $CsFilename an..." -ForegroundColor Green

$csContent = Get-Content $CsFile -Raw
if ($csContent -match 'namespace\s+[A-Za-z0-9_.]+') {
    $csContent = $csContent -replace 'namespace\s+[A-Za-z0-9_.]+', "namespace $SharedNs.Models"
} else {
    $csContent = "namespace $SharedNs.Models`n{`n$csContent`n}"
}
Set-Content -Path "$BaseDir\$ProjectName.Shared\Models\$CsFilename" -Value $csContent

# ── Shared .csproj ────────────────────────────────────────────────
Write-Host "[3/7] Erstelle Shared Projekt..." -ForegroundColor Green

@"
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
"@ | Set-Content "$BaseDir\$ProjectName.Shared\$ProjectName.Shared.csproj"

# ── PacketType.cs ─────────────────────────────────────────────────
@"
namespace $SharedNs.Protocol
{
    public enum PacketType
    {
        SendData,
        DataReceived,
        Connect,
        ConnectResponse,
        Disconnect,
        ClientJoined,
        ClientLeft,
        Error
    }
}
"@ | Set-Content "$BaseDir\$ProjectName.Shared\Protocol\PacketType.cs"

# ── Packet.cs ─────────────────────────────────────────────────────
@"
using Newtonsoft.Json;

namespace $SharedNs.Protocol
{
    public class Packet
    {
        public PacketType Type { get; set; }
        public string? Payload { get; set; }

        public static Packet Create<T>(PacketType type, T payload) => new()
        {
            Type = type,
            Payload = JsonConvert.SerializeObject(payload)
        };

        public static Packet Create(PacketType type) => new() { Type = type };

        public string ToJson() => JsonConvert.SerializeObject(this);

        public static Packet? FromJson(string json) =>
            JsonConvert.DeserializeObject<Packet>(json);

        public T? GetPayload<T>() =>
            Payload == null ? default : JsonConvert.DeserializeObject<T>(Payload);
    }
}
"@ | Set-Content "$BaseDir\$ProjectName.Shared\Protocol\Packet.cs"

# ── App .csproj ───────────────────────────────────────────────────
Write-Host "[4/7] Erstelle App Projekt..." -ForegroundColor Green

@"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net8.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>

  <ItemGroup>
    <ProjectReference Include="..\$ProjectName.Shared\$ProjectName.Shared.csproj" />
  </ItemGroup>

</Project>
"@ | Set-Content "$BaseDir\$ProjectName.App\$ProjectName.App.csproj"

# ── TcpServer.cs ──────────────────────────────────────────────────
Write-Host "[5/7] Erstelle Netzwerk-Layer..." -ForegroundColor Green

@"
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using $SharedNs.Models;
using $SharedNs.Protocol;

namespace $AppNs.Network
{
    public class TcpServer
    {
        private TcpListener? _listener;
        private bool _running;
        private readonly List<ConnectedClient> _clients = new();
        private readonly object _lock = new();

        public event Action<string>? OnLog;
        public event Action<$ClassName, string>? OnDataReceived;

        public void Start(int port)
        {
            _listener = new TcpListener(IPAddress.Any, port);
            _listener.Start();
            _running = true;
            Log(`$"Server gestartet auf Port {port}");
            Task.Run(AcceptConnections);
        }

        public void Stop()
        {
            _running = false;
            lock (_lock) { foreach (var c in _clients) c.Close(); _clients.Clear(); }
            _listener?.Stop();
            Log("Server gestoppt.");
        }

        private async Task AcceptConnections()
        {
            while (_running)
            {
                try
                {
                    var tcpClient = await _listener!.AcceptTcpClientAsync();
                    Log(`$"Neue Verbindung von {tcpClient.Client.RemoteEndPoint}");
                    var client = new ConnectedClient(tcpClient);
                    client.OnPacketReceived += packet => HandlePacket(client, packet);
                    client.OnDisconnected += () => HandleDisconnect(client);
                    client.StartReceiving();
                }
                catch { if (!_running) break; }
            }
        }

        private void HandlePacket(ConnectedClient client, Packet packet)
        {
            switch (packet.Type)
            {
                case PacketType.Connect: HandleConnect(client, packet); break;
                case PacketType.SendData: HandleData(client, packet); break;
                case PacketType.Disconnect: HandleDisconnect(client); break;
            }
        }

        private void HandleConnect(ConnectedClient client, Packet packet)
        {
            var name = packet.GetPayload<string>();
            if (string.IsNullOrWhiteSpace(name))
            { client.Send(Packet.Create(PacketType.Error, "Benutzername darf nicht leer sein.")); return; }

            lock (_lock)
            {
                if (_clients.Any(c => c.Name == name))
                { client.Send(Packet.Create(PacketType.Error, `$"Name '{name}' ist bereits vergeben.")); return; }
            }

            client.Name = name;
            lock (_lock) _clients.Add(client);
            client.Send(Packet.Create(PacketType.ConnectResponse, "Verbindung erfolgreich."));
            Log(`$"Client verbunden: {name} ({client.RemoteEndPoint})");
            BroadcastExcept(Packet.Create(PacketType.ClientJoined, name), client);
        }

        private void HandleData(ConnectedClient client, Packet packet)
        {
            var data = packet.GetPayload<$ClassName>();
            if (data == null || !client.IsConnected) return;
            Log(`$"Daten empfangen von {client.Name}: {data}");
            OnDataReceived?.Invoke(data, client.Name!);
            Broadcast(Packet.Create(PacketType.DataReceived, data));
        }

        private void HandleDisconnect(ConnectedClient client)
        {
            if (client.Name == null) return;
            var name = client.Name;
            lock (_lock) _clients.Remove(client);
            client.Close();
            Log(`$"Client getrennt: {name}");
            Broadcast(Packet.Create(PacketType.ClientLeft, name));
        }

        private void Broadcast(Packet packet)
        { lock (_lock) foreach (var c in _clients.Where(c => c.IsConnected)) c.Send(packet); }

        private void BroadcastExcept(Packet packet, ConnectedClient except)
        { lock (_lock) foreach (var c in _clients.Where(c => c.IsConnected && c != except)) c.Send(packet); }

        public void Log(string message) { OnLog?.Invoke(`$"[{DateTime.Now:HH:mm:ss}] {message}"); }
        public int ClientCount { get { lock (_lock) return _clients.Count; } }
    }

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

        public void StartReceiving() { _running = true; Task.Run(ReceiveLoop); }

        private async Task ReceiveLoop()
        {
            try
            {
                string? line;
                while (_running && (line = await _reader.ReadLineAsync()) != null)
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var packet = Packet.FromJson(line);
                    if (packet != null) OnPacketReceived?.Invoke(packet);
                }
            }
            catch (IOException) { }
            catch (Exception) { }
            finally { _running = false; OnDisconnected?.Invoke(); }
        }

        public void Send(Packet packet)
        { try { lock (_sendLock) _writer.WriteLine(packet.ToJson()); } catch { } }

        public void Close() { _running = false; try { _tcpClient.Close(); } catch { } }
    }
}
"@ | Set-Content "$BaseDir\$ProjectName.App\Network\TcpServer.cs"

# ── ServerConnection.cs ───────────────────────────────────────────
@"
using System;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using $SharedNs.Protocol;

namespace $AppNs.Network
{
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
            _client = new TcpClient { NoDelay = true };
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
                    if (packet != null) PacketReceived?.Invoke(packet);
                }
            }
            catch (IOException) { }
            catch (Exception) { }
            finally { _running = false; if (!_intentionalDisconnect) Disconnected?.Invoke(); }
        }

        public void Send(Packet packet)
        { try { lock (_writeLock) _writer?.WriteLine(packet.ToJson()); } catch { } }

        public void Disconnect()
        { _intentionalDisconnect = true; _running = false; try { _client?.Close(); } catch { } }
    }
}
"@ | Set-Content "$BaseDir\$ProjectName.App\Network\ServerConnection.cs"

# ── App.xaml ──────────────────────────────────────────────────────
Write-Host "[6/7] Erstelle WPF Oberflaeche..." -ForegroundColor Green

@"
<Application x:Class="$AppNs.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             StartupUri="MainWindow.xaml">
    <Application.Resources />
</Application>
"@ | Set-Content "$BaseDir\$ProjectName.App\App.xaml"

@"
using System.Windows;

namespace $AppNs
{
    public partial class App : Application { }
}
"@ | Set-Content "$BaseDir\$ProjectName.App\App.xaml.cs"

# ── MainWindow.xaml ───────────────────────────────────────────────
@"
<Window x:Class="$AppNs.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="$ProjectName" Height="650" Width="850"
        WindowStartupLocation="CenterScreen"
        Closing="Window_Closing">
    <Window.Resources>
        <Style TargetType="Button"><Setter Property="Padding" Value="12,6"/><Setter Property="Margin" Value="4"/><Setter Property="FontSize" Value="13"/></Style>
        <Style TargetType="TextBox"><Setter Property="Padding" Value="4,3"/><Setter Property="Margin" Value="4"/><Setter Property="VerticalContentAlignment" Value="Center"/></Style>
        <Style TargetType="Label"><Setter Property="VerticalAlignment" Value="Center"/><Setter Property="FontSize" Value="13"/></Style>
    </Window.Resources>
    <Grid>
        <Grid x:Name="PnlStart">
            <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                <TextBlock Text="Server-Client Anwendung" FontSize="24" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,20"/>
                <TextBlock Text="Waehle den Modus:" FontSize="14" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                <ComboBox x:Name="CmbMode" Width="250" FontSize="14" Padding="8,6" Margin="0,0,0,15" SelectedIndex="0">
                    <ComboBoxItem Content="Als Server starten"/>
                    <ComboBoxItem Content="Als Client starten"/>
                </ComboBox>
                <Button x:Name="BtnStartMode" Content="Starten" FontSize="16" FontWeight="Bold" Padding="20,10" HorizontalAlignment="Center" Click="BtnStartMode_Click"/>
            </StackPanel>
        </Grid>
        <DockPanel x:Name="PnlServer" Margin="8" Visibility="Collapsed">
            <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0,0,0,8">
                <Label Content="SERVER" FontWeight="Bold" FontSize="16" Foreground="DarkBlue"/>
                <Separator Margin="8,0"/>
                <Label Content="Port:"/>
                <TextBox x:Name="TxtServerPort" Text="5000" Width="70"/>
                <Button x:Name="BtnServerStart" Content="Starten" Click="BtnServerStart_Click"/>
                <Button x:Name="BtnServerStop" Content="Stoppen" Click="BtnServerStop_Click" IsEnabled="False"/>
                <Separator Margin="8,0"/>
                <Label x:Name="LblServerStatus" Content="Gestoppt" Foreground="Red" FontWeight="Bold"/>
            </StackPanel>
            <StatusBar DockPanel.Dock="Bottom"><StatusBarItem><TextBlock x:Name="TxtServerStats" Text="Verbundene Clients: 0"/></StatusBarItem></StatusBar>
            <Grid>
                <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                <GroupBox Grid.Row="0" Header="Server-Protokoll">
                    <Grid><Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                        <ListBox x:Name="LstServerLog" Grid.Row="0" FontFamily="Consolas" FontSize="12" ScrollViewer.VerticalScrollBarVisibility="Auto"/>
                        <Button Grid.Row="1" Content="Log leeren" HorizontalAlignment="Right" Margin="0,4,0,0" Click="BtnClearServerLog_Click"/>
                    </Grid>
                </GroupBox>
                <GridSplitter Grid.Row="1" Height="5" HorizontalAlignment="Stretch" Background="LightGray" ResizeDirection="Rows"/>
                <GroupBox Grid.Row="2" Header="Empfangene $ClassName-Objekte">
                    <ListBox x:Name="LstServerData" FontFamily="Consolas" FontSize="12" ScrollViewer.VerticalScrollBarVisibility="Auto"/>
                </GroupBox>
            </Grid>
        </DockPanel>
        <DockPanel x:Name="PnlClient" Margin="8" Visibility="Collapsed">
            <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Margin="0,0,0,8">
                <Label Content="CLIENT" FontWeight="Bold" FontSize="16" Foreground="DarkGreen"/>
                <Separator Margin="8,0"/>
                <Label Content="Host:"/>
                <TextBox x:Name="TxtClientHost" Text="127.0.0.1" Width="110"/>
                <Label Content="Port:"/>
                <TextBox x:Name="TxtClientPort" Text="5000" Width="60"/>
                <Label Content="Name:"/>
                <TextBox x:Name="TxtClientName" Width="100"/>
                <Button x:Name="BtnClientConnect" Content="Verbinden" Click="BtnClientConnect_Click"/>
                <Button x:Name="BtnClientDisconnect" Content="Trennen" Click="BtnClientDisconnect_Click" IsEnabled="False"/>
                <Separator Margin="8,0"/>
                <Label x:Name="LblClientStatus" Content="Getrennt" Foreground="Red" FontWeight="Bold"/>
            </StackPanel>
            <Grid DockPanel.Dock="Bottom" Margin="0,8,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBox x:Name="TxtClientInput" Grid.Column="0" FontSize="13" Padding="6,4" KeyDown="TxtClientInput_KeyDown" IsEnabled="False"/>
                <Button x:Name="BtnClientSend" Grid.Column="1" Content="Senden" FontWeight="Bold" Click="BtnClientSend_Click" IsEnabled="False"/>
            </Grid>
            <GroupBox Header="Empfangene Daten">
                <ListBox x:Name="LstClientData" FontFamily="Consolas" FontSize="12" ScrollViewer.VerticalScrollBarVisibility="Auto"/>
            </GroupBox>
        </DockPanel>
    </Grid>
</Window>
"@ | Set-Content "$BaseDir\$ProjectName.App\MainWindow.xaml"

# ── MainWindow.xaml.cs ────────────────────────────────────────────
@"
using System;
using System.Windows;
using System.Windows.Input;
using Newtonsoft.Json;
using ${AppNs}.Network;
using ${SharedNs}.Models;
using ${SharedNs}.Protocol;

namespace $AppNs
{
    public partial class MainWindow : Window
    {
        private TcpServer? _server;
        private ServerConnection? _connection;
        private string? _clientName;

        public MainWindow() { InitializeComponent(); }

        private void BtnStartMode_Click(object sender, RoutedEventArgs e)
        {
            PnlStart.Visibility = Visibility.Collapsed;
            if (CmbMode.SelectedIndex == 0) { PnlServer.Visibility = Visibility.Visible; Title = "$ProjectName - SERVER"; }
            else { PnlClient.Visibility = Visibility.Visible; Title = "$ProjectName - CLIENT"; }
        }

        // ── SERVER ────────────────────────────────────────────
        private void BtnServerStart_Click(object sender, RoutedEventArgs e)
        {
            if (!int.TryParse(TxtServerPort.Text, out int port) || port < 1 || port > 65535)
            { MessageBox.Show("Ungueltiger Port.", "Fehler", MessageBoxButton.OK, MessageBoxImage.Warning); return; }
            try
            {
                _server = new TcpServer();
                _server.OnLog += AppendServerLog;
                _server.OnDataReceived += (data, senderName) =>
                    Dispatcher.Invoke(() => { var json = JsonConvert.SerializeObject(data); LstServerData.Items.Add(`$"[{DateTime.Now:HH:mm:ss}] von {senderName}: {json}"); LstServerData.ScrollIntoView(LstServerData.Items[^1]); });
                _server.Start(port);
                LblServerStatus.Content = `$"Laeuft auf Port {port}"; LblServerStatus.Foreground = System.Windows.Media.Brushes.Green;
                BtnServerStart.IsEnabled = false; BtnServerStop.IsEnabled = true; TxtServerPort.IsEnabled = false;
            }
            catch (Exception ex) { MessageBox.Show(`$"Fehler: {ex.Message}", "Fehler", MessageBoxButton.OK, MessageBoxImage.Error); }
        }

        private void BtnServerStop_Click(object sender, RoutedEventArgs e)
        {
            _server?.Stop(); _server = null;
            LblServerStatus.Content = "Gestoppt"; LblServerStatus.Foreground = System.Windows.Media.Brushes.Red;
            BtnServerStart.IsEnabled = true; BtnServerStop.IsEnabled = false; TxtServerPort.IsEnabled = true;
        }

        private void AppendServerLog(string message)
        { Dispatcher.Invoke(() => { LstServerLog.Items.Add(message); LstServerLog.ScrollIntoView(LstServerLog.Items[^1]); TxtServerStats.Text = `$"Verbundene Clients: {_server?.ClientCount ?? 0}"; }); }

        private void BtnClearServerLog_Click(object sender, RoutedEventArgs e) { LstServerLog.Items.Clear(); }

        // ── CLIENT ────────────────────────────────────────────
        private async void BtnClientConnect_Click(object sender, RoutedEventArgs e)
        {
            var host = TxtClientHost.Text.Trim();
            var name = TxtClientName.Text.Trim();
            if (string.IsNullOrWhiteSpace(name)) { MessageBox.Show("Bitte einen Benutzernamen eingeben."); return; }
            if (!int.TryParse(TxtClientPort.Text, out int port) || port < 1 || port > 65535) { MessageBox.Show("Ungueltiger Port."); return; }
            try
            {
                _connection = new ServerConnection();
                _connection.PacketReceived += OnClientPacketReceived;
                _connection.Disconnected += () => Dispatcher.Invoke(() => { SetClientConnected(false); LstClientData.Items.Add("[System] Verbindung verloren."); });
                await _connection.ConnectAsync(host, port);
                _clientName = name;
                _connection.Send(Packet.Create(PacketType.Connect, name));
                LstClientData.Items.Add("[System] Verbindung wird hergestellt...");
            }
            catch (Exception ex) { MessageBox.Show(`$"Verbindung fehlgeschlagen: {ex.Message}"); }
        }

        private void OnClientPacketReceived(Packet packet)
        {
            Dispatcher.Invoke(() =>
            {
                switch (packet.Type)
                {
                    case PacketType.ConnectResponse: LstClientData.Items.Add(`$"[Server] {packet.GetPayload<string>()}"); SetClientConnected(true); break;
                    case PacketType.DataReceived:
                        var data = packet.GetPayload<$ClassName>();
                        if (data != null) LstClientData.Items.Add(`$"[{DateTime.Now:HH:mm:ss}] {JsonConvert.SerializeObject(data)}");
                        break;
                    case PacketType.ClientJoined: LstClientData.Items.Add(`$"[System] {packet.GetPayload<string>()} hat sich verbunden."); break;
                    case PacketType.ClientLeft: LstClientData.Items.Add(`$"[System] {packet.GetPayload<string>()} hat sich getrennt."); break;
                    case PacketType.Error: LstClientData.Items.Add(`$"[Fehler] {packet.GetPayload<string>()}"); _connection?.Disconnect(); SetClientConnected(false); break;
                }
                if (LstClientData.Items.Count > 0) LstClientData.ScrollIntoView(LstClientData.Items[^1]);
            });
        }

        private void SetClientConnected(bool c)
        {
            BtnClientConnect.IsEnabled = !c; BtnClientDisconnect.IsEnabled = c;
            TxtClientHost.IsEnabled = !c; TxtClientPort.IsEnabled = !c; TxtClientName.IsEnabled = !c;
            TxtClientInput.IsEnabled = c; BtnClientSend.IsEnabled = c;
            LblClientStatus.Content = c ? "Verbunden" : "Getrennt";
            LblClientStatus.Foreground = c ? System.Windows.Media.Brushes.Green : System.Windows.Media.Brushes.Red;
            if (c) TxtClientInput.Focus();
        }

        private void BtnClientSend_Click(object sender, RoutedEventArgs e) { SendClientData(); }
        private void TxtClientInput_KeyDown(object sender, KeyEventArgs e) { if (e.Key == Key.Enter) SendClientData(); }

        private void SendClientData()
        {
            var text = TxtClientInput.Text.Trim();
            if (string.IsNullOrWhiteSpace(text) || _connection == null) return;
            try
            {
                var obj = JsonConvert.DeserializeObject<$ClassName>(text);
                if (obj != null) { _connection.Send(Packet.Create(PacketType.SendData, obj)); TxtClientInput.Clear(); }
            }
            catch
            {
                MessageBox.Show("Bitte gueltiges JSON eingeben, z.B.:\n" +
                    JsonConvert.SerializeObject(new $ClassName(), Formatting.Indented),
                    "Ungueltiges Format", MessageBoxButton.OK, MessageBoxImage.Information);
            }
        }

        private void BtnClientDisconnect_Click(object sender, RoutedEventArgs e)
        {
            _connection?.Send(Packet.Create(PacketType.Disconnect));
            _connection?.Disconnect(); _connection = null;
            SetClientConnected(false);
            LstClientData.Items.Add("[System] Verbindung getrennt.");
        }

        private void Window_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        { _server?.Stop(); _connection?.Disconnect(); }
    }
}
"@ | Set-Content "$BaseDir\$ProjectName.App\MainWindow.xaml.cs"

# ── Solution ──────────────────────────────────────────────────────
Write-Host "[7/7] Erstelle Solution..." -ForegroundColor Green

$guidShared = [guid]::NewGuid().ToString().ToUpper()
$guidApp = [guid]::NewGuid().ToString().ToUpper()

@"

Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "$ProjectName.Shared", "$ProjectName.Shared\$ProjectName.Shared.csproj", "{$guidShared}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "$ProjectName.App", "$ProjectName.App\$ProjectName.App.csproj", "{$guidApp}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{$guidShared}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{$guidShared}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{$guidShared}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{$guidShared}.Release|Any CPU.Build.0 = Release|Any CPU
		{$guidApp}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{$guidApp}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{$guidApp}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{$guidApp}.Release|Any CPU.Build.0 = Release|Any CPU
	EndGlobalSection
EndGlobal
"@ | Set-Content "$BaseDir\$ProjectName.sln"

# ── Fertig ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "===================================================" -ForegroundColor Blue
Write-Host "  Projekt erfolgreich erstellt!" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  Ordner:    $BaseDir\" -ForegroundColor Yellow
Write-Host "  Klasse:    $ClassName" -ForegroundColor Yellow
Write-Host "  Solution:  $BaseDir\$ProjectName.sln" -ForegroundColor Green
Write-Host ""
Write-Host "  Oeffne in Visual Studio: $BaseDir\$ProjectName.sln"
Write-Host ""
