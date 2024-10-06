import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Device Control',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DeviceListPage(),
    );
  }
}

class Device {
  final String id;
  String name;
  String status;

  Device({required this.id, required this.name, required this.status});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      status: json['status'],
    );
  }
}

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<Device> devices = [];
  String? gatewayIp;
  bool isLoading = false;
  int? gatewayPort;

  @override
  void initState() {
    super.initState();
    discoverGateway();
  }

  // 使用 multicast_dns 发现服务，只使用第一个发现的网关
  void discoverGateway() async {
    final MDnsClient client = MDnsClient();
    await client.start();

    bool gatewayFound = false;

    // 查找 "_iot-gateway._tcp" 服务
    await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_iot-gateway._tcp'))) {
      if (gatewayFound) break;
      await for (final SrvResourceRecord srv
          in client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName))) {
        if (gatewayFound) break;
        await for (final IPAddressResourceRecord ip
            in client.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target))) {
          if (!gatewayFound) {
            setState(() {
              gatewayIp = ip.address.address;
              gatewayPort = srv.port;
              print("Gateway IP found: $gatewayIp");
            });
            fetchDevices(); // 找到网关后立即获取设备
            gatewayFound = true;
          }
        }
      }
    }

    client.stop();
  }

  // 获取设备列表
  Future<void> fetchDevices() async {
    if (gatewayIp == null) return;
    setState(() {
      isLoading = true;
    });
    try {
      final response =
          await http.get(Uri.parse('http://$gatewayIp:$gatewayPort/devices'));
      if (response.statusCode == 200) {
        List<dynamic> deviceJson = json.decode(response.body);
        setState(() {
          devices = deviceJson.map((json) => Device.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load devices');
      }
    } catch (e) {
      print('Error fetching devices: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 控制设备状态
  Future<void> controlDevice(String id, String action) async {
    if (gatewayIp == null) return;
    try {
      final response = await http.post(
          Uri.parse('http://$gatewayIp:$gatewayPort/control/$id/$action'));
      if (response.statusCode == 200) {
        print('Device $id action $action successful');
        setState(() {
          devices.firstWhere((device) => device.id == id).status = action;
        });
      }
    } catch (e) {
      print('Error controlling device: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDevices,
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    title: Text(device.name == '' ? device.id : device.name),
                    trailing: Switch(
                      value: device.status == "1",
                      onChanged: (value) {
                        String action = value ? '1' : '0';
                        controlDevice(device.id, action);
                      },
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          TextEditingController nameController =
                              TextEditingController();
                          return AlertDialog(
                            title: Text('Rename Device'),
                            content: TextField(
                              controller: nameController,
                              decoration:
                                  InputDecoration(hintText: "Enter new name"),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Rename'),
                                onPressed: () async {
                                  String newName = nameController.text;
                                  if (newName.isNotEmpty) {
                                    try {
                                      final response = await http.post(
                                        Uri.parse(
                                            'http://$gatewayIp:$gatewayPort/rename/${device.id}/$newName'),
                                      );
                                      if (response.statusCode == 200) {
                                        setState(() {
                                          device.name = newName;
                                        });
                                        Navigator.of(context).pop();
                                      } else {
                                        throw Exception(
                                            'Failed to rename device');
                                      }
                                    } catch (e) {
                                      print('Error renaming device: $e');
                                    }
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.delete),
                                title: const Text('Delete Device'),
                                onTap: () async {
                                  try {
                                    final response = await http.post(
                                      Uri.parse(
                                          'http://$gatewayIp:$gatewayPort/unregister/${device.id}'),
                                    );
                                    if (response.statusCode == 200) {
                                      setState(() {
                                        devices.removeWhere(
                                            (d) => d.id == device.id);
                                      });
                                      Navigator.of(context).pop();
                                    } else {
                                      throw Exception(
                                          'Failed to delete device');
                                    }
                                  } catch (e) {
                                    print('Error deleting device: $e');
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchDevices,
        tooltip: 'Refresh Devices',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
