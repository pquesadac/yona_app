import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yona_app/firebase_options.dart';
import 'package:yona_app/services/auth_service.dart';
import 'screens/welcome_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yona',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 20, 24, 27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('ConnectionState = ${snapshot.connectionState}');
        print('HasData = ${snapshot.hasData}');
        print('User = ${snapshot.data?.uid}');
        print('Error = ${snapshot.error}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Esperando inicialización...');
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return const WelcomePage();
        }

        if (snapshot.hasData && snapshot.data != null) {
          print('Usuario autenticado, mostrando HomePage');
          return const HomePage();
        }

        print('Sin usuario, mostrando WelcomePage');
        return const WelcomePage();
      },
    );
  }
}