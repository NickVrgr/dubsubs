package com.vargar.dubsubs

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles .srt files opened from outside the app (file manager, email
 * attachment, browser download, etc.) via the VIEW intent-filter declared in
 * AndroidManifest.xml, and hands their contents to Dart over a MethodChannel.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.vargar.dubsubs/open_file"
    private var channel: MethodChannel? = null
    private var pendingFile: Map<String, Any?>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel = methodChannel
        pendingFile = readSrtFromIntent(intent)
        methodChannel.setMethodCallHandler { call, result ->
            if (call.method == "getInitialFile") {
                result.success(pendingFile)
                pendingFile = null
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val file = readSrtFromIntent(intent) ?: return
        channel?.invokeMethod("onFileOpened", file)
    }

    private fun readSrtFromIntent(intent: Intent?): Map<String, Any?>? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val uri: Uri = intent.data ?: return null
        return try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
            mapOf(
                "name" to (queryDisplayName(uri) ?: uri.lastPathSegment ?: "subtitle.srt"),
                "bytes" to bytes,
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme != "content") return uri.lastPathSegment
        return contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (idx >= 0 && cursor.moveToFirst()) cursor.getString(idx) else null
        }
    }
}
