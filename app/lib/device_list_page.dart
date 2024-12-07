import 'package:app/session_model.dart';
import 'package:app/wifi_setup_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                              final deviceIcons = [Icons.wifi, Icons.bluetooth];
                              final actions = {
                                'Wifi Device': () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WiFiSetupPage(),
                                    ),
                                  );
                                },
                                'Bluetooth Device': () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Info'),
                                        content:
                                            const Text('Not Implemented Yet'),
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
                                },
                              };

                              return Card(
                                child: InkWell(
                                  onTap: actions[deviceTypes[index]],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(deviceIcons[index]),
                                        const SizedBox(height: 6),
                                        Text(deviceTypes[index]),
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600 ? 4 : 2,
                        childAspectRatio: 4 / 2,
                      ),
                      itemCount: session.devices.length,
                      itemBuilder: (context, index) {
                        final device = session.devices[index];
                        return Card(
                          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: InkWell(
                            onTap: () {
                              deviceCardOnClick(context, index, session);
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
                                            color: device.status == "-1"
                                                ? Theme.of(context)
                                                    .disabledColor
                                                : device.status == "0"
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                            onPressed: device.status == "-1"
                                                ? null
                                                : () {
                                                    String action =
                                                        device.status == "0"
                                                            ? 'action:on'
                                                            : 'action:off';
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

  Future<dynamic> deviceCardOnClick(
      BuildContext context, int deviceIndex, SessionModel session) {
    var device = session.devices[deviceIndex];
    return showModalBottomSheet(
      context: context,
      backgroundColor:
          Theme.of(context).canvasColor, // Set to default background color
      isScrollControlled: true, // Allow the bottom sheet to match content size
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    device.name == '' ? device.id : device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${device.status}'),
                      Text('Device ID: ${device.id}'),
                      Text('Gateway IP: ${session.gatewayIp}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                controlPanelBuilder(context, device),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () => showRenameDialog(context, device),
                        child: const Text('Rename Device')),
                    ElevatedButton(
                      onPressed: () => showUnregisterDialog(context, device),
                      child: const Text('Unregister Device'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget controlPanelBuilder(BuildContext context, Device device) {
    List<Widget> controlPanel = [];
    final session = Provider.of<SessionModel>(context, listen: false);
    if (device.cmds != "") {
      final cmds = device.cmds.split(';');
      List<Widget> buttonRow = [];
      for (var cmd in cmds) {
        if (cmd != "") {
          final cmdParts = cmd.split('->')[0].split(':');
          if (cmdParts[1] == 'reset') continue;

          if (cmdParts[0].split('.').length == 1) {
            buttonRow.add(
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      session.controlDevice(device.id, cmd.split('->')[0]);
                    },
                    child: Text(cmdParts[1]),
                  ),
                ),
              ),
            );
          } else {
            if (buttonRow.isNotEmpty) {
              controlPanel.add(Wrap(
                alignment: WrapAlignment.start,
                children: buttonRow,
              ));
              controlPanel.add(const SizedBox(height: 8));
              buttonRow = [];
            }
            TextEditingController paramController = TextEditingController();
            controlPanel.add(Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: paramController,
                    decoration: InputDecoration(
                      labelText: 'Enter value of ${cmdParts[0].split('.')[1]}:',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final paramValue = paramController.text;
                    final fullAction = '${cmdParts[0]}:$paramValue';
                    paramController.clear();
                    session.controlDevice(device.id, fullAction);
                  },
                  child: const Text('Send'),
                ),
              ],
            ));
            controlPanel.add(const SizedBox(height: 8));
          }
        }
      }
      if (buttonRow.isNotEmpty) {
        controlPanel.add(Wrap(
          alignment: WrapAlignment.start,
          children: buttonRow,
        ));
        controlPanel.add(const SizedBox(height: 8));
      }
    }
    if (controlPanel.isEmpty) {
      controlPanel.add(const Text('No actions available'));
    }
    return _buildSection(children: controlPanel, title: 'Control Panel');
  }

  Widget _buildSection(
          {String title = '', required List<Widget> children}) =>
      Card(
          child: Column(
              children: title != ''
                  ? [
                      const SizedBox(height: 10),
                      _buildListSubtitle(title),
                      ...children
                    ]
                  : [const SizedBox(height: 10), ...children]));

  Widget _buildListSubtitle(String text) => Row(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        )
      ]);
}
