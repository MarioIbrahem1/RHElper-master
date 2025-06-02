package com.example.road_helperr

import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.road_helperr/signing_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSigningInfo") {
                result.success(getSigningInfo())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getSigningInfo(): String {
        try {
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
            val signatures = packageInfo.signatures
            val sb = StringBuilder()

            for (signature in signatures) {
                val md = MessageDigest.getInstance("SHA-1")
                md.update(signature.toByteArray())
                val sha1 = bytesToHex(md.digest())
                sb.append("SHA-1: $sha1\n")

                // Also get SHA-256 for future reference
                val md256 = MessageDigest.getInstance("SHA-256")
                md256.update(signature.toByteArray())
                val sha256 = bytesToHex(md256.digest())
                sb.append("SHA-256: $sha256\n")
            }

            return sb.toString()
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e("MainActivity", "Package name not found", e)
            return "Error: Package name not found"
        } catch (e: NoSuchAlgorithmException) {
            Log.e("MainActivity", "No such algorithm", e)
            return "Error: No such algorithm"
        } catch (e: Exception) {
            Log.e("MainActivity", "Error getting signing info", e)
            return "Error: ${e.message}"
        }
    }

    private fun bytesToHex(bytes: ByteArray): String {
        val hexChars = "0123456789ABCDEF".toCharArray()
        val hexString = StringBuilder(bytes.size * 2)

        for (byte in bytes) {
            val i = byte.toInt() and 0xff
            hexString.append(hexChars[i shr 4])
            hexString.append(hexChars[i and 0x0f])
        }

        return hexString.toString()
    }
}
