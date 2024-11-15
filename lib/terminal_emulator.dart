import 'package:flutter/material.dart';
import 'package:process_run/process_run.dart';
import 'dart:io'; // Import for Platform checks

class TerminalEmulator {
  static Future<void> openTerminal(BuildContext context) async {
    // Logic to open the default system terminal
    try {
      if (Platform.isWindows) {
        // For Windows, use 'start cmd'
        await run('cmd', ['/c', 'start', 'cmd']);
      } else if (Platform.isMacOS) {
        // For macOS, use 'open -a Terminal'
        await run('open', ['-a', 'Terminal']);
      } else if (Platform.isLinux) {
        // For Linux, use 'gnome-terminal' or 'xterm' (you can adjust based on your default terminal)
        await run('gnome-terminal', []);
      } else {
        throw UnsupportedError('This platform is not supported');
      }
    } catch (e) {
      // Handle any errors that occur while trying to open the terminal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening terminal: $e')),
      );
    }
  }
}
