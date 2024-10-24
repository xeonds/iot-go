import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;

class WiFiSetupPage extends StatefulWidget {
  @override
  _WiFiSetupPageState createState() => _WiFiSetupPageState();
}

class _WiFiSetupPageState extends State<WiFiSetupPage> {
  List<WifiNetwork> _wifiNetworks = [];
  String _selectedSSID = '';
  final String _defaultPassword = '0.0.0.0';

  @override
  void initState() {
    super.initState();
    _loadWifiNetworks();
  }

  Future<void> _loadWifiNetworks() async {
    List<WifiNetwork> wifiNetworks = await WiFiForIoTPlugin.loadWifiList();
    setState(() {
      _wifiNetworks = wifiNetworks
          .where(
              (network) => network.ssid?.startsWith('ESP8266-setup') ?? false)
          .toList();
    });
  }

  void _connectToWiFi(String ssid) async {
    bool isConnected =
        await WiFiForIoTPlugin.connect(ssid, password: _defaultPassword);
    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to $ssid')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ConfigurationPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to $ssid')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Setup Page'),
      ),
      body: _wifiNetworks.isEmpty
          ? const Center(
              child: Column(
              children: [
                Text('Scanning for Devices...'),
                CircularProgressIndicator()
              ],
            ))
          : ListView.builder(
              itemCount: _wifiNetworks.length,
              itemBuilder: (context, index) {
                final wifiNetwork = _wifiNetworks[index];
                return ListTile(
                  title: Text(wifiNetwork.ssid ?? 'Unknown SSID'),
                  onTap: () {
                    setState(() {
                      _selectedSSID = wifiNetwork.ssid ?? '';
                    });
                    _connectToWiFi(_selectedSSID);
                  },
                );
              },
            ),
    );
  }
}

class ConfigurationPage extends StatefulWidget {
  @override
  _ConfigurationPageState createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  final TextEditingController _controller1 = TextEditingController();
  final TextEditingController _controller2 = TextEditingController();
  final TextEditingController _controller3 = TextEditingController();
  final TextEditingController _controller4 = TextEditingController();

  void _submitConfiguration() async {
    final response = await http.post(
      Uri.parse('http://192.168.4.1/configure'),
      body: {
        'ssid': _controller1.text,
        'pass': _controller2.text,
        'addr': _controller3.text,
        'port': _controller4.text,
      },
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to configure')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller1,
              decoration: InputDecoration(labelText: 'WiFi SSID'),
            ),
            TextField(
              controller: _controller2,
              decoration: InputDecoration(labelText: 'WiFi Password'),
            ),
            TextField(
              controller: _controller3,
              decoration: InputDecoration(labelText: 'Server IP/Domain Name'),
            ),
            TextField(
              controller: _controller4,
              decoration: InputDecoration(labelText: 'Server Port'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitConfiguration,
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
