import 'package:flutter/material.dart';
import 'character_card.dart';
import 'favorite_service.dart';

class FavoritesPage extends StatefulWidget {
  final Set<int> favoriteIds;
  final List<dynamic> allCharacters;
  final Function(int) onFavoriteToggle;

  const FavoritesPage({
    super.key,
    required this.favoriteIds,
    required this.allCharacters,
    required this.onFavoriteToggle,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    final favoriteCharacters = widget.allCharacters
        .where((character) => widget.favoriteIds.contains(character['id']))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        backgroundColor: Colors.green[700],
      ),
      body: favoriteCharacters.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Избранное пусто',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавьте персонажей через ❤️',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favoriteCharacters.length,
              itemBuilder: (context, index) {
                final character = favoriteCharacters[index];
                return CharacterCard(
                  character: character,
                  isFavorite: true, 
                  onFavoriteToggle: () {
                    widget.onFavoriteToggle(character['id']);
                    setState(() {}); 
                  },
                );
              },
            ),
    );
  }
}