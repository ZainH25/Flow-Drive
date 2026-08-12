package com.example.flow_drive

import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.os.StatFs
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "flow_drive/device_storage",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getStorageInfo" -> {
                    try {
                        result.success(readStorageInfo())
                    } catch (e: Exception) {
                        result.error("STORAGE_ERROR", e.message, null)
                    }
                }
                "revealFolder" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("INVALID", "path is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        revealFolder(path)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OPEN_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /// Open [path] in the system Files / Documents UI (map stays unchanged).
    private fun revealFolder(path: String) {
        val file = File(path)
        if (!file.exists() || !file.isDirectory) {
            throw IllegalArgumentException("Folder not found")
        }

        val attempts = mutableListOf<Exception>()

        // 1) Storage Access Framework document URI (works for /storage/emulated/0/...)
        try {
            val docUri = pathToPrimaryDocumentUri(path)
            if (docUri != null) {
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                return
            }
        } catch (e: Exception) {
            attempts.add(e)
        }

        // 2) Generic folder MIME (some OEM file managers)
        try {
            @Suppress("DEPRECATION")
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.fromFile(file), "resource/folder")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return
        } catch (e: Exception) {
            attempts.add(e)
        }

        // 3) Browse intent used by DocumentsUI on some devices
        try {
            val docUri = pathToPrimaryDocumentUri(path)
            if (docUri != null) {
                val intent = Intent("android.provider.action.BROWSE").apply {
                    setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(intent)
                return
            }
        } catch (e: Exception) {
            attempts.add(e)
        }

        val detail = attempts.lastOrNull()?.message ?: "No file manager can open this folder"
        throw IllegalStateException(detail)
    }

    private fun pathToPrimaryDocumentUri(path: String): Uri? {
        val primary = Environment.getExternalStorageDirectory()?.absolutePath ?: return null
        if (!path.startsWith(primary)) return null

        val relative = path.removePrefix(primary).trimStart('/')
        val docId = if (relative.isEmpty()) "primary:" else "primary:$relative"
        return DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            docId,
        )
    }

    private fun readStorageInfo(): Map<String, Double> {
        val candidates = listOfNotNull(
            Environment.getExternalStorageDirectory()?.absolutePath,
            Environment.getDataDirectory().absolutePath,
            filesDir?.absolutePath,
        ).distinct()

        var lastError: Exception? = null

        for (path in candidates) {
            try {
                val stat = StatFs(path)
                val blockSize = stat.blockSizeLong
                val totalMb = stat.blockCountLong * blockSize / (1024.0 * 1024.0)
                val freeMb = stat.availableBlocksLong * blockSize / (1024.0 * 1024.0)

                if (totalMb > 0) {
                    return mapOf(
                        "totalMb" to totalMb,
                        "freeMb" to freeMb.coerceAtLeast(0.0),
                    )
                }
            } catch (e: Exception) {
                lastError = e
            }
        }

        throw lastError ?: IllegalStateException("Unable to read device storage")
    }
}
