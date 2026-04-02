import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'character_card.dart';
import 'favorite_service.dart';
import 'favourites_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('characters_cache');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ApiService apiService = ApiService();
  bool isDarkMode = true; 

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick and Morty',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF00B5CC),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00B5CC),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: Colors.black54, fontSize: 13),
          bodySmall: TextStyle(color: Colors.black45, fontSize: 12),
        ),
        cardColor: Colors.white,  
      ),
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00B5CC),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
          bodySmall: TextStyle(color: Color(0xFF777777), fontSize: 12),
        ),
        cardColor: const Color(0xFF1E1E1E),  
      ),
      
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: MainPage(apiService: apiService, onToggleTheme: toggleTheme),
    );
  }
}

class MainPage extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onToggleTheme;

  const MainPage({super.key, required this.apiService, required this.onToggleTheme});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  String _sortBy = 'name';      
  bool _sortAscending = true; 
  List<dynamic> allCharacters = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;

  final ScrollController _scrollController = ScrollController();
  
  Set<int> favoriteIds = {};
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    loadCharacters();
    _loadFavorites();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        loadCharacters(isLoadMore: true);
      }
    });
  }

  List<dynamic> _getSortedCharacters() {
    List<dynamic> sortedList = List.from(allCharacters);
    
    sortedList.sort((a, b) {
      int result;
      
      switch (_sortBy) {
        case 'name':
          result = a['name'].toString().compareTo(b['name'].toString());
          break;
        case 'status':
          result = a['status'].toString().compareTo(b['status'].toString());
          break;
        case 'species':
          result = a['species'].toString().compareTo(b['species'].toString());
          break;
        default:
          result = 0;
      }
      
      return _sortAscending ? result : -result;
    });
    
    return sortedList;
  }

  Future<void> loadCharacters({bool isLoadMore = false}) async {
    if (!hasMore || isLoading) return;
    
    setState(() {
      isLoading = true;
      if (!isLoadMore) {
        allCharacters.clear();
        currentPage = 1;
        hasMore = true;
      }
      errorMessage = null;
    });
    
    try {
      final data = await widget.apiService.getCharacters(currentPage);
      final newCharacters = data['results'];
      final info = data['info'];
      
      setState(() {
        allCharacters.addAll(newCharacters);
        hasMore = info['next'] != null;
        currentPage++;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final ids = await _favoritesService.loadFavorites();
    setState(() {
      favoriteIds = ids.toSet();
    });
  }

  Future<void> _toggleFavorite(int characterId) async {
    Set<int> newFavorites = Set.from(favoriteIds);
    
    if (newFavorites.contains(characterId)) {
      newFavorites.remove(characterId);
    } else {
      newFavorites.add(characterId);
    }
    
    setState(() {
      favoriteIds = newFavorites;
    });
    
    await _favoritesService.saveFavorites(newFavorites.toList());
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rick and Morty'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (value == 'name_asc') {
                  _sortBy = 'name';
                  _sortAscending = true;
                } else if (value == 'name_desc') {
                  _sortBy = 'name';
                  _sortAscending = false;
                } else if (value == 'status') {
                  _sortBy = 'status';
                  _sortAscending = true;
                } else if (value == 'species') {
                  _sortBy = 'species';
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name_asc', child: Text('A to Z')),
              const PopupMenuItem(value: 'name_desc', child: Text('Z to A')),
              const PopupMenuItem(value: 'status', child: Text('Status(Alive/Dead)')),
              const PopupMenuItem(value: 'species', child: Text('Species')),
            ],
          ),
        ],
      ),
      body: isLoading && allCharacters.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Қате: $errorMessage'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _getSortedCharacters().length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _getSortedCharacters().length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final character = _getSortedCharacters()[index];
                    return CharacterCard(
                      character: character,
                      isFavorite: favoriteIds.contains(character['id']),
                      onFavoriteToggle: () => _toggleFavorite(character['id']),
                    );
                  },
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
              : [Colors.white, Colors.grey.shade100],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _selectedIndex == 0
            ? _buildHomePage()
            : FavoritesPage(
                favoriteIds: favoriteIds,
                allCharacters: allCharacters,
                onFavoriteToggle: _toggleFavorite,
              ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Барлығы'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Избранное'),
          ],
          backgroundColor: isDark
              ? const Color(0xFF1A1A1A).withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          selectedItemColor: const Color(0xFF00B5CC),
          unselectedItemColor: isDark ? Colors.grey : Colors.grey[600],
          elevation: 0,
        ),
      ),
    );
  }
}