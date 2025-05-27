import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el usuario actual
  User? get currentUser {
    final user = _auth.currentUser;
    print('🔍 AUTH_SERVICE: currentUser = ${user?.uid}');
    return user;
  }

  // Stream para escuchar cambios en el estado de autenticación con debug
  Stream<User?> get authStateChanges {
    print('Creando stream authStateChanges');
    return _auth.authStateChanges().map((User? user) {
      print('authStateChanges detectó cambio: ${user?.uid}');
      return user;
    });
  }

  // Registro usuario 
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      print('Iniciando para $email');
      
      // Crear usuario en Firebase Auth con timeout
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw 'Timeout: Registro tardó demasiado. Verifica tu conexión.',
      );

      print('Usuario creado en Auth - UID: ${result.user?.uid}');

      User? user = result.user;
      if (user != null) {
        print('Guardando datos en Firestore...');
        
        // Intentar guardar en Firestore con reintentos
        await _saveUserToFirestore(user, username, email);
        
        await user.updateDisplayName(username).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Timeout al actualizar displayName');
          },
        );

        print('Proceso completado exitosamente');
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException - ${e.code}: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error inesperado: $e');
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        throw 'Conexión lenta. Verifica tu internet e intenta de nuevo.';
      }
      throw 'Error inesperado: ${e.toString()}';
    }
  }

  // Método auxiliar para guardar usuario en Firestore con reintentos
  Future<void> _saveUserToFirestore(User user, String username, String email) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        print('Intento $attempt de guardar datos...');
        
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username.trim(),
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 15));

        print('Datos guardados exitosamente');
        return; 
        
      } catch (e) {
        print('Error en intento $attempt: $e');
        
        if (attempt == 3) {
          if (e.toString().contains('permission-denied')) {
            throw 'Error de permisos. Contacta al administrador.';
          } else if (e.toString().contains('timeout')) {
            throw 'Timeout al guardar datos. Verifica tu conexión.';
          } else {
            throw 'Error al guardar datos del usuario: ${e.toString()}';
          }
        }
        
        await Future.delayed(Duration(seconds: attempt));
      }
    }
  }

  // Login con verificación y creación de documento si no existe
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Iniciando para $email');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw 'Timeout: Login tardó demasiado. Verifica tu conexión.',
      );

      print('Exitoso - UID: ${result.user?.uid}');

      // Verificar y crear documento si no existe
      if (result.user != null) {
        await _ensureUserDocumentExists(result.user!);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException - ${e.code}: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Error inesperado: $e');
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        throw 'Conexión lenta. Verifica tu internet e intenta de nuevo.';
      }
      throw 'Error inesperado: ${e.toString()}';
    }
  }

  // Método para asegurar que el documento del usuario existe
  Future<void> _ensureUserDocumentExists(User user) async {
    try {
      print('Verificando documento para ${user.uid}');
      
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get().timeout(const Duration(seconds: 10));
      
      if (!docSnapshot.exists) {
        print('Documento no existe, creando...');
        
        await docRef.set({
          'uid': user.uid,
          'username': user.displayName ?? 'Usuario',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'recoveredAccount': true, 
        }).timeout(const Duration(seconds: 15));
        
        print('Documento creado exitosamente');
      } else {
        print('Documento existe, actualizando lastLogin...');
        
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 10));
        
        print('Actualizado correctamente');
      }
    } catch (e) {
      print('Error al verificar/crear documento: $e');
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(const Duration(seconds: 10));
      print('Sesión cerrada exitosamente');
    } catch (e) {
      print('Error al cerrar sesión: $e');
      throw 'Error al cerrar sesión';
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim()).timeout(
        const Duration(seconds: 15),
      );
      print('Email de restablecimiento enviado');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw 'Timeout al enviar email. Verifica tu conexión.';
      }
      throw 'Error al enviar email de restablecimiento';
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      print('Obteniendo datos para $uid');
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 10));
      
      if (doc.exists) {
        print('Datos encontrados');
        return doc.data() as Map<String, dynamic>?;
      } else {
        print('Documento no encontrado');
        
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid) {
          print('Creando documento faltante...');
          
          final userData = {
            'uid': uid,
            'username': currentUser.displayName ?? 'Usuario',
            'email': currentUser.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'recoveredAccount': true,
          };
          
          await _firestore.collection('users').doc(uid).set(userData);
          print('Documento creado');
          
          return userData;
        }
        
        return null;
      }
    } catch (e) {
      print('Error al obtener datos: $e');
      throw 'Error al obtener datos del usuario';
    }
  }

  // Método para reparar cuentas existentes 
  Future<void> repairUserDocument() async {
    final user = currentUser;
    if (user != null) {
      await _ensureUserDocumentExists(user);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'user-not-found':
        return 'No se encontró usuario con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email no válido';
      case 'user-disabled':
        return 'Cuenta deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'invalid-credential':
        return 'Credenciales no válidas';
      case 'permission-denied':
        return 'Sin permisos para esta operación';
      default:
        return 'Error: ${e.message ?? 'Error desconocido'}';
    }
  }
}