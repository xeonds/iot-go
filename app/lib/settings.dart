import 'package:app/session_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => AboutPageState();
}

class AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionModel>(context, listen: true);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          const Text(
            'IoT-Go',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This app is designed to provide information about our IoT solutions. '
            'We aim to deliver the best IoT services to our customers.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          _buildSection(children: [
            const ListTile(
              title: Text('System can work in LAN or WAN mode. '
                  'In LAN mode, the system will connect to the local server. '
                  'In WAN mode, the system will connect to the remote server.'
                  'If you want to switch between LAN and WAN mode or both,'
                  ' just leave blank the IP:Port field that you do not want to use.'),
            ),
            ListTile(
              title: const Text('LAN Server Address'),
              subtitle: Text(session.lanGatewayIp ?? 'Unset'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final textBoxCtrl =
                    TextEditingController(text: session.lanGatewayIp);

                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Setup Server IP:Port'),
                      content: TextField(
                        controller: textBoxCtrl,
                        decoration: const InputDecoration(
                            hintText: 'IP:Port, default port is 80'),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Save'),
                          onPressed: () {
                            setState(() {
                              session.lanGatewayIp = textBoxCtrl.text;
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: const Text('WAN Server Address'),
              subtitle: Text(session.wanGatewayIp ?? 'Unset'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final textCtrl = TextEditingController(
                    text: session.wanGatewayIp.toString());

                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Setup Server IP:Port'),
                      content: TextField(
                        controller: textCtrl,
                        decoration: const InputDecoration(
                            hintText: 'WAN Server IP:Port, default port is 80'),
                        keyboardType: TextInputType.number,
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Save'),
                          onPressed: () {
                            setState(() {
                              session.wanGatewayIp = textCtrl.text;
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: const Text('Run mode'),
              subtitle: Text(session.runMode ?? ''),
              trailing: SegmentedButton(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'LAN',
                    label: Text('LAN'),
                  ),
                  ButtonSegment(
                    value: 'WAN',
                    label: Text('WAN'),
                  ),
                  ButtonSegment(
                    value: 'Hybrid',
                    label: Text('Hybrid'),
                  ),
                ],
                selected: {session.runMode ?? 'LAN'},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    session.runMode = newSelection.first;
                  });
                },
              ),
            )
          ], title: 'Gateway Configuration'),
          const SizedBox(height: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Copyright 2024 xeonds | Version 1.0.0'),
              Text('All rights reserved')
            ],
          ),
        ],
      ),
    );
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
