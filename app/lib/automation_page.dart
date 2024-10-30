import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage> {
  Widget _buildDeviceCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          // Handle card tap
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
                    const Text(
                      'Title',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Description'),
                    const SizedBox(height: 8),
                    const Text('Cmd Counts: 5'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: List<Widget>.generate(3, (int index) {
                        return Chip(
                          label: Text('Device ${index + 1}'),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (bool value) {
                  // Handle switch toggle
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Automation Rule'),
      ),
      body: ListView(
        children: <Widget>[
          _buildDeviceCard(context),
        ],
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
