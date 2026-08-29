package com.rotina.rotina_comercial

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.net.ConnectivityManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "rotina/proxy"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getProxy") {
                    result.success(getSystemProxy())
                } else {
                    result.notImplemented()
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
}
