import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_iot/wifi_iot.dart';

class WiFiSetupPage extends StatefulWidget {
  @override
  _WiFiSetupPageState createState() => _WiFiSetupPageState();
}

class _WiFiSetupPageState extends State<WiFiSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WiFi Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _ssidController,
                decoration: InputDecoration(labelText: 'SSID'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter SSID';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _configureWiFi,
                child: Text('Configure WiFi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _configureWiFi() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 连接到 ESP8266 的 AP
        await WiFiForIoTPlugin.connect('ESP8266_Setup',
            password: 'password', security: NetworkSecurity.WPA);

        // 发送 WiFi 配置到 ESP8266
        final response = await http.post(
          Uri.parse('http://192.168.4.1/configure'),
          body: {
            'ssid': _ssidController.text,
            'password': _passwordController.text,
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('WiFi configured successfully')),
          );
        } else {
          throw Exception('Failed to configure WiFi');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
