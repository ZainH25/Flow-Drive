package com.example.flow_drive

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                else -> result.notImplemented()
            }
        }
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
