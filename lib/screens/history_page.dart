import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import 'chat_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ChatService _chatService = ChatService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    
    ThemeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
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
@override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return _buildNotAuthenticatedState();
    }

    return Scaffold(
      backgroundColor: _isDarkMode 
          ? const Color.fromARGB(255, 20, 24, 27) 
          : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _isDarkMode 
            ? const Color(0xFF212836) 
            : Colors.white,
        title: Text(
          'Historial de Conversaciones',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: _isDarkMode ? 0 : 1,
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _chatService.getUserConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return _buildConversationsList(conversations);
        },
      ),
    );
  }

  Widget _buildNotAuthenticatedState() {
    return Scaffold(
      backgroundColor: _isDarkMode 
          ? const Color.fromARGB(255, 20, 24, 27) 
          : Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.login,
              size: 100,
              color: Color(0xFF4CAF50),
            ),
            const SizedBox(height: 24),
            Text(
              'Inicia Sesión',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Debes iniciar sesión para ver tu historial',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 100,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            'Error',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Error al cargar conversaciones: $error',
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
              setState(() {}); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),



          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 100,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin Conversaciones',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Aún no has iniciado ninguna conversación.\n¡Ve al chat y comienza a hablar con Yona!',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.chat),
            label: const Text('Ir al Chat'),



          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(List<Conversation> conversations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationCard(conversation);
      },
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    return Card(
      color: _isDarkMode 
          ? const Color(0xFF212836) 
          : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: _isDarkMode ? 0 : 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.chat_bubble,
            color: Color(0xFF4CAF50),
          ),
        ),
        title: Text(
          conversation.title,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${conversation.messageCount} mensajes',
              style: TextStyle(
                color: _isDarkMode ? Colors.white54 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(conversation.lastMessage),
              style: TextStyle(
                color: _isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert, 
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
          color: _isDarkMode 
              ? const Color(0xFF2A3441) 
              : Colors.white,
          onSelected: (value) => _handleMenuAction(value, conversation),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new, 
                    color: _isDarkMode ? Colors.white : Colors.black87, 
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Abrir', 
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(
                    Icons.edit, 
                    color: _isDarkMode ? Colors.white : Colors.black87, 
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Renombrar', 
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  void _handleMenuAction(String action, Conversation conversation) {
    switch (action) {
      case 'open':
        _openConversation(conversation);
        break;
      case 'rename':
        _showRenameDialog(conversation);
        break;
      case 'delete':
        _showDeleteDialog(conversation);
        break;
    }
  }

  void _openConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(conversationId: conversation.id),
      ),
    );
  }

  void _showRenameDialog(Conversation conversation) {
    final TextEditingController controller = TextEditingController(text: conversation.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode 
            ? const Color(0xFF212836) 
            : Colors.white,
        title: Text(
          'Renombrar Conversación', 
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Nuevo nombre...',
            hintStyle: TextStyle(
              color: _isDarkMode ? Colors.white54 : Colors.black54,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF4CAF50)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF4CAF50)),
            ),
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar', 
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != conversation.title) {
                try {
                  await _chatService.renameConversation(conversation.id, newTitle);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Conversación renombrada'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Guardar', 
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode 
            ? const Color(0xFF212836) 
            : Colors.white,
        title: Text(
          'Eliminar Conversación', 
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${conversation.title}"?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar', 
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _chatService.deleteConversation(conversation.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversación eliminada'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar', 
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}