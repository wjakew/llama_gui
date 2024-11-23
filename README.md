# altiplano

![altiplano logo](readme_src/logo.png)

A Flutter desktop application that provides a modern chat interface for local Ollama models, featuring real-time streaming responses, customizable settings, and chat history management.

![Llama GUI Screenshot](readme_src/image.png)

## Features

- Real-time streaming responses from Ollama models
- Support for multiple Ollama models with easy switching
- Chat history management with export/import capabilities
- Customizable settings including dark/light theme
- System prompt customization and context control
- Built-in terminal emulator for model management
- Chat saving and loading functionality
- Message copying and conversation export

## Requirements

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Ollama installed and running locally
- Supported platforms: Windows, macOS, Linux

## Installation

### From Source

1. **Install Ollama**
   Follow the installation instructions at [Ollama.ai](https://ollama.ai)

2. **Download Altiplano**
   ```bash
   git clone https://github.com/yourusername/altiplano.git
   cd altiplano
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the Application**
   ```bash
   flutter run
   ```
5. **Build the Application**
   ```bash
   flutter build windows
   ```
   or 
   ```bash
   flutter pub run msix:create
   ```
   to build the windows installer.

### From Release

- Windows:
  - Download the latest release from the [Releases](https://github.com/yourusername/altiplano/releases) page.
  - Extract the zip file, and run command `Add-AppPackage -Path ".\altiplano.msix" -AllowUnsigned` - the current release is not signed.
- MacOS:
  - Download the latest release from the [Releases](https://github.com/yourusername/altiplano/releases) page.
  - Extract the zip file, and copy the app to the Applications folder.


## Configuration

1. **Server Settings**
   - Default URL: `http://127.0.0.1:11434`
   - For emulators: Use `10.0.2.2` instead of `127.0.0.1`

2. **Model Settings**
   - Type the name of any installed Ollama model

## Usage

### Basic Chat
1. Select your preferred model from the dropdown
2. Type your message in the input field
3. Press Enter or click Send
4. View real-time streaming responses

### Advanced Features
- **Export**: Save chat history as JSON via the menu
- **Theme**: Toggle dark/light mode using the theme switch
- **Copy**: Click the copy icon on any message to copy its content

## Troubleshooting

### Common Issues
- **Connection Failed**: Verify Ollama is running (`ollama serve`)
- **Model Not Found**: Ensure model is installed (`ollama pull modelname`)
- **Slow Responses**: Check system resources and model requirements

### Logs
- Application logs are available in the console when running in debug mode
- Server logs can be found in the Ollama output

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Powered by [Ollama](https://ollama.ai/)
- Icons from [Material Design Icons](https://materialdesignicons.com/)