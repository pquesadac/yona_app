import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? conversationId;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.conversationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'conversationId': conversationId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      conversationId: map['conversationId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      conversationId: doc.reference.parent.parent?.id,
    );
  }
}

class Conversation {
  final String id;
  final String title;
  final DateTime lastMessage;
  final DateTime createdAt;
  final int messageCount;

  Conversation({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.createdAt,
    required this.messageCount,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      title: data['title'] ?? 'Conversación sin título',
      lastMessage: (data['lastMessage'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      messageCount: data['messageCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'lastMessage': Timestamp.fromDate(lastMessage),
      'createdAt': Timestamp.fromDate(createdAt),
      'messageCount': messageCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Crear nueva conversación
  Future<String> createNewConversation(String firstMessage) async {
    if (_currentUserId == null) throw 'Usuario no autenticado';

    try {
      print('Creando nueva conversación...');
      
      String title = firstMessage.length > 50 
          ? '${firstMessage.substring(0, 47)}...'
          : firstMessage;
      
      final conversationRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': FieldValue.serverTimestamp(),
        'messageCount': 0,
      });

      print('Conversación creada con ID: ${conversationRef.id}');
      return conversationRef.id;
    } catch (e) {
      print('Error al crear conversación: $e');
      throw 'Error al crear nueva conversación';
    }
  }

  Future<void> saveMessage(String conversationId, ChatMessage message) async {
    if (_currentUserId == null) throw 'Usuario no autenticado';

    try {
      final batch = _firestore.batch();

      final messageRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      batch.set(messageRef, message.toFirestore());

      final conversationRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .doc(conversationId);

      batch.update(conversationRef, {
        'lastMessage': FieldValue.serverTimestamp(),
        'messageCount': FieldValue.increment(1),
      });

      await batch.commit();
      print('Mensaje guardado en conversación $conversationId');
    } catch (e) {
      print('Error al guardar mensaje: $e');
      throw 'Error al guardar mensaje';
    }
  }

  Stream<List<Conversation>> getUserConversations() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('conversations')
        .orderBy('lastMessage', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }

  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

// Borrar conversacion
  Future<void> deleteConversation(String conversationId) async {
    if (_currentUserId == null) throw 'Usuario no autenticado';

    try {
      print('Eliminando conversación $conversationId...');
      
      final messagesQuery = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      final conversationRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .doc(conversationId);

      batch.delete(conversationRef);

      await batch.commit();
      print('Conversación eliminada exitosamente');
    } catch (e) {
      print('Error al eliminar conversación: $e');
      throw 'Error al eliminar conversación';
    }
  }

  //Renombrar conversacion
  Future<void> renameConversation(String conversationId, String newTitle) async {
    if (_currentUserId == null) throw 'Usuario no autenticado';

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .doc(conversationId)
          .update({
        'title': newTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Conversación renombrada a: $newTitle');
    } catch (e) {
      print('Error al renombrar conversación: $e');
      throw 'Error al renombrar conversación';
    }
  }

  // Limpiar todas las conversaciones del usuario (para logout)
  Future<void> clearUserConversations() async {
    if (_currentUserId == null) return;

    try {
      print('Limpiando conversaciones del usuario...');
      
      final conversationsQuery = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .get();

      final batch = _firestore.batch();

      for (final conversationDoc in conversationsQuery.docs) {
        // Eliminar mensajes de cada conversación
        final messagesQuery = await conversationDoc.reference
            .collection('messages')
            .get();

        for (final messageDoc in messagesQuery.docs) {
          batch.delete(messageDoc.reference);
        }

        // Eliminar conversación 
        batch.delete(conversationDoc.reference);
      }

      await batch.commit();
      print('Conversaciones limpiadas exitosamente');
    } catch (e) {
      print('Error al limpiar conversaciones: $e');
    }
  }

  // Obtener la conversación más reciente
  Future<String?> getLatestConversationId() async {
    if (_currentUserId == null) return null;

    try {
      final query = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('conversations')
          .orderBy('lastMessage', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error al obtener última conversación: $e');
      return null;
    }
  }
}