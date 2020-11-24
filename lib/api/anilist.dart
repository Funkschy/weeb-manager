import 'dart:convert';

import 'package:http/http.dart' as http;

class AnilistInfo {
  const AnilistInfo(this.currentEpisode);

  final int currentEpisode;
}

final String _apiUrl = 'https://graphql.anilist.co';
final String _airingEpQuery = '''
query media(\$search:String) {
  Page(page:1) {
    media(search:\$search) {
      id,
      nextAiringEpisode{airingAt timeUntilAiring episode}
    }
  }
}
''';

Future<AnilistInfo> getAnilistInfo(String name) async {
  final params = {
    'query': _airingEpQuery,
    'variables': {'search': name},
  };

  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode(params);

  final resp = await http.post(_apiUrl, headers: headers, body: body);
  final json = jsonDecode(resp.body);

  final media = json['data']['Page']['media'];
  // some error happened
  if (media.length == 0) {
    return AnilistInfo(0);
  }

// find the first object which is still running
  for (var obj in media) {
    if (obj['nextAiringEpisode'] != null) {
      return AnilistInfo(obj['nextAiringEpisode']['episode'] - 1);
    }
  }

  return AnilistInfo(0);
}
