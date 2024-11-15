import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding

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
  int _counter = 0; // This can be removed if not needed
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = []; // List to hold chat messages
  String _ollamaUrl = 'http://127.0.0.1:11434'; // Default Ollama URL

  void _sendMessage() async {
    final prompt = _controller.text;
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add('You: $prompt'); // Add user message to chat
    });

    try {
      // Send request to Ollama API
      final response = await http.post(
        Uri.parse('$_ollamaUrl/api/generate'), // Adjust endpoint as necessary
        headers: {'Content-Type': 'application/json'},
        body: json
            .encode({"model": "llama3.2", "prompt": prompt, "stream": true}),
      );

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
      setState(() {
        _messages.add('Error: $e'); // Display the error message
      });
    }

    _controller.clear(); // Clear the input field
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Logic to set Ollama URL and model can be added here
            },
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
