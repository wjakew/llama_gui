import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding
import 'terminal_emulator.dart'; // Import the terminal emulator logic
import 'dart:io'; // Import for Platform checks
import 'settings_page.dart'; // Import the settings page
import 'package:path_provider/path_provider.dart'; // Import for path provider
import 'package:file_picker/file_picker.dart'; // Import for file picker

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llama GUI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'llama_gui'),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = []; // List to hold chat messages
  String _ollamaUrl = 'http://localhost:11434'; // Default Ollama URL

  void _sendMessage() async {
    final prompt = _controller.text;
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add('You: $prompt'); // Add user message to chat
    });

    try {
      // Construct the URL
      final uri = Uri.parse(_ollamaUrl + '/api/generate');
      print('Sending request to: $uri'); // Print the URI to the console

      // Prepare the request body
      final requestBody = json.encode({
        "model": "llama3.2",
        "prompt": prompt,
        "stream": false,
      });

      // Send request to Ollama API with a timeout
      final response = await http
          .post(
            uri, // Use the constructed URI
            headers: {'Content-Type': 'application/json'},
            body: requestBody, // Use the prepared request body
          )
          .timeout(const Duration(seconds: 60)); // Set timeout duration here

      print('Response status: ${response.statusCode}'); // Log response status
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add('Ollama: ${data['response']}'); // Add response to chat
        });
      } else {
        setState(() {
          _messages.add('Error: Unable to get response from Ollama');
        });
      }
    } catch (e) {
      // Show the full error message in the chat
      setState(() {
        _messages
            .add('Error: ${e.toString()}'); // Display the full error message
      });
    }

    _controller.clear(); // Clear the input field
  }

  void _clearChat() {
    setState(() {
      _messages.clear(); // Clear the chat messages
    });
  }

  Future<void> _exportChat() async {
    // Convert messages to JSON
    final chatJson = json.encode(_messages);

    // Use file picker to select the location to save the file
    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Chat Export',
      fileName: 'chat_export.json',
    );

    if (filePath != null) {
      // Write the JSON to the selected file
      final file = File(filePath);
      await file.writeAsString(chatJson);

      // Show a dialog to inform the user
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Export Successful'),
            content: Text('Chat exported to: $filePath'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  void _closeWindow() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0); // Close the application
    }
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return SettingsPage(
          initialUrl: _ollamaUrl,
          onUrlChanged: (newUrl) {
            setState(() {
              _ollamaUrl = newUrl; // Update the Ollama URL
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Tooltip(
            message: 'Export Chat', // Tooltip message for export chat
            child: IconButton(
              icon: const Icon(Icons.save_alt), // Export icon
              onPressed: _exportChat, // Export chat messages
            ),
          ),
          Tooltip(
            message: 'Clear Chat', // Tooltip message for clear chat
            child: IconButton(
              icon: const Icon(Icons.delete), // Clear icon
              onPressed: _clearChat, // Clear chat messages
            ),
          ),
          Tooltip(
            message: 'Settings', // Tooltip message for settings
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings, // Open settings window
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                _ollamaUrl,
                style:
                    const TextStyle(fontSize: 16), // Adjust font size as needed
              ),
            ),
          ),
          Tooltip(
            message: 'Open terminal', // Tooltip message for terminal
            child: IconButton(
              icon: const Icon(Icons.terminal),
              onPressed: () {
                TerminalEmulator.openTerminal(
                    context); // Open terminal emulator
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closeWindow, // Close window
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter your prompt',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
