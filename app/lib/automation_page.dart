import 'package:app/session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';

class DeviceCardData {
  final String title;
  final String description;
  final int cmdCount;
  final List<String> devices;
  bool isActive;

  DeviceCardData({
    required this.title,
    required this.description,
    required this.cmdCount,
    required this.devices,
    required this.isActive,
  });
}

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage> {
  final List<DeviceCardData> _deviceCards = [
    DeviceCardData(
      title: 'Automation 1',
      description: 'Description 1',
      cmdCount: 5,
      devices: ['Device 1', 'Device 2', 'Device 3'],
      isActive: true,
    ),
    DeviceCardData(
      title: 'Automation 2',
      description: 'Description 2',
      cmdCount: 3,
      devices: ['Device 4', 'Device 5'],
      isActive: false,
    ),
  ];

  Widget _buildDeviceCard(BuildContext context, DeviceCardData data) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AutomationDetailPage(),
            ),
          );
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('Run'),
                    onTap: () {
                      // Handle run action
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete'),
                    onTap: () {
                      // Handle delete action
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(data.description),
                    const SizedBox(height: 8),
                    Text('Cmd Counts: ${data.cmdCount}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: data.devices.map((device) {
                        return Chip(
                          label: Text(device),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Switch(
                value: data.isActive,
                onChanged: (bool value) {
                  setState(() {
                    data.isActive = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Automation Rule'),
      ),
      body: RefreshIndicator(
        onRefresh: session.fetchRules,
        child: ListView(
          children: _deviceCards
              .map((data) => _buildDeviceCard(context, data))
              .toList(),
        ),
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        distance: 70,
        childrenAnimation: ExpandableFabAnimation.none,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.add),
          fabSize: ExpandableFabSize.regular,
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          fabSize: ExpandableFabSize.small,
        ),
        children: [
          Row(
            children: [
              const Text('Refresh'),
              const SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: null,
                child: const Icon(Icons.refresh),
                onPressed: () {
                  session.fetchRules();
                },
              ),
            ],
          ),
          Row(
            children: [
              const Text('Load automation rules'),
              const SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: null,
                child: const Icon(Icons.file_upload),
                onPressed: () {},
              ),
            ],
          ),
          Row(
            children: [
              const Text('Create new automation rule'),
              const SizedBox(width: 20),
              FloatingActionButton.small(
                heroTag: null,
                child: const Icon(Icons.create),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AutomationDetailPage extends StatefulWidget {
  const AutomationDetailPage({super.key});

  @override
  State<AutomationDetailPage> createState() => _AutomationDetailPageState();
}

class _AutomationDetailPageState extends State<AutomationDetailPage> {
  bool isManual = true;
  bool conditionsEnabled = false;
  List<Map<String, dynamic>> conditions = [];

  var _selectedDateTime;

  String _selectedRepeat = 'no';

  void _addCondition() {
    setState(() {
      conditions.add({
        'item': 'Item 1',
        'comparator': 'greater',
        'value': '',
      });
    });
  }

  void _removeCondition(int index) {
    setState(() {
      conditions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const ListTile(
            title: Text('Commands for Devices'),
          ),
          for (int i = 0; i < conditions.length; i++)
            Dismissible(
              key: Key(conditions[i].toString()),
              onDismissed: (direction) {
                _removeCondition(i);
              },
              background: Container(color: Colors.red),
              child: ListTile(
                title: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Commands',
                            ),
                            maxLines: null,
                            onChanged: (String newValue) {
                              setState(() {
                                conditions[i]['commands'] = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: conditions[i]['deviceID'],
                          hint: const Text('Select Device'),
                          items: <String>['Device 1', 'Device 2', 'Device 3']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              conditions[i]['deviceID'] = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                    if (conditions[i]['deviceID'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            'Selected Device: ${conditions[i]['deviceID']}'),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _addCondition,
              child: const Text('Add Device Command'),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Mode'),
            subtitle: const Text('Run manually, or on a schedule.'),
            trailing: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Manual'),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Routinely'),
                ),
              ],
              selected: {isManual},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  isManual = newSelection.first;
                });
              },
            ),
          ),
          if (!isManual) ...[
            const ListTile(
              title: Text('Routine Setup'),
            ),
            ListTile(
              title: Text(_selectedDateTime != null
                  ? _selectedDateTime.toString()
                  : ''),
              trailing: ElevatedButton(
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      final DateTime pickedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      _selectedDateTime = pickedDateTime;
                    }
                  }
                },
                child: const Text('Select Date and Time'),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'no',
                  label: Text('No'),
                ),
                ButtonSegment(
                  value: 'daily',
                  label: Text('Daily'),
                ),
                ButtonSegment(
                  value: 'weekly',
                  label: Text('Weekly'),
                ),
                ButtonSegment(
                  value: 'monthly',
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: 'yearly',
                  label: Text('Yearly'),
                ),
              ],
              selected: {_selectedRepeat},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedRepeat = newSelection.first;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          const ListTile(
            title: Text('Conditions'),
          ),
          for (int i = 0; i < conditions.length; i++)
            Dismissible(
              key: Key(conditions[i].toString()),
              onDismissed: (direction) {
                _removeCondition(i);
              },
              background: Container(color: Colors.red),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: conditions[i]['item'],
                        items: <String>['Item 1', 'Item 2', 'Item 3']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            conditions[i]['item'] = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: conditions[i]['comparator'],
                        items: <String>['greater', 'less', 'exactly']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            conditions[i]['comparator'] = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Value',
                        ),
                        onChanged: (String newValue) {
                          setState(() {
                            conditions[i]['value'] = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _addCondition,
              child: const Text('Add Condition'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle save action
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
