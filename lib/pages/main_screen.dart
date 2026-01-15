import 'package:flutter/material.dart';
import '../widgets/linear_icon.dart';
import 'home_page.dart';
import 'search_screen.dart';
import 'create_topic_page.dart';
import 'qr_scanner_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _searchQuery = ""; // Variável para guardar o texto da pesquisa

  // Função para mudar a aba quando se clica na barra de navegação
  void _onItemTapped(int index) {
    if (index == 3) {
      // Lógica do Scan (abre por cima)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // NOVA FUNÇÃO: Chamada pela HomePage quando dás Enter na pesquisa
  void _jumpToSearch(String query) {
    setState(() {
      _searchQuery = query; // Atualiza o texto
      _selectedIndex = 1;   // Muda forçadamente para a aba Search (Index 1)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definimos a lista de páginas aqui dentro para podermos passar
    // a função _jumpToSearch e a variável _searchQuery
    final List<Widget> pages = [
      // Index 0: Home agora recebe a função de callback
      HomePageWidget(onSearchSubmitted: _jumpToSearch),
      
      // Index 1: Search agora recebe o texto atualizado
      SearchScreen(initialQuery: _searchQuery),
      
      // Index 2: Create
      const CreateTopicPage(),
      
      // Index 3: Placeholder do Scan (vazio)
      const SizedBox(),
      
      // Index 4: Profile
      const ProfilePageWidget(isMainTab: true),
    ];

    return Scaffold(
      // IndexedStack preserva o estado das páginas
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFFFC751D),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: SvgIcon('home'),
            activeIcon: SvgIcon('home', color: const Color(0xFFFC751D)),
            label: "Home"
          ),
          BottomNavigationBarItem(
            icon: SvgIcon('search'),
            activeIcon: SvgIcon('search', color: const Color(0xFFFC751D)),
            label: "Search"
          ),
          BottomNavigationBarItem(
            icon: SvgIcon('add', size: 28),
            activeIcon: SvgIcon('add', size: 28, color: const Color(0xFFFC751D)),
            label: "Create"
          ),
          BottomNavigationBarItem(
            icon: SvgIcon('scan'),
            activeIcon: SvgIcon('scan', color: const Color(0xFFFC751D)),
            label: "Scan"
          ),
          BottomNavigationBarItem(
            icon: SvgIcon('profile'),
            activeIcon: SvgIcon('profile', color: const Color(0xFFFC751D)),
            label: "Profile"
          ),
        ],
      ),
    );
  }
}