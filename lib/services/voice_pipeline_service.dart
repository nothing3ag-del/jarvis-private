import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

class VoicePipelineService {
  final Future<void> Function(String language) onWakeWordDetected;
  final void Function(String text, String language) onTranscriptUpdate;
  final Future<void> Function(String finalCommand, String language) onFinalCommand;
  final void Function(double amplitude) onAmplitudeChange;

  PorcupineManager? _porcupineManager;
  final FlutterTts _tts = FlutterTts();
  Timer? _lipSyncTimer;

  VoicePipelineService({
    required this.onWakeWordDetected,
    required this.onTranscriptUpdate,
    required this.onFinalCommand,
    required this.onAmplitudeChange,
  }) {
    _configureOfflineTts();
  }

  Future<void> _configureOfflineTts() async {
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(0.95);
    _tts.setStartHandler(() {
      _lipSyncTimer?.cancel();
      _lipSyncTimer = Timer.periodic(const Duration(milliseconds: 60), (t) {
        onAmplitudeChange(0.35 + (t.tick % 5) * 0.12);
      });
    });
    _tts.setCompletionHandler(() {
      _lipSyncTimer?.cancel();
      onAmplitudeChange(0.0);
    });
  }

  Future<bool> startListeningPipeline() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        'YOUR_OFFLINE_PICOVOICE_ACCESS_KEY',
        [
          'assets/models/hey_jarvis_android.ppn',
          'assets/models/hello_jarvis_hi_android.ppn',
        ],
        (int keywordIndex) {
          final lang = keywordIndex == 1 ? 'hi' : 'en';
          onWakeWordDetected(lang);
        },
      );
      await _porcupineManager?.start();
    } catch (_) {
      // Continues in push-to-talk / preset command mode until .ppn models are placed
    }
    return true;
  }

  Future<void> stopListeningPipeline() async {
    await _porcupineManager?.stop();
    await _porcupineManager?.delete();
    _porcupineManager = null;
    onAmplitudeChange(0.0);
  }

  Future<void> speak(String text, {required String language}) async {
    await _tts.setLanguage(language == 'hi' ? 'hi-IN' : 'en-IN');
    await _tts.speak(text);
  }

  Future<void> captureUserCommand({required String language}) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
