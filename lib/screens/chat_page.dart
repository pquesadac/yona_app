import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:convert';
import 'dart:io'; 
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

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
  
  // URLs para diferentes plataformas
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
    _initializeChat();
    _debugPrintUrl();
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
        print('❌ CHAT: Error al cargar mensajes: $error');
      },
    );
  }

  void _debugPrintUrl() {
    print('Platform: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
    print('Using URL: $_lmStudioUrl');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        _currentConversationId = await _chatService.createNewConversation(userMessage);
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
              'content': '''Eres un asistente virtual especializado en salud, nutrición y fitness que responde de manera clara, concisa y siempre en español.
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
        final errorMessage = 'Error al conectar con LM Studio: ${response.statusCode}\n\nVerifica que el servidor esté ejecutándose.\nPlataforma: ${kIsWeb ? 'Web' : Platform.operatingSystem}\nURL: $_lmStudioUrl';
        
        final errorMessageObj = ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
        );

        await _chatService.saveMessage(_currentConversationId!, errorMessageObj);
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      final errorMessage = 'Error de conexión con LM Studio: $e\n\nVerifica tu conexión y que el servidor esté activo.\nPlataforma: ${kIsWeb ? 'Web' : Platform.operatingSystem}\nURL: $_lmStudioUrl\n\nSi usas Android emulador, asegúrate de que LM Studio esté configurado para aceptar conexiones desde 10.0.2.2';
      
      try {
        if (_currentConversationId != null) {
          final errorMessageObj = ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
          );
          await _chatService.saveMessage(_currentConversationId!, errorMessageObj);
        }
      } catch (saveError) {
        print('❌ Error al guardar mensaje de error: $saveError');
      }

      setState(() {
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _cleanResponse(String response) {
    response = response.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
    response = response.replaceAll('<think>', '');
    response = response.replaceAll('</think>', '');
    response = response.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    response = response.replaceAll(RegExp(r'\[La respuesta parece incompleta\. Por favor, reformula tu pregunta para obtener más detalles\.\]'), '');
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
      backgroundColor: const Color.fromARGB(255, 20, 24, 27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212836),
        title: Row(
          children: [
            const Text(
              'Yona',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                kIsWeb ? 'Web' : Platform.operatingSystem,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment, color: Colors.white),
            onPressed: _startNewConversation,
            tooltip: 'Nueva conversación',
          ),
          if (_currentConversationId != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF212836),
                      title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                      content: const Text('¿Deseas eliminar esta conversación?', 
                        style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            if (_currentConversationId != null) {
                              await _chatService.deleteConversation(_currentConversationId!);
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
                  'assets/images/yonalogo.png', 
                  height: 250,
                  width: 250,
                ),          
          const SizedBox(height: 5),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Tu entrenador personal virtual. Hazme cualquier pregunta sobre nutrición, ejercicios o estilo de vida saludable.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  _messageController.text = '¿Puedes recomendarme una rutina de ejercicios para principiantes?';
                  _sendMessage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5D3A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    bool isLongMessage = !message.isUser && 
                        (message.text.length > 300 || 
                         message.text.split('\n').length > 6);
    
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
              : const Color(0xFF212836),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12.0),
        child: isLongMessage
            ? _ExpandableMessageText(messageText: message.text)
            : Text(
                message.text,
                style: const TextStyle(color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF212836),
        border: Border(
          top: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe tu mensaje...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E2730),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: null,
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

  const _ExpandableMessageText({required this.messageText});

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
          style: const TextStyle(
            color: Colors.white,
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