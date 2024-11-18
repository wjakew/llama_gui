import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String initialUrl;
  final Function(String) onUrlChanged;
  final List<String> availableModels;
  final String selectedModel;
  final Function(String) onModelChanged;

  const SettingsPage({
    Key? key,
    required this.initialUrl,
    required this.onUrlChanged,
    required this.availableModels,
    required this.selectedModel,
    required this.onModelChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _modelController = TextEditingController(text: widget.selectedModel);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Ollama URL',
              hintText: 'http://localhost:11434',
            ),
            onChanged: widget.onUrlChanged,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model Name',
              hintText: 'Enter model name',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onUrlChanged(_urlController.text);
            widget.onModelChanged(_modelController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    super.dispose();
  }
}
