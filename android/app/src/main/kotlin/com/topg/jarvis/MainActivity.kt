package com.topg.jarvis

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.topg.jarvis/music_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val service = JarvisMusicAccessibilityService.instance

            when (call.method) {
                "playSong" -> {
                    val query = call.argument<String>("query") ?: ""
                    val app = call.argument<String>("app") ?: "spotify"
                    val ok = JarvisMusicAccessibilityService.playSongWithoutApi(applicationContext, query, app)
                    result.success(ok)
                }
                "mediaKeyPause" -> {
                    JarvisMusicAccessibilityService.dispatchPauseKey(applicationContext)
                    result.success(true)
                }
                "setVolume" -> {
                    val level = call.argument<Int>("level") ?: 50
                    JarvisMusicAccessibilityService.setSystemMusicVolume(applicationContext, level)
                    result.success(true)
                }
                "createPlaylist" -> {
                    val name = call.argument<String>("name") ?: "Topg Playlist"
                    if (service == null) {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(false)
                    } else {
                        JarvisMusicAccessibilityService.pendingPlaylistName = name
                        JarvisMusicAccessibilityService.openAppPackage(applicationContext, "spotify")
                        result.success(true)
                    }
                }
                "openMusicApp" -> {
                    val app = call.argument<String>("app") ?: "spotify"
                    val ok = JarvisMusicAccessibilityService.openAppPackage(applicationContext, app)
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }
    }
}
