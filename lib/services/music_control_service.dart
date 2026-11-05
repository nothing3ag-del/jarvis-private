import 'package:flutter/services.dart';

class MusicControlService {
  static const MethodChannel _channel =
      MethodChannel('com.topg.jarvis/music_control');

  Future<bool> playSongQuery(String songQuery, {String app = 'spotify'}) async {
    return await _channel.invokeMethod<bool>('playSong', {
          'query': songQuery,
          'app': app,
        }) ??
        false;
  }

  Future<void> pauseMusic() async {
    await _channel.invokeMethod('mediaKeyPause');
  }

  Future<void> setVolume(int percentage) async {
    await _channel.invokeMethod('setVolume', {'level': percentage});
  }

  Future<bool> createSpotifyPlaylist(String name) async {
    return await _channel.invokeMethod<bool>('createPlaylist', {'name': name}) ??
        false;
  }

  Future<void> openDefaultMusicApp(String app) async {
    await _channel.invokeMethod('openMusicApp', {'app': app});
  }
}
