import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yona_app/services/services.dart';
import 'package:yona_app/screens/screens.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;
  bool _isDarkMode = true; 

  final List<Widget> _pages = [
    const ChatPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];


  bool get _isMobile => !kIsWeb && MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _loadTheme();

    ThemeService.addListener(() {
      _loadTheme();
    });
  }

  @override
  void dispose() {
    ThemeService.removeListener(() {
      _loadTheme();
    });
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color.fromARGB(255, 20, 24, 27)
          : Colors.grey[100],
      body: Row(
        children: [
          if (!_isMobile) ...[
            _buildNavigationRail(),
            Container(
              width: 1,
              color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
            ),
          ],

          Expanded(
            child: Stack(
              children: [
                _pages[_selectedIndex],

                if (_isMobile)
                  Positioned(
                    top:
                        MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    left: _selectedIndex == 2 ? null : 16,
                    right: _selectedIndex == 2 ? 16 : null,
                    child: FloatingActionButton.small(
                      backgroundColor:
                          _isDarkMode ? const Color(0xFF212836) : Colors.white,
                      foregroundColor:
                          _isDarkMode ? Colors.white : Colors.black87,
                      onPressed: () {
                        setState(() {
                          _isDrawerOpen = !_isDrawerOpen;
                        });
                      },
                      child: Icon(_isDrawerOpen ? Icons.close : Icons.menu),
                    ),
                  ),

                if (_isMobile && _isDrawerOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = false;
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
                    child: _buildMobileDrawer(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Column(
      children: [
        Expanded(
          child: NavigationRail(
            backgroundColor:
                _isDarkMode ? const Color(0xFF212836) : Colors.white,
            selectedIndex: _selectedIndex < 2 ? _selectedIndex : null,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
                if (_isMobile) _isDrawerOpen = false;
              });
            },
            labelType: NavigationRailLabelType.selected,
            useIndicator: false,
            indicatorColor: Colors.transparent,
            leading: const SizedBox(height: 12),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline,
                    color: _isDarkMode ? Colors.white70 : Colors.black54),
                selectedIcon:
                    const Icon(Icons.chat_bubble, color: Color(0xFF4CAF50)),
                label: const Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history,
                    color: _isDarkMode ? Colors.white70 : Colors.black54),
                selectedIcon:
                    const Icon(Icons.history, color: Color(0xFF4CAF50)),
                label: const Text('Historial'),
              ),
            ],
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        Container(
          width: 80,
          color: _isDarkMode ? const Color(0xFF212836) : Colors.white,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = 2;
                if (_isMobile) _isDrawerOpen = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectedIndex == 2
                        ? Icons.settings
                        : Icons.settings_outlined,
                    color: _selectedIndex == 2
                        ? const Color(0xFF4CAF50)
                        : (_isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ajustes',
                    style: TextStyle(
                      color: _selectedIndex == 2
                          ? const Color(0xFF4CAF50)
                          : (_isDarkMode ? Colors.white70 : Colors.black54),
                      fontWeight: _selectedIndex == 2
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileDrawer() {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF212836) : Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yona',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tu entrenador virtual',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Divider(
                color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
                height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMobileDrawerItem(
                    icon: Icons.chat_bubble_outline,
                    selectedIcon: Icons.chat_bubble,
                    title: 'Chat',
                    index: 0,
                  ),
                  _buildMobileDrawerItem(
                    icon: Icons.history,
                    selectedIcon: Icons.history,
                    title: 'Historial',
                    index: 1,
                  ),
                  _buildMobileDrawerItem(
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    title: 'Ajustes',
                    index: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawerItem({
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected
            ? const Color(0xFF4CAF50)
            : (_isDarkMode ? Colors.white70 : Colors.black54),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? const Color(0xFF4CAF50)
              : (_isDarkMode ? Colors.white70 : Colors.black54),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor:
          (_isDarkMode ? const Color(0xFF1A5D3A) : const Color(0xFF4CAF50))
              .withOpacity(0.3),
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _isDrawerOpen = false;
        });
      },
    );
  }
}