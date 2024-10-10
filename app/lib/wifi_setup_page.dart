import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

class WiFiSetupPage extends StatefulWidget {
  @override
  _WiFiSetupPageState createState() => _WiFiSetupPageState();
}

class _WiFiSetupPageState extends State<WiFiSetupPage> {
  List<WifiNetwork> _wifiNetworks = [];
  String _selectedSSID = '';

  @override
  void initState() {
    super.initState();
    _loadWifiNetworks();
  }

  Future<void> _loadWifiNetworks() async {
    List<WifiNetwork> wifiNetworks = await WiFiForIoTPlugin.loadWifiList();
    setState(() {
      _wifiNetworks = wifiNetworks;
    });
  }

  void _connectToWiFi(String ssid) async {
    bool isConnected = await WiFiForIoTPlugin.connect(ssid);
    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to $ssid')),
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
          ? const Center(child: const CircularProgressIndicator())
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

void main() {
  runApp(MaterialApp(
    home: WiFiSetupPage(),
  ));
}
