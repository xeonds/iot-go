import 'dart:convert';
import 'dart:io';

import 'package:app/session_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage> {
  Widget _buildDeviceCard(BuildContext context, Rule data) {
    final session = Provider.of<SessionModel>(context, listen: true);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AutomationDetailPage(rule: data)),
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
                      session.runRule(data.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rule ${data.name} is running.'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Rule'),
                            content: Text(
                                'Are you sure you want to delete rule ${data.name}?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () async {
                                  await session.deleteRule(data.id);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                      );
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
                      data.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(data.description),
                    const SizedBox(height: 8),
                    Text('Tasks Counts: ${data.tasks.length}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: data.tasks.map((device) {
                        return Chip(
                          label: Text(device.deviceID),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Switch(
                value: data.isEnabled,
                onChanged: (bool value) {
                  setState(() async {
                    data.isEnabled = value;
                    await session.updateRule(data);
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
      body: session.rules.isEmpty
          ? const Center(child: Text("No automation rules found."))
          : RefreshIndicator(
              onRefresh: session.fetchRules,
              child: ListView(
                children: session.rules
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
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final file = File(result.files.single.path!);
                    final content = await file.readAsString();
                    print(content);
                    final rule = Rule.fromJson(json.decode(content));
                    await session.createRule(rule);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rule ${rule.name} loaded.'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No file selected.'),
                      ),
                    );
                  }
                },
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AutomationDetailPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AutomationDetailPage extends StatefulWidget {
  final Rule? rule;

  const AutomationDetailPage({super.key, this.rule});

  @override
  State<AutomationDetailPage> createState() => _AutomationDetailPageState();
}

class _AutomationDetailPageState extends State<AutomationDetailPage> {
  Rule rule = Rule(
    name: 'New Rule',
    description: '',
    tasks: [],
    isEnabled: false,
    isManual: true,
    conditions: [],
    selectedDateTime: null,
    selectedRepeat: 'no',
    repeat: '',
  );

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      rule = widget.rule!;
    }
  }

  void _addCondition() {
    final id =
        Provider.of<SessionModel>(context, listen: false).devices.first.id;
    setState(() {
      rule.conditions.add(Condition(item: id, comparator: ">", value: "1"));
    });
  }

  void _removeCondition(int index) {
    setState(() {
      rule.conditions.removeAt(index);
    });
  }

  void _saveConfigToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/rule_${rule.name}.json');
    await file.writeAsString(json.encode(rule));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rule configuration saved to ${file.path}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveConfigToFile,
          ),
        ],
        title: const Text('Automation Detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Rule Name',
            ),
            controller: TextEditingController(text: rule.name),
            onChanged: (String newValue) {
              setState(() {
                rule.name = newValue;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Rule Description',
            ),
            controller: TextEditingController(text: rule.description),
            onChanged: (String newValue) {
              setState(() {
                rule.description = newValue;
              });
            },
          ),
          const SizedBox(height: 16),
          const ListTile(
            title: Text('Commands for Devices'),
          ),
          for (int i = 0; i < rule.tasks.length; i++)
            Dismissible(
              key: Key(rule.tasks[i].toString()),
              onDismissed: (direction) {
                _removeDevice(i);
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
                            controller: TextEditingController(
                                text: rule.tasks[i].commands.join('\n')),
                            onChanged: (String newValue) {
                              setState(() {
                                rule.tasks[i].commands = newValue.split('\n');
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: rule.tasks[i].deviceID == ''
                              ? session.devices.first.id
                              : rule.tasks[i].deviceID,
                          hint: const Text('Select Device'),
                          items: session.devices
                              .map((device) => DropdownMenuItem<String>(
                                    value: device.id,
                                    child: Text(device.id),
                                  ))
                              .toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              rule.tasks[i].deviceID = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Selected Device: ${rule.tasks[i].deviceID}'),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _addDeviceCommand,
              child: const Text('Add Device Command'),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Mode'),
            subtitle: const Text('Run manually, or on a schedule.'),
            trailing: SegmentedButton<bool>(
              showSelectedIcon: false,
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
              selected: {rule.isManual},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  rule.isManual = newSelection.first;
                });
              },
            ),
          ),
          if (!rule.isManual) ...[
            const ListTile(
              title: Text('Routine Setup'),
            ),
            ListTile(
              title:
                  Text(rule.dateTime != null ? rule.dateTime.toString() : ''),
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
                      setState(() {
                        rule.dateTime = pickedDateTime;
                      });
                    }
                  }
                },
                child: const Text('Select Date and Time'),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              showSelectedIcon: false,
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
              selected: {rule.repeat},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  rule.repeat = newSelection.first;
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          const ListTile(
            title: Text('Conditions'),
          ),
          for (int i = 0; i < rule.conditions.length; i++)
            Dismissible(
              key: Key(rule.conditions[i].toString()),
              onDismissed: (direction) {
                _removeCondition(i);
              },
              background: Container(color: Colors.red),
              child: ListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: rule.conditions[i].item == ''
                            ? session.devices.first.id
                            : rule.conditions[i].item,
                        hint: const Text('Select Item'),
                        items: session.devices
                            .map((device) => DropdownMenuItem<String>(
                                  value: device.id,
                                  child: Text(device.id),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            rule.conditions[i].item = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'greater',
                            label: Text('>'),
                          ),
                          ButtonSegment(
                            value: 'exactly',
                            label: Text('='),
                          ),
                          ButtonSegment(
                            value: 'less',
                            label: Text('<'),
                          ),
                        ],
                        selected: {rule.conditions[i].comparator},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            rule.conditions[i].comparator = newSelection.first;
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
                        controller: TextEditingController(
                            text: rule.conditions[i].value),
                        onChanged: (String newValue) {
                          setState(() {
                            rule.conditions[i].value = newValue;
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
        onPressed: () async {
          if (widget.rule == null) {
            await session.createRule(rule);
          } else {
            await session.updateRule(rule);
          }
          Navigator.pop(context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  void _addDeviceCommand() {
    final id =
        Provider.of<SessionModel>(context, listen: false).devices.first.id;
    setState(() {
      rule.tasks.add(Task(deviceID: id, commands: []));
    });
  }

  void _removeDevice(int index) {
    setState(() {
      rule.tasks.removeAt(index);
    });
  }
}
