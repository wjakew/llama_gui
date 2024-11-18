import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding
import 'terminal_emulator.dart'; // Import the terminal emulator logic
import 'dart:io'; // Import for Platform checks
import 'settings_page.dart'; // Import the settings page
import 'package:path_provider/path_provider.dart'; // Import for path provider
import 'package:file_picker/file_picker.dart'; // Import for file picker
import 'package:flutter/services.dart'; // Import for clipboard functionality

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true; // Set dark mode to default

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'altiplano',
      theme: _isDarkMode
          ? ThemeData.dark() // Use dark theme
          : ThemeData.light(), // Use light theme
      home: MyHomePage(
        title: 'altiplano',
        isDarkMode: _isDarkMode,
        onThemeChanged: (value) {
          setState(() {
            _isDarkMode = value; // Update the dark mode state
          });
        },
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final String title;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // Add scroll controller
  List<String> _messages = []; // List to hold chat messages
  String _ollamaUrl = 'http://localhost:11434'; // Default Ollama URL
  String _selectedModel = 'llama3.2'; // Default model
  List<String> _availableModels = []; // List to hold available models
  bool _isLoading = false; // Add loading state variable

  @override
  void initState() {
    super.initState();
    _fetchAvailableModels(); // Fetch available models on initialization
  }

  Future<void> _fetchAvailableModels() async {
    try {
      final response = await http
          .get(Uri.parse('$_ollamaUrl/api/tags'))
          .timeout(const Duration(seconds: 30)); // Added timeout of 30 seconds
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _availableModels = List<String>.from(
              data['models'].map((model) => model['name'])); // Extract names
        });
      } else {
        print('Failed to load models: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching models: $e');
      // Optionally set an empty list to prevent null errors
      setState(() {
        _availableModels = [];
      });
    }
  }

  void _scrollToBottom() {
    // Add small delay to ensure the list has updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final prompt = _controller.text;
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add('You: $prompt');
      _messages
          .add('Ollama: '); // Add empty Ollama message that will be updated
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final uri = Uri.parse('$_ollamaUrl/api/generate');
      final request = http.Request('POST', uri);
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        "model": _selectedModel,
        "prompt": prompt,
        "stream": true,
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        final stream = response.stream.transform(utf8.decoder);
        String currentResponse = '';

        await for (final chunk in stream) {
          // Split by newlines as each line is a separate JSON object
          for (final line in chunk.split('\n')) {
            if (line.isEmpty) continue;

            try {
              final data = json.decode(line);
              if (data['response'] != null) {
                currentResponse += data['response'];
                setState(() {
                  // Update the last message (Ollama's response)
                  _messages[_messages.length - 1] = 'Ollama: $currentResponse';
                });
                _scrollToBottom();
              }
            } catch (e) {
              print('Error parsing JSON: $e');
            }
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages[_messages.length - 1] =
              'Error: Unable to get response from Ollama';
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages[_messages.length - 1] = 'Error: ${e.toString()}';
        _isLoading = false;
      });
      _scrollToBottom();
    }

    _controller.clear();
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
          availableModels:
              _availableModels, // Pass available models to settings
          selectedModel: _selectedModel, // Pass selected model to settings
          onModelChanged: (newModel) {
            setState(() {
              _selectedModel = newModel; // Update the selected model
            });
          },
        );
      },
    );
  }

  Widget _buildMessageTile(String message) {
    // Check if the message is from Ollama
    bool isOllamaMessage = message.startsWith('Ollama:');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isOllamaMessage
                ? Colors.green
                : Colors.white, // Green border for Ollama messages
            width: 1.0, // Border width
          ),
          borderRadius: BorderRadius.circular(8.0), // Rounded corners
        ),
        child: ListTile(
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              message,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          trailing:
              isOllamaMessage // Add a copy button only for Ollama messages
                  ? IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message));
                      },
                    )
                  : null,
        ),
      ),
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
            message: 'Toggle Dark Mode', // Tooltip message for dark mode toggle
            child: IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: () {
                widget.onThemeChanged(!widget.isDarkMode); // Toggle dark mode
              },
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
                '$_ollamaUrl - $_selectedModel',
                style: const TextStyle(fontSize: 16),
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
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageTile(
                        _messages[index]); // Use the new message tile
                  },
                ),
                // Show loading indicator when _isLoading is true
                if (_isLoading)
                  Container(
                    color: Colors
                        .black54, // Background color for the loading overlay
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Waiting for response...',
                            style: TextStyle(
                              color: Colors.white, // Text color for visibility
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up the controller
    _controller.dispose();
    super.dispose();
  }
}
