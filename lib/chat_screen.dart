import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(ChatApp());
}

bool waiting = false;

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _userInput = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late GenerativeModel model;

  final List<ChatMessage> _chatHistory = [
    ChatMessage(role: "user", message: "Hello."),
  ];

  final List<Message> _messages = [];
  bool _imageSelected = false;
  File? _selectedImage;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    const apiKey = "AIzaSyDYGrejkJKNsPxMHsWxSwpNFa_ABZa0hL4"; // Replace with your API key
    model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

    setState(() {
      _selectedImage = null;
      _imageSelected = false;
      _userInput.text = "";
    });
    startChatWithHistory();
  }

  Future<void> startChatWithHistory() async {
    final chat = model.startChat(history: _chatHistory.map((message) => Content.text(message.message)).toList());

    final response = await chat.sendMessage(Content.text(''));
    _addMessage(isUser: false, message: response.text);
  }

  Future<void> sendMessage() async {
    final text = _userInput.text.trim();
         setState(() {
            _userInput.clear();
         });

    if (_imageSelected && (text == null || text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter text with the image.'),
      ));
      return;
    }

    setState(() {
      if (_selectedImage != null) {
        _messages.add(Message(isUser: true, image: _selectedImage, message: text, date: DateTime.now(), waiting: false));
         _chatHistory.add(ChatMessage(role: "user", message: text ?? ""));
        _messages.add(Message(isUser: false, message: "loading", date: DateTime.now(), waiting: true));
        _imageSelected = false;
      } else if (text != null && text.isNotEmpty) {
        _messages.add(Message(isUser: true, message: text, date: DateTime.now(), waiting: false));
         _chatHistory.add(ChatMessage(role: "user", message: text ?? ""));
        _messages.add(Message(isUser: false, message: "loading...", date: DateTime.now(), waiting: true));
      }
      _scrollToBottom();
    });

    if (_selectedImage != null) {
      final bytes = await _selectedImage?.readAsBytes();
      if (bytes != null) {
        final content = Content.multi([TextPart(text), DataPart('image/jpeg', bytes)]);
        final chat = model.startChat(history: _chatHistory.map((msg) => Content.text(msg.message)).toList());
        final response = await chat.sendMessage(content);
         _chatHistory.add(ChatMessage(role: "model", message: response.text ?? ""));
        
        setState(() {
          _messages.removeLast(); // Remove the placeholder message
          _messages.add(Message(isUser: false, message: response.text, date: DateTime.now(), waiting: false));
          _selectedImage = null;
          _imageSelected = false;
        });
      }
    } else if (text != null && text.isNotEmpty) {
     
      final chat = model.startChat(history: _chatHistory.map((msg) => Content.text(msg.message)).toList());
      final response = await chat.sendMessage(Content.text(text));
       _chatHistory.add(ChatMessage(role: "model", message: response.text ?? ""));
      
      setState(() {
        _messages.removeLast(); // Remove the placeholder message
        _messages.add(Message(isUser: false, message: response.text, date: DateTime.now(), waiting: false));
      });
    }
    _scrollToBottom();
  }

  void _addMessage({required bool isUser, String? message}) {
    setState(() {
      _messages.add(Message(
        isUser: isUser,
        message: message,
        date: DateTime.now(),
      ));
       WidgetsBinding.instance?.addPostFrameCallback((_) {
    _scrollToBottom();
  });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageSelected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Screen'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return message.image != null
                    ? ImageMessage(message: message, context: context)
                    : TextMessage(message: message, context: context);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 15,
                  child: TextFormField(
                    controller: _userInput,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter text with the image.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      labelText: 'Enter Your Message',
                    ),
                  ),
                ),
                Spacer(),
                IconButton(
                  padding: EdgeInsets.all(12),
                  iconSize: 30,
                  onPressed: sendMessage,
                  icon: Icon(Icons.send),
                ),
                IconButton(
                  padding: EdgeInsets.all(12),
                  iconSize: 30,
                  onPressed: _pickImage,
                  icon: Icon(Icons.image),
                ),
              ],
            ),
          ),
          if (_imageSelected && _selectedImage != null) ...[
            SizedBox(height: 20),
            Image.file(
              _selectedImage!,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String role;
  final String message;

  ChatMessage({required this.role, required this.message});
}

class Message {
  final bool isUser;
  final String? message;
  final File? image;
  final DateTime date;
  bool waiting;

  Message({required this.isUser, this.message, this.image, required this.date, this.waiting = false});
  
  get key => null;
}

class TextMessage extends StatelessWidget {
  final Message message;
  final BuildContext context;

  const TextMessage({Key? key, required this.message, required this.context}) : super(key: key);

  List<InlineSpan> _formatMessage(String message) {
    final RegExp codeBlockRegex = RegExp(r'```(.*?)```', dotAll: true);
    final List<InlineSpan> spans = [];

    int lastMatchEnd = 0;
    final matches = codeBlockRegex.allMatches(message);

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          WidgetSpan(
            child: MarkdownBody(
              data: message.substring(lastMatchEnd, match.start),
            ),
          ),
        );
      }
      spans.add(
        WidgetSpan(
          child: Container(
            color: Colors.black54,
            padding: EdgeInsets.all(4),
           
           
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match.group(1)?.substring(0, match.group(1)?.indexOf('\n') ?? 0) ?? "",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  color: Colors.white,
                  onPressed: () => _copyToClipboard(
                    match.group(1)?.substring((match.group(1)?.indexOf('\n') ?? -1) + 1) ?? "",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      spans.add(
        WidgetSpan(
          child: Container(
            color: Colors.black,
            padding: EdgeInsets.all(4),
            
            child: Text(
              match.group(1)?.substring((match.group(1)?.indexOf('\n') ?? -1) + 1) ?? "",
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < message.length) {
      spans.add(
        WidgetSpan(
          child: MarkdownBody(
            data: message.substring(lastMatchEnd),
          ),
        ),
      );
    }

    return spans;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code copied to clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 15).copyWith(
        left: message.isUser ? 100 : 10,
        right: message.isUser ? 10 : 100,
      ),
      decoration: BoxDecoration(
        color: message.isUser ? Colors.blue : Colors.black45,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: message.isUser ? Radius.circular(10) : Radius.zero,
          topRight: Radius.circular(10),
          bottomRight: message.isUser ? Radius.zero : Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.waiting
            ? [
                Container(
                  child: JumpingDots(
                    innerPadding: 5,
                    radius: 5,
                    color: Colors.red,
                    verticalOffset: 5,
                    animationDuration: const Duration(milliseconds: 100),
                  ),
                ),
              ]
            : [
                GestureDetector(
                  onTap: () => {},
                  child: SelectableText.rich(
                     TextSpan(
                      style: TextStyle(fontSize: 16, color: message.isUser ? Colors.white : Colors.black),
                      children: _formatMessage(message.message!),
                    ),
                  ),
                ),
                Text(
                  '${message.date.hour}:${message.date.minute}',
                  style: TextStyle(fontSize: 10, color: message.isUser ? Colors.white70 : Colors.black54),
                ),
              ],
      ),
    );
  }
}


class ImageMessage extends StatelessWidget {
  final Message message;
  final BuildContext context;

  const ImageMessage({Key? key, required this.message, required this.context}) : super(key: key);

  List<InlineSpan> _formatMessage(String message) {
    final RegExp codeBlockRegex = RegExp(r'```(.*?)```', dotAll: true);
    final List<InlineSpan> spans = [];

    int lastMatchEnd = 0;
    final matches = codeBlockRegex.allMatches(message);

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          WidgetSpan(
            child: MarkdownBody(
              data: message.substring(lastMatchEnd, match.start),
            ),
          ),
        );
      }
      spans.add(
        WidgetSpan(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match.group(1)?.substring(0, match.group(1)?.indexOf('\n') ?? 0) ?? "",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  color: Colors.white,
                  onPressed: () => _copyToClipboard(
                    match.group(1)?.substring((match.group(1)?.indexOf('\n') ?? -1) + 1) ?? "",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      spans.add(
        WidgetSpan(
          child: Container(
            color: Colors.black,
            child: Text(
              match.group(1)?.substring((match.group(1)?.indexOf('\n') ?? -1) + 1) ?? "",
              style: TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < message.length) {
      spans.add(
        WidgetSpan(
          child: MarkdownBody(
            data: message.substring(lastMatchEnd),
          ),
        ),
      );
    }

    return spans;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code copied to clipboard'),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 15).copyWith(
        left: message.isUser ? 100 : 10,
        right: message.isUser ? 10 : 100,
      ),
      decoration: BoxDecoration(
        color: message.isUser ? Colors.blue : Colors.black45,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: message.isUser ? Radius.circular(10) : Radius.zero,
          topRight: Radius.circular(10),
          bottomRight: message.isUser ? Radius.zero : Radius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.file(
            message.image!,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
          if (message.message != null) ...[
            SizedBox(height: 10),
            Text(
              message.message!,
              style: TextStyle(fontSize: 16, color: message.isUser ? Colors.white : Colors.black),
            ),
          ],
          Text(
            '${message.date.hour}:${message.date.minute}',
            style: TextStyle(fontSize: 10, color: message.isUser ? Colors.white70 : Colors.black54),
          ),
        ],
      ),
    );
  }
}



