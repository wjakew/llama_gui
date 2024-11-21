import 'package:flutter/material.dart';

class PromptSettingsDialog extends StatelessWidget {
  final bool wholeConversation;
  final ValueChanged<bool> onWholeConversationChanged;

  const PromptSettingsDialog({
    Key? key,
    required this.wholeConversation,
    required this.onWholeConversationChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prompt Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Attach Whole Conversation'),
            value: wholeConversation,
            onChanged: (value) {
              if (value != null) {
                onWholeConversationChanged(value);
                Navigator.of(context).pop(); // Close the dialog
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
