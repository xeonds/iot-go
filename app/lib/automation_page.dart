import 'package:flutter/material.dart';

class AutomationPage extends StatefulWidget {
  const AutomationPage({super.key});

  @override
  State<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends State<AutomationPage> {
  final _formKey = GlobalKey<FormState>();
  String _device = '';
  String _condition = '';
  String _action = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Automation Rule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Device'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a device';
                  }
                  return null;
                },
                onSaved: (value) {
                  _device = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Condition'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a condition';
                  }
                  return null;
                },
                onSaved: (value) {
                  _condition = value!;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Action'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an action';
                  }
                  return null;
                },
                onSaved: (value) {
                  _action = value!;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Handle the form submission logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Automation Rule Created')),
                    );
                  }
                },
                child: const Text('Create Rule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
