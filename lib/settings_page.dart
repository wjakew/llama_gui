import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final String initialUrl;
  final ValueChanged<String> onUrlChanged;
  final List<String> availableModels;
  final String selectedModel;
  final ValueChanged<String> onModelChanged;
  final bool saveChatAfterClearing;
  final ValueChanged<bool?> onSaveChatAfterClearingChanged;

  const SettingsPage({
    Key? key,
    required this.initialUrl,
    required this.onUrlChanged,
    required this.availableModels,
    required this.selectedModel,
    required this.onModelChanged,
    required this.saveChatAfterClearing,
    required this.onSaveChatAfterClearingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(hintText: 'Enter Ollama URL'),
            onChanged: onUrlChanged,
            controller: TextEditingController(text: initialUrl),
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Model Name',
              hintText: 'Enter model name',
            ),
            onChanged: onModelChanged,
            controller: TextEditingController(text: selectedModel),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Save chat after clearing'),
              Checkbox(
                value: saveChatAfterClearing,
                onChanged: onSaveChatAfterClearingChanged,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
