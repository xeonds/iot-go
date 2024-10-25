import 'package:app/session_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionModel>(context);
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
            ListTile(
              title: const Text('Server IP'),
              subtitle: Text(session.gatewayIp ?? ''),
              onTap: () async {
                final ipController =
                    TextEditingController(text: session.gatewayIp);

                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Setup Server IP'),
                      content: TextField(
                        controller: ipController,
                        decoration:
                            const InputDecoration(hintText: 'Enter Server IP'),
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
                            session.gatewayIp = ipController.text;
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
              title: const Text('Server Port'),
              subtitle: Text(session.gatewayPort.toString()),
              onTap: () async {
                final portController =
                    TextEditingController(text: session.gatewayPort.toString());

                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Setup Server Port'),
                      content: TextField(
                        controller: portController,
                        decoration: const InputDecoration(
                            hintText: 'Enter Server Port'),
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
                            session.gatewayPort =
                                int.parse(portController.text);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
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
