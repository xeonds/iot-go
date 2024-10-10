import 'dart:convert';
import 'package:app/wifi_setup_page.dart';
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

  // 注销设备
  Future<void> unregisterDevice(String id) async {
    if (gatewayIp == null) return;
    try {
      final response = await http
          .post(Uri.parse('http://$gatewayIp:$gatewayPort/unregister/$id'));
      if (response.statusCode == 200) {
        print('Device $id unregistered successfully');
        setState(() {
          devices.removeWhere((device) => device.id == id);
        });
      } else {
        throw Exception('Failed to unregister device');
      }
    } catch (e) {
      print('Error unregistering device: $e');
    }
  }

  // 重命名设备
  void showRenameDialog(BuildContext context, Device device) {
    TextEditingController nameController = TextEditingController();
    nameController.text = device.name;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Device'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Enter new name',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                renameDevice(device.id, nameController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void renameDevice(String id, String name) async {
    if (gatewayIp == null) return;
    try {
      final response = await http
          .post(Uri.parse('http://$gatewayIp:$gatewayPort/rename/$id/$name'));
      if (response.statusCode == 200) {
        print('Device $id renamed to $name');
        setState(() {
          devices.firstWhere((device) => device.id == id).name = name;
        });
      } else {
        throw Exception('Failed to rename device');
      }
    } catch (e) {
      print('Error renaming device: $e');
    }
  }

  void showUnregisterDialog(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content:
              const Text('Are you sure you want to unregister this device?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                unregisterDevice(device.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Unregister'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController searchController =
                      TextEditingController();
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            const Text(
                              "Add Device",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 4 / 2,
                            ),
                            itemCount: 2,
                            itemBuilder: (context, index) {
                              final deviceTypes = [
                                'Wifi Device',
                                'Bluetooth Device'
                              ];
                              final deviceType = deviceTypes[index];
                              return Card(
                                child: InkWell(
                                  onTap: () {
                                    if (deviceType == 'Wifi Device') {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WiFiSetupPage(),
                                          ));
                                    } else if (deviceType ==
                                        'Bluetooth Device') {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Info'),
                                            content: const Text(
                                                'Not Implemented Yet'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.devices),
                                        const SizedBox(height: 6),
                                        Text(deviceType),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDevices,
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gateway Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('IP: ${gatewayIp ?? 'Not found'}'),
                          Text('Port: ${gatewayPort ?? 'Not found'}'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 4 / 2,
                      ),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return Card(
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(children: [
                                          IconButton(
                                            icon: const Icon(Icons.arrow_back),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          const Text(
                                            "Device Details",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ]),
                                        const SizedBox(height: 16),
                                        ListTile(
                                          leading: const Icon(Icons.info),
                                          title: Text(
                                            device.name == ''
                                                ? device.id
                                                : device.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Status: ${device.status}'),
                                              Text('Device ID: ${device.id}'),
                                              Text('Gateway IP: $gatewayIp'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            String action = device.status == "1"
                                                ? '0'
                                                : '1';
                                            controlDevice(device.id, action);
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(device.status == "1"
                                              ? 'Turn Off'
                                              : 'Turn On'),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                            onPressed: () => showRenameDialog(
                                                context, device),
                                            child: const Text('Rename Device')),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () => showUnregisterDialog(
                                              context, device),
                                          child:
                                              const Text('Unregister Device'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Icon(Icons.devices),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.power_settings_new),
                                            color: device.status == "1"
                                                ? Colors.green
                                                : device.status == "0"
                                                    ? Colors.black
                                                    : Colors.grey,
                                            onPressed: device.status == "-1"
                                                ? null
                                                : () {
                                                    String action =
                                                        device.status == "1"
                                                            ? '0'
                                                            : '1';
                                                    controlDevice(
                                                        device.id, action);
                                                  },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.name == ''
                                                ? device.id
                                                : device.name,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                )),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
