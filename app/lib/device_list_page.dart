import 'package:app/session_model.dart';
import 'package:app/wifi_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/* TODO: cache device actions from server's /api/device/cmds
  and generate item's control panel based on the action cmds
*/
class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  @override
  void initState() {
    super.initState();
  }

  void showUnregisterDialog(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final session = Provider.of<SessionModel>(context, listen: false);
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
                session.unregisterDevice(device.id);
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

  // 重命名设备
  void showRenameDialog(BuildContext context, Device device) {
    TextEditingController nameController = TextEditingController();
    nameController.text = device.name;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final session = Provider.of<SessionModel>(context, listen: false);
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
                session.renameDevice(device.id, nameController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionModel>(context, listen: true);
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
                  // TODO: filter adapter types by input box
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
      body: session.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: session.fetchDevices,
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
                          Text('IP: ${session.gatewayIp ?? 'Not found'}'),
                          Text('Port: ${session.gatewayPort ?? 'Not found'}'),
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
                      itemCount: session.devices.length,
                      itemBuilder: (context, index) {
                        final device = session.devices[index];
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
                                              Text(
                                                  'Gateway IP: ${session.gatewayIp}'),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () {
                                            String action = device.status == "1"
                                                ? '0'
                                                : '1';
                                            session.controlDevice(
                                                device.id, action);
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
                                                    session.controlDevice(
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
        onPressed: session.fetchDevices,
        tooltip: 'Refresh Devices',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
