import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/encrypted_db_service.dart';
import '../services/intent_router.dart';
import '../services/music_control_service.dart';
import '../services/voice_pipeline_service.dart';

enum JarvisMood { idle, listening, thinking, smiling, nodding, shrugging }

class JarvisState {
  final JarvisMood mood;
  final String displayTranscript;
  final String jarvisResponse;
  final String activeLanguage;
  final double audioAmplitude;
  final bool micEnabled;
  final bool renderActive;
  final int particleTriggerCount;

  const JarvisState({
    this.mood = JarvisMood.idle,
    this.displayTranscript = '',
    this.jarvisResponse = 'Hello, Topg! How can I assist you today?',
    this.activeLanguage = 'en',
    this.audioAmplitude = 0.0,
    this.micEnabled = false,
    this.renderActive = true,
    this.particleTriggerCount = 0,
  });

  JarvisState copyWith({
    JarvisMood? mood,
    String? displayTranscript,
    String? jarvisResponse,
    String? activeLanguage,
    double? audioAmplitude,
    bool? micEnabled,
    bool? renderActive,
    int? particleTriggerCount,
  }) {
    return JarvisState(
      mood: mood ?? this.mood,
      displayTranscript: displayTranscript ?? this.displayTranscript,
      jarvisResponse: jarvisResponse ?? this.jarvisResponse,
      activeLanguage: activeLanguage ?? this.activeLanguage,
      audioAmplitude: audioAmplitude ?? this.audioAmplitude,
      micEnabled: micEnabled ?? this.micEnabled,
      renderActive: renderActive ?? this.renderActive,
      particleTriggerCount: particleTriggerCount ?? this.particleTriggerCount,
    );
  }
}

final jarvisProvider =
    StateNotifierProvider<JarvisController, JarvisState>((ref) {
  return JarvisController();
});

class JarvisController extends StateNotifier<JarvisState> {
  JarvisController() : super(const JarvisState());

  final EncryptedDbService _db = EncryptedDbService();
  final MusicControlService _music = MusicControlService();
  late final VoicePipelineService _voice;
  late final IntentRouter _router;

  Future<void> initializeSystem() async {
    await _db.initDb();
    _router = IntentRouter(db: _db, musicService: _music);
    _voice = VoicePipelineService(
      onWakeWordDetected: _handleWakeWord,
      onTranscriptUpdate: (text, lang) {
        state = state.copyWith(displayTranscript: text, activeLanguage: lang);
      },
      onFinalCommand: _processCommand,
      onAmplitudeChange: (amp) {
        if (state.renderActive) {
          state = state.copyWith(audioAmplitude: amp);
        }
      },
    );
  }

  Future<void> toggleMicrophone() async {
    if (state.micEnabled) {
      await _voice.stopListeningPipeline();
      state = state.copyWith(micEnabled: false, mood: JarvisMood.idle);
    } else {
      final granted = await _voice.startListeningPipeline();
      if (granted) {
        state = state.copyWith(
          micEnabled: true,
          mood: JarvisMood.smiling,
          jarvisResponse: 'Hello, Topg! How can I assist you today?\nनमस्ते टॉपग! मैं आपकी कैसे मदद कर सकता हूँ?',
        );
      }
    }
  }

  Future<void> runQuickCommand(String rawText, String language) async {
    state = state.copyWith(displayTranscript: rawText, activeLanguage: language);
    await _processCommand(rawText, language);
  }

  void setRenderActive(bool active) {
    state = state.copyWith(renderActive: active, audioAmplitude: 0.0);
  }

  Future<void> _handleWakeWord(String language) async {
    final greeting = language == 'hi'
        ? 'नमस्ते टॉपग! मैं आपकी कैसे मदद कर सकता हूँ?'
        : 'Hello, Topg! How can I assist you today?';
    state = state.copyWith(
      mood: JarvisMood.listening,
      activeLanguage: language,
      jarvisResponse: greeting,
    );
    await _voice.speak(greeting, language: language);
    await _voice.captureUserCommand(language: language);
  }

  Future<void> _processCommand(String rawText, String language) async {
    if (rawText.trim().isEmpty) {
      final fallback = language == 'hi'
          ? 'माफ़ करना टॉपग, मैंने सुना नहीं।'
          : 'Sorry Topg, I did not catch that.';
      state = state.copyWith(mood: JarvisMood.shrugging, jarvisResponse: fallback);
      await _voice.speak(fallback, language: language);
      return;
    }

    final thinkingMsg =
        language == 'hi' ? 'सोच रहा हूँ टॉपग...' : 'Thinking, Topg...';
    state = state.copyWith(mood: JarvisMood.thinking, jarvisResponse: thinkingMsg);

    final result = await _router.executeCommand(rawText, language);
    await _db.logCommand(rawText, result.reply, language);

    state = state.copyWith(
      mood: result.success ? JarvisMood.nodding : JarvisMood.shrugging,
      jarvisResponse: result.reply,
      particleTriggerCount:
          result.success ? state.particleTriggerCount + 1 : state.particleTriggerCount,
    );

    await _voice.speak(result.reply, language: language);
    state = state.copyWith(mood: JarvisMood.idle);
  }
}
