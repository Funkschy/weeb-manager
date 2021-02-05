import 'dart:convert';

import 'package:http/http.dart' as http;

class AnimeSeason {
  int year;
  String season;
  AnimeSeason(int year, String season)
      : year = year,
        season = season;

  static AnimeSeason current() {
    var now = DateTime.now();
    if (now.month >= 1 && now.month <= 3) {
      return AnimeSeason(now.year, 'WINTER');
    }
    if (now.month >= 4 && now.month <= 6) {
      return AnimeSeason(now.year, 'SPRING');
    }
    if (now.month >= 7 && now.month <= 9) {
      return AnimeSeason(now.year, 'SUMMER');
    }
    if (now.month >= 10 && now.month <= 12) {
      return AnimeSeason(now.year, 'FALL');
    }

    return null;
  }
}

class AnilistInfo {
  const AnilistInfo(this.currentEpisode);

  final int currentEpisode;
}

final String _apiUrl = 'https://graphql.anilist.co';
final String _airingEpQuery = '''
query media(\$page:Int = 1 \$type:MediaType \$season:MediaSeason \$year:String \$sort:[MediaSort]=[POPULARITY_DESC,SCORE_DESC]) {
  Page(page:\$page,perPage:100) {
    media(type:\$type season:\$season startDate_like:\$year sort:\$sort) {
      idMal
      episodes
      nextAiringEpisode{airingAt timeUntilAiring episode}
    }
  }
}
''';

Future<Map<String, AnilistInfo>> getAnilistInfo() async {
  final currentSeason = AnimeSeason.current();

  final params = {
    'query': _airingEpQuery,
    'variables': {
      'season': currentSeason.season,
      'type': 'ANIME',
      'year': '${currentSeason.year}%'
    },
  };

  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode(params);

  final resp = await http.post(_apiUrl, headers: headers, body: body);
  final json = jsonDecode(resp.body);

  final media = json['data']['Page']['media'];
  final map = Map<String, AnilistInfo>();

  // some error happened
  if (media.length == 0) {
    return map;
  }

  for (var obj in media) {
    // default to episode count
    var info = AnilistInfo(obj['episodes']);
    if (obj['nextAiringEpisode'] != null) {
      info = AnilistInfo(obj['nextAiringEpisode']['episode'] - 1);
    }

    if (obj['idMal'] != null) {
      map[obj['idMal'].toString()] = info;
    }
  }

  return map;
}
