import 'dart:math';

import 'package:flutter/material.dart';
import 'package:weeb_manager/api/anime.dart';

import 'anime_card.dart';

class AnimeList extends StatelessWidget {
  AnimeList(this._apiCall);

  final Future<List<CurrentlyWatchingAnime>> Function() _apiCall;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CurrentlyWatchingAnime>>(
        future: _apiCall(),
        builder: (BuildContext context,
            AsyncSnapshot<List<CurrentlyWatchingAnime>> snap) {
          if (!snap.hasData) {
            return Container();
          }

          final count = max(snap.data.length * 2 - 1, 0);
          return ListView.builder(
            itemCount: count,
            padding: EdgeInsets.all(16.0),
            itemBuilder: (BuildContext context, int i) {
              if (i.isOdd) return Divider();
              final anime = snap.data[i ~/ 2];

              return AnimeCard(anime);
            },
          );
        });
  }
}
