import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:yona_app/services/theme_service.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedOption = 'Perfil';
  bool _isMobileMenuOpen = false;
  bool _isDarkMode = true; 
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();


  bool get _isMobile => !kIsWeb && MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    
    ThemeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
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
    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color.fromARGB(255, 20, 24, 27)
          : Colors.grey[100],
      body: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [

        Container(
          padding:
              const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
          color: _isDarkMode ? const Color(0xFF212836) : Colors.white,
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isMobileMenuOpen = !_isMobileMenuOpen;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isMobileMenuOpen ? Icons.close : Icons.menu,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Ajustes',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),


        Expanded(
          child: Stack(
            children: [

              _getSettingsContent(),


              if (_isMobileMenuOpen) ...[

                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isMobileMenuOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.black54,
                    ),
                  ),
                ),
                
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildMobileSettingsMenu(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSettingsMenu() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color:
            _isDarkMode ? const Color.fromARGB(255, 20, 24, 27) : Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Opciones',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildMenuOption('Perfil', Icons.person_outline),
          _buildMenuOption('Apariencia', Icons.color_lens_outlined),
          _buildMenuOption('Cambiar Contraseña', Icons.lock_reset_outlined),
          const Divider(color: Colors.grey),
          _buildLogoutOption(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? const Color.fromARGB(255, 20, 24, 27)
                : Colors.white,
            border: Border(
              right: BorderSide(
                color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 24.0),
                  child: Text(
                    'Ajustes',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildMenuOption('Perfil', Icons.person_outline),
                _buildMenuOption('Apariencia', Icons.color_lens_outlined),
                _buildMenuOption(
                    'Cambiar Contraseña', Icons.lock_reset_outlined),
                const SizedBox(height: 20),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),
                _buildLogoutOption(),
              ],
            ),
          ),
        ),

        Expanded(
          child: _getSettingsContent(),
        ),
      ],
    );
  }

  Widget _buildMenuOption(String title, IconData icon) {
    bool isSelected = _selectedOption == title;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (_isDarkMode ? const Color(0xFF212836) : Colors.grey.shade200)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF4CAF50)
              : (_isDarkMode ? Colors.white70 : Colors.black54),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : (_isDarkMode ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedOption = title;
            if (_isMobile) _isMobileMenuOpen = false;
          });
        },
      ),
    );
  }

  Widget _buildLogoutOption() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.logout,
          color: Colors.red,
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          if (_isMobile) {
            setState(() {
              _isMobileMenuOpen = false;
            });
          }
          _showLogoutDialog();
        },
      ),
    );
  }

  Widget _getSettingsContent() {
    switch (_selectedOption) {
      case 'Perfil':
        return _buildProfileContent();
      case 'Apariencia':
        return _buildAppearanceContent();
      case 'Cambiar Contraseña':
        return _buildPasswordChangeContent();




      default:
        return _buildProfileContent();
    }
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF212836) : Colors.white,
          title: Text(
            'Cerrar sesión',
            style:
                TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style:
                TextStyle(color: _isDarkMode ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                _logout(); 
              },
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(

            'Nombre completo',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: 'Pablo Quesada',
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  _isDarkMode ? const Color(0xFF212836) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style:
                TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 24),
          Text(

            'Nombre de usuario',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: 'Pablo',
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  _isDarkMode ? const Color(0xFF212836) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style:
                TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 24),
          Text(

            '¿Qué descripción se ajusta mejor a su trabajo?',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color:
                  _isDarkMode ? const Color(0xFF212836) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: null,
              hint: Text(
                'Seleccione su puesto de trabajo',
                style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54),
              ),
              dropdownColor:
                  _isDarkMode ? const Color(0xFF212836) : Colors.white,
              style:
                  TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'estudiante',
                  child: Text('Estudiante'),
                ),
                DropdownMenuItem(
                  value: 'empleado',
                  child: Text('Empleado'),
                ),
                DropdownMenuItem(
                  value: 'emprendedor',
                  child: Text('Emprendedor'),
                ),
                DropdownMenuItem(
                  value: 'freelancer',
                  child: Text('Freelancer'),
                ),
                DropdownMenuItem(
                  value: 'jubilado',
                  child: Text('Jubilado'),
                ),
                DropdownMenuItem(
                  value: 'otro',
                  child: Text('Otro'),
                ),
              ],
              onChanged: (value) {},
            ),
          ),

          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Más información sobre las preferencias',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Tema de la aplicación',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  _isDarkMode ? const Color(0xFF212836) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF4CAF50),
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isDarkMode ? 'Modo Oscuro' : 'Modo Claro',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isDarkMode
                            ? 'La interfaz usa colores oscuros'
                            : 'La interfaz usa colores claros',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (value) async {
                    setState(() {
                      _isDarkMode = value;
                    });
                    // Guardar y notificar el cambio de tema
                    await ThemeService.setTheme(value);
                  },
                  activeColor: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Vista previa',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color.fromARGB(255, 20, 24, 27)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejemplo de texto principal',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este es un ejemplo de cómo se ve el texto secundario en el tema seleccionado.',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Botón de ejemplo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChangeContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Cambiar Contraseña',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tu email para recibir un enlace de restablecimiento de contraseña.',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Email',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Ingresa tu email',
              hintStyle: TextStyle(
                  color: _isDarkMode ? Colors.white54 : Colors.black38),
              filled: true,
              fillColor:
                  _isDarkMode ? const Color(0xFF212836) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style:
                TextStyle(color: _isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _resetPassword,
              icon: const Icon(
                Icons.email_outlined,
                color: Colors.white,
              ),
              label: const Text(
                'Enviar enlace de restablecimiento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF1A5D3A).withOpacity(0.2)
                  : const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4CAF50),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recibirás un email con instrucciones para crear una nueva contraseña.',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar('Por favor ingresa tu email');
      return;
    }

    try {
      await _authService.resetPassword(email);
      _showSuccessSnackBar(
          'Se ha enviado un email para restablecer tu contraseña');
      _emailController.clear();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),






        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF1A5D3A),
          duration: const Duration(seconds: 2),
        ),
      );



    }
  }
}