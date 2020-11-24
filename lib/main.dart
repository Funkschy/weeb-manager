import 'package:flutter/material.dart';
import 'package:weeb_manager/api/anime.dart';
import 'package:weeb_manager/api/oauth.dart';
import 'package:weeb_manager/widgets/anime_list.dart';

void main() {
  runApp(WeebManager());
}

class WeebManager extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weeb Manager',
      home: CurrentlyWatchingView(),
      theme: ThemeData.dark(),
    );
  }
}

class CurrentlyWatchingView extends StatefulWidget {
  @override
  _CurrentlyWatchingViewState createState() => _CurrentlyWatchingViewState();
}

class _CurrentlyWatchingViewState extends State<CurrentlyWatchingView> {
  MalClient _client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Weeb Manager'),
          actions: [
            IconButton(icon: Icon(Icons.list_rounded), onPressed: _pushSettings)
          ],
        ),
        body: AnimeList(() => getCurrentlyWatching()));
  }

  Future<List<CurrentlyWatchingAnime>> getCurrentlyWatching() async {
    return fetch(_client);
  }

  void _pushSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      final tile = _client == null
          ? ListTile(
              title: RaisedButton(
                  child: Text('Allow Access'),
                  onPressed: () async {
                    Navigator.pop(context);
                    _client = await MalClient.create();
                    setState(() {});
                  }))
          // if we already have a client, we don't need to create a new one
          : ListTile(
              title: RaisedButton(
                  child: Text('Reload'),
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() {});
                  }));
      return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: ListView(
          children: [tile],
        ),
      );
    }));
  }
}
