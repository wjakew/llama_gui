import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding
import 'terminal_emulator.dart'; // Import the terminal emulator logic
import 'dart:io'; // Import for Platform checks
import 'settings_page.dart'; // Import the settings page
import 'package:path_provider/path_provider.dart'; // Import for path provider
import 'package:file_picker/file_picker.dart'; // Import for file picker
import 'package:flutter/services.dart'; // Import for clipboard functionality
import 'prompt_settings_dialog.dart'; // Import the new dialog
import 'package:shared_preferences/shared_preferences.dart'; // Import for shared preferences

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
  final String _version = '1.2.0'; // Add version variable

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'altiplano',
      theme: ThemeData(
        fontFamily: 'GeistMono', // Set the default font family to GeistMono
        brightness: _isDarkMode
            ? Brightness.dark
            : Brightness.light, // Set brightness based on dark mode
        // You can customize other theme properties here if needed
      ),
      home: MyHomePage(
        title: 'altiplano', // Keep the main title
        isDarkMode: _isDarkMode,
        onThemeChanged: (value) {
          setState(() {
            _isDarkMode = value; // Update the dark mode state
          });
        },
        version: _version,
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
    required this.version,
  });

  final String title;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String version;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class ChatSession {
  String title; // Title of the chat session
  final List<String> messages; // List of messages in the chat session

  ChatSession({required this.title, required this.messages});

  // Convert ChatSession to JSON format
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'messages': messages,
    };
  }

  // Create a ChatSession from JSON format
  static ChatSession fromJson(Map<String, dynamic> json) {
    return ChatSession(
      title: json['title'],
      messages: List<String>.from(json['messages']),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller =
      TextEditingController(); // Controller for the text input
  final FocusNode _focusNode =
      FocusNode(); // Create a FocusNode for the text field
  final ScrollController _scrollController =
      ScrollController(); // Add scroll controller for the message list
  List<String> _messages = []; // List to hold chat messages
  String _ollamaUrl = 'http://localhost:11434'; // Default Ollama URL
  String _selectedModel = 'llama3.2'; // Default model
  List<String> _availableModels = []; // List to hold available models
  bool _isLoading = false; // Add loading state variable
  bool _wholeConversation = false; // Set to false by default
  List<ChatSession> _savedChats = []; // List to hold saved chat sessions
  bool _saveChatAfterClearing =
      false; // New variable to track saving chat after clearing
  String? _contextMessage; // New variable to hold the selected context message

  @override
  void initState() {
    super.initState();
    _fetchAvailableModels(); // Fetch available models on initialization
    _loadSavedChats(); // Load saved chats on initialization
  }

  // Fetch available models from the Ollama API
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

  // Load saved chat sessions from shared preferences
  Future<void> _loadSavedChats() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? chatData = prefs.getStringList('savedChats');
    if (chatData != null) {
      setState(() {
        _savedChats = chatData.map((data) {
          final json = jsonDecode(data);
          return ChatSession.fromJson(json);
        }).toList();
      });
    }
  }

  // Save the current chat session
  Future<void> _saveChat() async {
    // Create a deep copy of the messages
    final List<String> messagesCopy = List.from(_messages);

    final newChat = ChatSession(
        title: DateTime.now()
            .toLocal()
            .toString(), // Use current date and time as title
        messages: messagesCopy);
    setState(() {
      _savedChats.add(newChat);
    });
    final prefs = await SharedPreferences.getInstance();
    final List<String> chatData =
        _savedChats.map((chat) => jsonEncode(chat.toJson())).toList();
    await prefs.setStringList('savedChats', chatData);

    // Show notification that chat was saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chat saved successfully!')),
    );
  }

  // Scroll to the bottom of the message list
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

  // Send a message to the Ollama API
  void _sendMessage() async {
    final prompt = _controller.text;
    if (prompt.isEmpty) return;

    String finalPrompt = prompt; // Initialize finalPrompt with the user input

    // Check if wholeConversation is true and append the latest message
    if (_wholeConversation && _messages.isNotEmpty) {
      final latestMessage = _messages.last; // Get the latest message
      finalPrompt =
          "I'm referring to the following message as context: $latestMessage\n$prompt"; // Prepend the latest message
    }

    if (_contextMessage != null) {
      finalPrompt =
          "I'm referring to the following message as context: $_contextMessage\n$prompt"; // Prepend the context message
    }

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
        "prompt": finalPrompt, // Use finalPrompt instead of prompt
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
    _focusNode.requestFocus(); // Set focus back to the text field
  }

  // Clear the chat messages
  void _clearChat() {
    if (_messages.isNotEmpty && _saveChatAfterClearing) {
      // Check if there are messages to save
      _saveChat(); // Save chat before clearing
    }
    setState(() {
      _messages.clear(); // Clear the chat messages
    });

    // Show notification that chat was cleared
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chat cleared successfully!')),
    );
  }

  // Export the chat messages to a file
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

  // Close the application window
  void _closeWindow() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0); // Close the application
    }
  }

  // Open the settings dialog
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
          saveChatAfterClearing:
              _saveChatAfterClearing, // Pass the new variable
          onSaveChatAfterClearingChanged: (value) {
            setState(() {
              _saveChatAfterClearing = value ?? false; // Handle null case
            });
          },
        );
      },
    );
  }

  // Open the prompt settings dialog
  void _openPromptSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return PromptSettingsDialog(
          wholeConversation: _wholeConversation,
          onWholeConversationChanged: (value) {
            setState(() {
              _wholeConversation = value; // Update the whole conversation state
            });
          },
        );
      },
    );
  }

  // Open the saved chats dialog
  void _openSavedChats() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Saved Chats'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _savedChats.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_savedChats[index].title),
                  onTap: () {
                    // Load the selected chat into the main screen
                    setState(() {
                      _messages = List.from(
                          _savedChats[index].messages); // Load selected chat
                      _scrollToBottom(); // Scroll to the bottom to show the latest message
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit), // Edit button icon
                        onPressed: () {
                          _renameChatDialog(index); // Open rename dialog
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete), // Delete button icon
                        onPressed: () {
                          _deleteChat(index); // Call delete function
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Open a dialog to rename a saved chat
  void _renameChatDialog(int index) {
    final TextEditingController _renameController =
        TextEditingController(text: _savedChats[index].title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Chat'),
          content: TextField(
            controller: _renameController,
            decoration: const InputDecoration(hintText: 'Enter new chat name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _savedChats[index].title =
                      _renameController.text; // Update the chat title
                });
                _saveChatList(); // Save the updated chat list
                _loadSavedChats(); // Reload saved chats after renaming
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Save the updated list of saved chats to shared preferences
  Future<void> _saveChatList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> chatData =
        _savedChats.map((chat) => jsonEncode(chat.toJson())).toList();
    await prefs.setStringList('savedChats', chatData);
  }

  // Add this new method to handle selecting a message as context
  void _selectMessageAsContext(String message) {
    setState(() {
      _contextMessage = message; // Set the selected message as context
    });
  }

  // Add this new method to handle removing the context message
  void _removeContextMessage() {
    setState(() {
      _contextMessage = null; // Clear the context message
    });
  }

  // Build a message tile for displaying messages
  Widget _buildMessageTile(String message, {VoidCallback? onSelect}) {
    // Check if the message is from Ollama
    bool isOllamaMessage = message.startsWith('Ollama:');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: GestureDetector(
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOllamaMessage) // Add a copy button only for Ollama messages
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message));
                    },
                  ),
                // Add a pin button to set the message as context
                IconButton(
                  icon: const Icon(Icons.push_pin), // Pin icon
                  onPressed: () {
                    _selectMessageAsContext(
                        message); // Set the message as context
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add this new method to handle chat deletion with confirmation
  void _deleteChat(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this chat?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _savedChats.removeAt(index); // Remove the selected chat
                });
                _saveChatList(); // Save the updated chat list
                _loadSavedChats(); // Reload saved chats after deletion
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.title), // Main title
            const SizedBox(width: 8), // Add some spacing
            Text(
              'v${widget.version}', // Use widget.version instead of _version
              style: const TextStyle(fontSize: 12), // Smaller font size
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openSavedChats, // Open saved chats on menu button press
        ),
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
            message: 'Save Chat', // Tooltip message for save chat
            child: IconButton(
              icon: const Icon(Icons.save), // Save icon
              onPressed: _saveChat, // Save chat when pressed
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
        ],
      ),
      body: Column(
        children: [
          // Add a label for the selected context message if it exists
          if (_contextMessage != null)
            GestureDetector(
              onTap: _removeContextMessage, // Remove context on tap
              child: Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.blueAccent,
                child: Text(
                  'Using message as context: $_contextMessage',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageTile(
                      _messages[index],
                      onSelect: () => _selectMessageAsContext(
                          _messages[index]), // Pass the message to select
                    ); // Use the new message tile
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
                    focusNode: _focusNode, // Assign the FocusNode
                    decoration: InputDecoration(
                      hintText: _wholeConversation
                          ? 'Enter your prompt (context activated)'
                          : 'Enter your prompt',
                    ),
                    onSubmitted: (value) {
                      _sendMessage(); // Trigger send message on Enter
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings), // Settings button
                  onPressed: _openPromptSettings, // Open settings dialog
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
    _controller.dispose(); // Dispose of the text controller
    _focusNode.dispose(); // Dispose of the FocusNode
    super.dispose(); // Call the superclass dispose method
  }
}
