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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // Variable to track dark mode state

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llama GUI',
      theme: _isDarkMode
          ? ThemeData.dark() // Use dark theme
          : ThemeData.light(), // Use light theme
      home: MyHomePage(
        title: 'llama_gui',
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
          .timeout(const Duration(seconds: 30)); // Added timeout of 10 seconds
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
      _isLoading = true;
    });
    _scrollToBottom(); // Scroll after user message

    try {
      // Construct the URL
      final uri = Uri.parse(_ollamaUrl + '/api/generate');
      print('Sending request to: $uri'); // Print the URI to the console

      // Prepare the request body
      final requestBody = json.encode({
        "model": _selectedModel, // Use the selected model
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
          _messages.add('Ollama: ${data['response']}');
          _isLoading = false;
        });
        _scrollToBottom(); // Scroll after response
      } else {
        setState(() {
          _messages.add('Error: Unable to get response from Ollama');
          _isLoading = false;
        });
        _scrollToBottom(); // Scroll after error
      }
    } catch (e) {
      setState(() {
        _messages.add('Error: ${e.toString()}');
        _isLoading = false;
      });
      _scrollToBottom(); // Scroll after error
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
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Waiting for response...'),
                      ],
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
