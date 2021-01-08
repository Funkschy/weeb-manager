import 'dart:convert';

import 'package:weeb_manager/api/oauth.dart';

import 'anilist.dart';

class CurrentlyWatchingAnime {
  get title => {};
  get imageUrl => {};
  get behind => {};
}

class _MalInfo implements CurrentlyWatchingAnime {
  String jpTitle;
  String status;
  AnimeSeason startSeason;
  int id;
  int numEpsWatched;

  String _title;
  String _imageUrl;
  // how many episodes are you behind?
  int _behind;

  _MalInfo(String title) : _title = title;

  _MalInfo.fromListJson(Map<String, dynamic> json) {
    id = json['node']['id'];
    _title = json['node']['title'];
    _imageUrl = json['node']['main_picture']['large'];
  }

  _MalInfo.fromInfoJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    numEpsWatched = json['my_list_status']['num_episodes_watched'];
    jpTitle = json['alternative_titles']['ja'];
    var season = json['start_season'];
    startSeason = AnimeSeason(season['year'], season['season']);
    _title = json['title'];
    _imageUrl = json['main_picture']['large'];
  }

  @override
  get behind => _behind;
  set behind(val) => _behind = val;

  @override
  get imageUrl => _imageUrl;

  @override
  get title => _title;
}

class _MalInfoList {
  List<_MalInfo> animes;
  String next;

  _MalInfoList(List<_MalInfo> animes) {
    this.animes = animes;
  }

  void merge(_MalInfoList other) {
    this.animes.addAll(other.animes);
    next = other.next;
  }

  int get length => animes.length;

  operator [](int i) => animes[i];

  _MalInfoList.fromJson(Map<String, dynamic> json) {
    animes = (json['data'] as List<dynamic>)
        .map((node) => _MalInfo.fromListJson(node))
        .toList();
    next = json['paging']['next'];
  }
}

class __ApiCombo {
  const __ApiCombo(this.malInfo, this.aniListInfo);

  final _MalInfo malInfo;
  final AnilistInfo aniListInfo;
}

Future<List<CurrentlyWatchingAnime>> fetch(MalClient client) async {
  if (client == null) {
    return [];
  }

  Future<__ApiCombo> fetchAnimeInfo(
      Map<String, AnilistInfo> airingInfos, String title, int id) async {
    final malInfoData = await client.apiGet('/anime/' +
        id.toString() +
        '?fields=id,title,status,my_list_status,alternative_titles,start_season');

    final malJson = jsonDecode(malInfoData.body);
    final malInfo = _MalInfo.fromInfoJson(malJson);

    // the japanese title is usually the same on every site, while the
    //english title can vary
    var info = airingInfos[malInfo.jpTitle.toLowerCase()];
    if (info == null) {
      info = airingInfos[malInfo.title.toLowerCase()];
    }

    if (info == null) {
      // we only want to fetch the anilist info if we the series is airing
      return __ApiCombo(malInfo, AnilistInfo(0));
    }

    return __ApiCombo(malInfo, info);
  }

  List<Future<__ApiCombo>> waitingFor = [];
  {
    String initUrl =
        'https://api.myanimelist.net/v2/users/@me/animelist?status=watching';
    final list = _MalInfoList([]);
    list.next = initUrl;
    do {
      final malResult = client.get(list.next);
      final anilistResult = getAnilistInfo();

      final animelist = jsonDecode((await malResult).body);
      final airingInfos = await anilistResult;
      final nextList = _MalInfoList.fromJson(animelist);
      for (var anime in nextList.animes) {
        waitingFor.add(fetchAnimeInfo(airingInfos, anime.title, anime.id));
      }
      list.merge(nextList);
    } while (list.next != null);
  }

  List<CurrentlyWatchingAnime> airingAnimes = [];
  for (var future in waitingFor) {
    final info = await future;
    final malData = info.malInfo;
    final behind = info.aniListInfo.currentEpisode - malData.numEpsWatched;
    if (behind <= 0) {
      continue;
    }

    malData.behind = behind;
    airingAnimes.add(malData);
  }

  return airingAnimes;
}
