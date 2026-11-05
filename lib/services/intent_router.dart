import 'encrypted_db_service.dart';
import 'music_control_service.dart';

class CommandResult {
  final bool success;
  final String reply;
  CommandResult({required this.success, required this.reply});
}

class IntentRouter {
  final EncryptedDbService db;
  final MusicControlService musicService;

  IntentRouter({required this.db, required this.musicService});

  Future<CommandResult> executeCommand(String rawInput, String lang) async {
    final text = rawInput.toLowerCase().trim();

    final volRegex = RegExp(r'(?:volume|वॉल्यूम)\s*(?:to|को)?\s*(\d{1,3})');
    final volMatch = volRegex.firstMatch(text);
    if (volMatch != null) {
      final level = int.parse(volMatch.group(1)!).clamp(0, 100);
      await musicService.setVolume(level);
      return CommandResult(
        success: true,
        reply: lang == 'hi'
            ? 'हाँ टॉपग, वॉल्यूम $level% कर दिया गया है!'
            : 'Done, Topg! Volume set to $level%.',
      );
    }

    if (text.contains('favorite') || text.contains('फेवरेट')) {
      final favSong = await db.getFavoriteSong() ?? 'Tujhe Kitna Chahne Lage';
      final ok = await musicService.playSongQuery(favSong, app: 'spotify');
      return CommandResult(
        success: ok,
        reply: lang == 'hi'
            ? 'हाँ टॉपग, आपका फेवरेट गाना "$favSong" चला रहा हूँ!'
            : 'Done, Topg! Playing your favorite track "$favSong".',
      );
    }

    if (text.contains('stop') || text.contains('pause') || text.contains('रोक दो')) {
      await musicService.pauseMusic();
      return CommandResult(
        success: true,
        reply: lang == 'hi' ? 'हाँ टॉपग, गाना रोक दिया है!' : 'Done, Topg! Playback paused.',
      );
    }

    if (text.contains('playlist') || text.contains('प्लेलिस्ट')) {
      final ok = await musicService.createSpotifyPlaylist('Topg Vibes');
      return CommandResult(
        success: ok,
        reply: lang == 'hi'
            ? 'हाँ टॉपग, स्पॉटिफ़ाई में नया प्लेलिस्ट बना दिया है!'
            : 'Done, Topg! Created a new playlist on Spotify.',
      );
    }

    if (text.contains('play') || text.contains('चलाओ')) {
      final cleanedQuery = text
          .replaceAll(RegExp(r'(hey jarvis|हेलो जार्विस|play|गाना|चलाओ|music)'), '')
          .trim();
      final targetApp = _resolveTargetApp(text);
      if (cleanedQuery.isEmpty) {
        await musicService.openDefaultMusicApp(targetApp);
        return CommandResult(
          success: true,
          reply: lang == 'hi' ? 'हाँ टॉपग, म्यूजिक ऐप खोल दिया है!' : 'Done, Topg! Opening music.',
        );
      }
      final ok = await musicService.playSongQuery(cleanedQuery, app: targetApp);
      return CommandResult(
        success: ok,
        reply: lang == 'hi'
            ? 'हाँ टॉपग, "$cleanedQuery" चला रहा हूँ!'
            : 'Done, Topg! Playing "$cleanedQuery".',
      );
    }

    return CommandResult(
      success: false,
      reply: lang == 'hi'
          ? 'माफ़ करना टॉपग, यह कमांड समझ नहीं आया।'
          : 'Not sure about that command, Topg.',
    );
  }

  String _resolveTargetApp(String command) {
    if (command.contains('gaana') || command.contains('गाना ऐप')) return 'gaana';
    if (command.contains('saavn') || command.contains('सावन')) return 'jiosaavn';
    if (command.contains('youtube') || command.contains('यूट्यूब')) return 'ytmusic';
    return 'spotify';
  }
}
