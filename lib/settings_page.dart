import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String initialUrl;
  final Function(String) onUrlChanged;

  const SettingsPage({
    Key? key,
    required this.initialUrl,
    required this.onUrlChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _updateUrl() {
    widget.onUrlChanged(_urlController.text);
    Navigator.of(context).pop(); // Close the settings window
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Current URL: '),
              Text(widget.initialUrl), // Display the current URL
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Ollama URL',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _updateUrl,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
