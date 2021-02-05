import 'package:flutter/material.dart';
import 'package:weeb_manager/api/anime.dart';

class AnimeCard extends StatelessWidget {
  const AnimeCard(this.anime);

  final CurrentlyWatchingAnime anime;

  @override
  Widget build(BuildContext context) {
    final counter = anime.behind <= 1 ? 'episode' : 'episodes';

    return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Image.network(anime.imageUrl),
            ListTile(
              title: Text(anime.title),
            ),
            Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'you are ${anime.behind.toString()} $counter behind',
                ))
          ],
        ));
  }
}
