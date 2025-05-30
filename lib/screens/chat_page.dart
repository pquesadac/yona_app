import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';

class ChatPage extends StatefulWidget {
  final String? conversationId;

  const ChatPage({Key? key, this.conversationId}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentConversationId;
  bool _isDarkMode = true;

  String get _lmStudioUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:1234/v1/chat/completions';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:1234/v1/chat/completions';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:1234/v1/chat/completions';
    } else {
      return 'http://127.0.0.1:1234/v1/chat/completions';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initializeChat();
    _debugPrintUrl();

    ThemeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ThemeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await ThemeService.getTheme();
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
    }
  }

  Future<void> _initializeChat() async {
    if (widget.conversationId != null) {
      _currentConversationId = widget.conversationId;
      _loadConversationMessages();
    } else {
      final latestId = await _chatService.getLatestConversationId();
      if (latestId != null) {
        _currentConversationId = latestId;
        _loadConversationMessages();
      }
    }
  }

  void _loadConversationMessages() {
    if (_currentConversationId == null) return;

    _chatService.getConversationMessages(_currentConversationId!).listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages);
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        print('Error al cargar mensajes: $error');
      },
    );
  }

  void _debugPrintUrl() {
    print('Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
    print('Using URL: $_lmStudioUrl');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para usar el chat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (_currentConversationId == null) {
        _currentConversationId =
            await _chatService.createNewConversation(userMessage);
        _loadConversationMessages();
      }

      final userMessageObj = ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      );

      await _chatService.saveMessage(_currentConversationId!, userMessageObj);

      setState(() {
        _isLoading = true;
        _messageController.clear();
      });

      _scrollToBottom();

      final response = await http.post(
        Uri.parse(_lmStudioUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'Access-Control-Allow-Origin': '*',
        },
        body: jsonEncode({
          'model': 'hermes-3-llama-3.2-3b',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''Eres un asistente virtual especializado en salud, nutrición y fitness que responde de manera clara, concisa y siempre en español.
              Proporciona información precisa y fácil de entender sobre ejercicios, rutinas deportivas, nutrición y hábitos saludables.
              IMPORTANTE: NO USES ETIQUETAS <think> NI MUESTRES TU PROCESO DE PENSAMIENTO.
              Estructura tus respuestas de forma directa y profesional.
              Usa exclusivamente terminología correcta en español relacionada con la nutrición y el fitness.
              Evita usar términos en inglés o expresiones incorrectas.
              Cuando uses viñetas, usa solo 3-4 puntos principales por sección.
              Para solicitudes de planes nutricionales, proporciona ejemplos específicos de alimentos y su valor nutricional aproximado.
              Para solicitudes de rutinas de ejercicio, menciona siempre la importancia del calentamiento y enfriamiento.
              Proporciona respuestas completas entre 150-300 palabras.
              Si el usuario hace preguntas simples o saludos, responde de forma cordial y profesional sin necesidad de una respuesta extensa.
              Nunca indiques que tu respuesta es incompleta, simplemente da la mejor respuesta posible.
              Siempre recuerda que no sustituyes a un profesional del deporte o nutricionista certificado.
              '''
            },
            ..._messages.map((msg) => {
                  'role': msg.isUser ? 'user' : 'assistant',
                  'content': msg.text,
                }),
          ],
          'temperature': 0.2,
          'max_tokens': 800,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var aiResponse = data['choices'][0]['message']['content'] as String;
        aiResponse = _cleanResponse(aiResponse);

        final aiMessageObj = ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );

        await _chatService.saveMessage(_currentConversationId!, aiMessageObj);

        setState(() {
          _isLoading = false;
        });
      } else {
        final errorMessage =
            'Error al conectar con LM Studio: ${response.statusCode}\n\nVerifica que el servidor esté ejecutándose.\nPlataforma: ${kIsWeb ? 'Web' : Platform.operatingSystem}\nURL: $_lmStudioUrl';

        final errorMessageObj = ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
        );

        await _chatService.saveMessage(
            _currentConversationId!, errorMessageObj);

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage =
          'Error: $e\n\nVerifica tu conexión y que el servidor esté activo.\nPlataforma: ${kIsWeb ? 'Web' : Platform.operatingSystem}\nURL: $_lmStudioUrl';

      try {
        if (_currentConversationId != null) {
          final errorMessageObj = ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
          );
          await _chatService.saveMessage(
              _currentConversationId!, errorMessageObj);
        }
      } catch (saveError) {
        print('Error al guardar mensaje de error: $saveError');
      }

      setState(() {
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _cleanResponse(String response) {
    response =
        response.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
    response = response.replaceAll('<think>', '');
    response = response.replaceAll('</think>', '');
    response = response.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    response = response.replaceAll(
        RegExp(
            r'\[La respuesta parece incompleta\. Por favor, reformula tu pregunta para obtener más detalles\.\]'),
        '');
    return response.trim();
  }

  Future<void> _startNewConversation() async {
    setState(() {
      _currentConversationId = null;
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color.fromARGB(255, 20, 24, 27)
          : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _isDarkMode ? const Color(0xFF212836) : Colors.white,
        title: Row(
          children: [
            Text(
              'Yona',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                kIsWeb ? 'Web' : Platform.operatingSystem,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: _isDarkMode ? 0 : 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_comment,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: _startNewConversation,
            tooltip: 'Nueva conversación',
          ),
          if (_currentConversationId != null)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor:
                          _isDarkMode ? const Color(0xFF212836) : Colors.white,
                      title: Text(
                        'Confirmar',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      content: Text(
                        '¿Deseas eliminar esta conversación?',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      actions: [
                        TextButton(
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () async {
                            if (_currentConversationId != null) {
                              await _chatService
                                  .deleteConversation(_currentConversationId!);
                              _startNewConversation();
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Eliminar conversación',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageItem(message);
                    },
                  ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/yonalogo.png',
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Tu entrenador personal virtual. Hazme cualquier pregunta sobre nutrición, ejercicios o estilo de vida saludable.',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _messageController.text =
                    '¿Puedes recomendarme una rutina de ejercicios para principiantes?';
                _sendMessage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5D3A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Rutina de ejercicios',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    bool isLongMessage = !message.isUser &&
        (message.text.length > 300 || message.text.split('\n').length > 6);

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF1A5D3A)
              : (_isDarkMode ? const Color(0xFF212836) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: !_isDarkMode && !message.isUser
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12.0),
        child: isLongMessage
            ? _ExpandableMessageText(
                messageText: message.text,
                isDarkMode: _isDarkMode,
              )
            : Text(
                message.text,
                style: TextStyle(
                  color: message.isUser
                      ? Colors.white
                      : (_isDarkMode ? Colors.white : Colors.black87),
                ),
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF212836) : Colors.white,
        border: Border(
          top: BorderSide(
            color: _isDarkMode ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        boxShadow: !_isDarkMode
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 16.0 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                hintStyle: TextStyle(
                  color: _isDarkMode ? Colors.white54 : Colors.black54,
                ),
                filled: true,
                fillColor:
                    _isDarkMode ? const Color(0xFF1E2730) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableMessageText extends StatefulWidget {
  final String messageText;
  final bool isDarkMode;

  const _ExpandableMessageText({
    required this.messageText,
    required this.isDarkMode,
  });

  @override
  State<_ExpandableMessageText> createState() => _ExpandableMessageTextState();
}

class _ExpandableMessageTextState extends State<_ExpandableMessageText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          _isExpanded
              ? widget.messageText
              : (widget.messageText.length > 150
                  ? '${widget.messageText.substring(0, 150)}...'
                  : widget.messageText),
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(
            _isExpanded ? 'Mostrar menos' : 'Ver mensaje completo',
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}