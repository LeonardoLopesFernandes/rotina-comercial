package com.rotina.rotina_comercial

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.ContentValues
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore

class MainActivity : FlutterActivity() {
    private val PROXY_CHANNEL = "rotina/proxy"
    private val STORAGE_CHANNEL = "rotina/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PROXY_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getProxy") {
                    result.success(getSystemProxy())
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePdf" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        if (bytes == null || fileName == null) {
                            result.error("INVALID_ARGS", "bytes ou fileName ausentes", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(savePdfToDownloads(bytes, fileName))
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message ?: "Falha ao salvar", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getSystemProxy(): String {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return ""
            val lp = cm.getLinkProperties(network) ?: return ""
            val proxyObj = lp.javaClass.getMethod("getHttpProxy").invoke(lp) ?: return ""
            // Tenta ProxyInfo (android.net) ou java.net.Proxy
            val host = try {
                proxyObj.javaClass.getMethod("getHost").invoke(proxyObj) as? String
            } catch (e: Exception) {
                null
            }
            val port = try {
                proxyObj.javaClass.getMethod("getPort").invoke(proxyObj) as? Int
            } catch (e: Exception) {
                null
            }
            if (!host.isNullOrEmpty() && port != null) {
                "$host:$port"
            } else {
                val addr = try {
                    proxyObj.javaClass.getMethod("address").invoke(proxyObj)
                } catch (e: Exception) {
                    null
                }
                if (addr != null) {
                    val h = addr.javaClass.getMethod("getHostName").invoke(addr) as? String
                    val p = addr.javaClass.getMethod("getPort").invoke(addr) as? Int
                    if (!h.isNullOrEmpty() && p != null) "$h:$p" else ""
                } else {
                    ""
                }
            }
        } catch (e: Exception) {
            ""
        }
    }

    private fun savePdfToDownloads(bytes: ByteArray, fileName: String): String {
        val resolver = contentResolver
        val collection: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Downloads.EXTERNAL_CONTENT_URI
        }
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
        }
        val uri = resolver.insert(collection, values)
            ?: throw Exception("Não foi possível criar o arquivo em Downloads")
        resolver.openOutputStream(uri)?.use { it.write(bytes) }
            ?: throw Exception("Não foi possível gravar o arquivo")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        }
        return uri.toString()
    }
}
