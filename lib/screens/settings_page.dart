import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedOption = 'Perfil';
  bool _isMobileMenuOpen = false;

  // Determinar si es móvil
  bool get _isMobile => !kIsWeb && MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 20, 24, 27),
      body: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Header móvil con título y botón de menú INTERNO (posición modificada)
        Container(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 16),
          color: const Color(0xFF212836),
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
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isMobileMenuOpen ? Icons.close : Icons.menu,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Ajustes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Contenido
        Expanded(
          child: Stack(
            children: [
              // Contenido principal de ajustes
              _getSettingsContent(),
              
              // Menú lateral móvil INTERNO de ajustes
              if (_isMobileMenuOpen) ...[
                // Overlay
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
                // Menú interno de ajustes
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
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 20, 24, 27),
        boxShadow: [
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
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Opciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildMenuOption('Perfil', Icons.person_outline),
          _buildMenuOption('Apariencia', Icons.color_lens_outlined),
          _buildMenuOption('Cuenta', Icons.account_circle_outlined),
          _buildMenuOption('Privacidad', Icons.lock_outline),
          _buildMenuOption('Facturación', Icons.payment_outlined),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 20, 24, 27),
            border: Border(
              right: BorderSide(
                color: Colors.white24,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 24.0),
                  child: Text(
                    'Ajustes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildMenuOption('Perfil', Icons.person_outline),
                _buildMenuOption('Apariencia', Icons.color_lens_outlined),
                _buildMenuOption('Cuenta', Icons.account_circle_outlined),
                _buildMenuOption('Privacidad', Icons.lock_outline),
                _buildMenuOption('Facturación', Icons.payment_outlined),
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
        color: isSelected ? const Color(0xFF212836) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF4CAF50) : Colors.white70,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
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

  Widget _getSettingsContent() {
    switch (_selectedOption) {
      case 'Perfil':
        return _buildProfileContent();
      case 'Apariencia':
        return _buildPlaceholderContent('Apariencia');
      case 'Cuenta':
        return _buildPlaceholderContent('Cuenta');
      case 'Privacidad':
        return _buildPlaceholderContent('Privacidad');
      case 'Facturación':
        return _buildPlaceholderContent('Facturación');
      default:
        return _buildProfileContent();
    }
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          const Text(
            'Nombre completo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: 'Pablo Quesada',
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF212836),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),

          const Text(
            'Nombre de usuario',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: 'Pablo',
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF212836),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 24),

          const Text(
            '¿Qué descripción se ajusta mejor a su trabajo?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF212836),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: null,
              hint: const Text(
                'Seleccione su puesto de trabajo',
                style: TextStyle(color: Colors.white70),
              ),
              dropdownColor: const Color(0xFF212836),
              style: const TextStyle(color: Colors.white),
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

  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_isMobile ? 16.0 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForTitle(title),
              size: _isMobile ? 80 : 100,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: _isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Próximamente: Implementación de $title',
              style: TextStyle(
                color: Colors.white70,
                fontSize: _isMobile ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Apariencia':
        return Icons.color_lens_outlined;
      case 'Cuenta':
        return Icons.account_circle_outlined;
      case 'Privacidad':
        return Icons.lock_outline;
      case 'Facturación':
        return Icons.payment_outlined;
      case 'Configuracion IA':
        return Icons.code_outlined;
      default:
        return Icons.settings;
    }
  }
}