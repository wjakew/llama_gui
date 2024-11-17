import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String initialUrl;
  final Function(String) onUrlChanged;
  final List<String> availableModels; // List of available models
  final String selectedModel; // Currently selected model
  final Function(String) onModelChanged; // Callback for model change

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
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Ollama URL',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: widget.selectedModel,
            onChanged: (String? newValue) {
              if (newValue != null) {
                widget.onModelChanged(newValue); // Update the selected model
              }
            },
            items: widget.availableModels
                .map<DropdownMenuItem<String>>((String model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(model),
              );
            }).toList(),
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
