import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'clientId.dart';

class MalClient {
  final _storage = FlutterSecureStorage();

  String _authString;
  String _refreshToken;
  DateTime _expiresAt;

  static Future<MalClient> create() async {
    final client = MalClient();
    if (!await client._generateTokens()) {
      throw Exception('Coult not generate token');
    }
    return client;
  }

  Future<bool> _generateTokens() async {
    String savedAuthString = await _storage.read(key: 'authString');
    if (savedAuthString != null) {
      _authString = savedAuthString;
      _refreshToken = await _storage.read(key: 'refreshToken');
      _expiresAt = DateTime.parse(await _storage.read(key: 'expiresAt'));
      // since the token could be too old, we must also refresh it
      await _refreshTokens();
      return true;
    }

    final verifier = _createOAuthCodeVerifier();
    final authUrl = _generateLoginUrl(clientId, verifier);
    // final client = MalOAuth2Client(
    //     redirectUri: 'my.test.app://oauth2redirect',
    //     customUriScheme: 'my.test.app');

    String result;
    try {
      result = await FlutterWebAuth.authenticate(
          url: authUrl, callbackUrlScheme: 'funkschy.weebmanager');
    } on PlatformException {
      // this is thrown, if the user cancels the activation
      return false;
    }

    final code = Uri.parse(result).queryParameters['code'];
    // final state = Uri.parse(result).queryParameters['state'];

    final params = {
      'client_id': clientId,
      'code': code,
      'code_verifier': verifier,
      'grant_type': 'authorization_code'
    };
    final tokenUri = Uri.https(
      'myanimelist.net',
      '/v1/oauth2/token',
    );

    final resp = await http.post(tokenUri.toString(), body: params);
    final tokenJson = jsonDecode(resp.body);
    await _updateFromJson(tokenJson);
    return true;
  }

  Future<void> _refreshTokens() async {
    final params = {
      'client_id': clientId,
      'grant_type': 'refresh_token',
      'refresh_token': _refreshToken
    };
    final tokenUri = Uri.https(
      'myanimelist.net',
      '/v1/oauth2/token',
    );

    final resp = await http.post(tokenUri.toString(), body: params);
    final tokenJson = jsonDecode(resp.body);
    await _updateFromJson(tokenJson);
  }

  Future<void> _updateFromJson(dynamic tokenJson) async {
    final expiresIn = tokenJson['expires_in'];
    final accessToken = tokenJson['access_token'];
    final refreshToken = tokenJson['refresh_token'];

    _refreshToken = refreshToken;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    _authString = 'Bearer ' + accessToken;

    await _storage.write(key: 'authString', value: _authString);
    await _storage.write(key: 'refreshToken', value: _refreshToken);
    await _storage.write(key: 'expiresAt', value: _expiresAt.toIso8601String());
  }

  Future<http.Response> apiGet(String path) async {
    return get('https://api.myanimelist.net/v2' + path);
  }

  Future<http.Response> get(String url) async {
    if (_authString == null) {
      if (!await _generateTokens()) {
        throw Exception('Coult not generate token');
      }
    } else if (DateTime.now().isAfter(_expiresAt)) {
      await _refreshTokens();
    }

    return http.get(url, headers: {'Authorization': _authString});
  }
}

String _createOAuthCodeVerifier() {
  final _random = Random.secure();
  final values = List<int>.generate(200, (i) => _random.nextInt(256));
  return base64UrlEncode(values).substring(0, 128);
}

String _generateLoginUrl(String clientId, String verifier) {
  final uri = Uri.https('myanimelist.net', '/v1/oauth2/authorize', {
    'response_type': 'code',
    'client_id': clientId,
    'code_challenge': verifier,
    'state': 'request42'
  });
  return uri.toString();
}

// class MalOAuth2Client extends OAuth2Client {
//   MalOAuth2Client({String redirectUri, String customUriScheme})
//       : super(
//             authorizeUrl: 'https://myanimelist.net/v1/oauth2/authorize',
//             tokenUrl: 'https://myanimelist.net/v1/oauth2/token',
//             redirectUri: redirectUri,
//             customUriScheme: customUriScheme);
// }

// void authenticate() async {
//   final verifier = _createOAuthCodeVerifier();
//   final authUrl = _generateLoginUrl(verifier);
//   // final client = MalOAuth2Client(
//   //     redirectUri: 'my.test.app://oauth2redirect',
//   //     customUriScheme: 'my.test.app');
//
//   final result = await FlutterWebAuth.authenticate(
//       url: authUrl, callbackUrlScheme: 'my.test.app');
//
//   final code = Uri.parse(result).queryParameters['code'];
//   // final state = Uri.parse(result).queryParameters['state'];
//
//   final params = {
//     'client_id': _clientId,
//     'code': code,
//     'code_verifier': verifier,
//     'grant_type': 'authorization_code'
//   };
//   final tokenUri = Uri.https(
//     'myanimelist.net',
//     '/v1/oauth2/token',
//   );
//
//   final resp = await http.post(tokenUri.toString(), body: params);
//
//   final tokenJson = jsonDecode(resp.body);
//   final expiresIn = tokenJson['expires_in'];
//   final accessToken = tokenJson['access_token'];
//   final refreshToken = tokenJson['refresh_token'];
//
//   final auth = 'Bearer ' + accessToken;
//   final profile = await http.get('https://api.myanimelist.net/v2/users/@me',
//       headers: {'Authorization': auth});
//
//   print(jsonDecode(profile.body));
// }
