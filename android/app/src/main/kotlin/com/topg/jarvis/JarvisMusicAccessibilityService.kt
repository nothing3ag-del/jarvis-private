package com.topg.jarvis

import android.accessibilityservice.AccessibilityService
import android.app.SearchManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Bundle
import android.provider.MediaStore
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class JarvisMusicAccessibilityService : AccessibilityService() {

    companion object {
        var instance: JarvisMusicAccessibilityService? = null
        var pendingPlaylistName: String? = null

        val SUPPORTED_PACKAGES = mapOf(
            "spotify" to "com.spotify.music",
            "gaana" to "com.gaana",
            "jiosaavn" to "com.jio.media.jiobeats",
            "ytmusic" to "com.google.android.apps.youtube.music"
        )

        fun playSongWithoutApi(context: Context, query: String, appKey: String): Boolean {
            val pkg = SUPPORTED_PACKAGES[appKey] ?: "com.spotify.music"
            val intent = Intent(MediaStore.INTENT_ACTION_MEDIA_PLAY_FROM_SEARCH).apply {
                putExtra(MediaStore.EXTRA_MEDIA_FOCUS, "vnd.android.cursor.item/*")
                putExtra(SearchManager.QUERY, query)
                setPackage(pkg)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            return try {
                context.startActivity(intent)
                true
            } catch (e: Exception) {
                openAppPackage(context, appKey)
            }
        }

        fun openAppPackage(context: Context, appKey: String): Boolean {
            val pkg = SUPPORTED_PACKAGES[appKey] ?: "com.spotify.music"
            val launchIntent = context.packageManager.getLaunchIntentForPackage(pkg)
            return if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
                true
            } else {
                false
            }
        }

        fun dispatchPauseKey(context: Context) {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.dispatchMediaKeyEvent(
                KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PAUSE)
            )
            audioManager.dispatchMediaKeyEvent(
                KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PAUSE)
            )
        }

        fun setSystemMusicVolume(context: Context, percentage: Int) {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val targetVolume = ((percentage.coerceIn(0, 100) / 100.0) * maxVolume).toInt()
            audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetVolume, AudioManager.FLAG_SHOW_UI)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val rootNode = rootInActiveWindow ?: return

        pendingPlaylistName?.let { playlistTitle ->
            if (event?.packageName == "com.spotify.music") {
                clickNodeByText(rootNode, "Your Library")
                clickNodeByText(rootNode, "Create playlist")
                val inputNodes = rootNode.findAccessibilityNodeInfosByViewId(
                    "com.spotify.music:id/edit_text"
                )
                if (inputNodes.isNotEmpty()) {
                    val args = Bundle()
                    args.putCharSequence(
                        AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                        playlistTitle
                    )
                    inputNodes[0].performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
                    clickNodeByText(rootNode, "Create")
                    pendingPlaylistName = null
                }
            }
        }
    }

    override fun onInterrupt() {}

    private fun clickNodeByText(root: AccessibilityNodeInfo, text: String): Boolean {
        val nodes = root.findAccessibilityNodeInfosByText(text)
        for (node in nodes) {
            if (node.isClickable) {
                node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                return true
            }
            node.parent?.let { parent ->
                if (parent.isClickable) {
                    parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    return true
                }
            }
        }
        return false
    }
}
