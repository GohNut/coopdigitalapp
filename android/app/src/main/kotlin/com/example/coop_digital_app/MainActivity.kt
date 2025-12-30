package com.example.coop_digital_app

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import android.util.Log
import android.webkit.JavascriptInterface
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val TAG = "CoopMainActivity"
    private val CHANNEL = "com.example.coop_digital_app/native_bridge"
    private val PERMISSION_REQUEST_CODE = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "Native Bridge MethodChannel initialized on Android")
        showToast("Coop Native Bridge: พร้อมใช้งาน")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "MethodChannel call received: ${call.method}")
            when (call.method) {
                "downloadImage" -> {
                    val dataUrl = call.argument<String>("dataUrl")
                    if (!dataUrl.isNullOrEmpty()) {
                        showToast("Native: รับข้อมูลรูปภาพแล้ว...")
                        try {
                            Log.d(TAG, "Starting image save process (length: ${dataUrl.length})")
                            saveDataUrlToGallery(dataUrl)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "CRITICAL ERROR: ${e.message}", e)
                            showToast("Error: ${e.message}")
                            result.error("SAVE_FAILED", e.message, e.toString())
                        }
                    } else {
                        Log.e(TAG, "Error: dataUrl is empty")
                        showToast("Error: ข้อมูลรูปภาพว่างเปล่า")
                        result.error("INVALID_ARGUMENT", "dataUrl is empty", null)
                    }
                }
                "checkStatus" -> {
                    Log.d(TAG, "Status check received")
                    showToast("Native Bridge: เชื่อมต่อสำเร็จ ✅")
                    result.success("Native Bridge is ACTIVE")
                }
                else -> {
                    Log.w(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "Permission granted by user")
                showToast("ได้รับสิทธิ์แล้ว รบกวนกดบันทึกรูปอีกครั้งครับ")
            } else {
                Log.w(TAG, "Permission denied by user")
                showToast("ไม่ได้รับสิทธิ์เข้าถึงพื้นที่จัดเก็บข้อมูล")
            }
        }
    }

    // JavaScript Interface for Hybrid/WebView shell
    inner class JSInterface {
        @JavascriptInterface
        fun downloadImageUrl(dataUrl: String) {
            runOnUiThread {
                Log.d(TAG, "JSBridge: downloadImageUrl called")
                saveDataUrlToGallery(dataUrl)
            }
        }
    }
    
    // This allows the shell to inject the interface if it's using our MainActivity
    fun setupWebView(webView: android.webkit.WebView) {
        webView.settings.javaScriptEnabled = true
        webView.addJavascriptInterface(JSInterface(), "NativeFunction")
        Log.d(TAG, "JSBridge: NativeFunction interface injected")
    }

    private fun saveDataUrlToGallery(dataUrl: String) {
        Log.d(TAG, "saveDataUrlToGallery: Received data URL")
        
        // 1. Check Permissions for older Androids
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            Log.d(TAG, "Checking WRITE_EXTERNAL_STORAGE permission")
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) 
                != PackageManager.PERMISSION_GRANTED) {
                Log.w(TAG, "Permission denied, requesting...")
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), PERMISSION_REQUEST_CODE)
                showToast("ต้องการสิทธิ์เข้าถึง Photo Library")
                return
            }
        }
        
        try {
            showToast("กำลังประมวลผลรูปภาพ...")
            Log.d(TAG, "Attempting to extract Base64 data.")
            // Extract Base64 data
            val base64Data = if (dataUrl.contains(",")) {
                dataUrl.substring(dataUrl.indexOf(",") + 1)
            } else {
                dataUrl
            }
            Log.d(TAG, "Base64 data extracted. Length: ${base64Data.length}")
            
            showToast("กำลังถอดรหัสรูปภาพ...")
            // Decode Base64
            val imageBytes = Base64.decode(base64Data, Base64.DEFAULT)
            Log.d(TAG, "Image bytes decoded. Size: ${imageBytes.size}")
            
            // Set options to avoid OOM
            val options = BitmapFactory.Options().apply {
                inMutable = true
            }
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, options)
            Log.d(TAG, "Bitmap created from bytes.")
            
            if (bitmap == null) {
                Log.e(TAG, "BitmapFactory returned null")
                showToast("ไม่สามารถประมวลผลรูปได้ (Bitmap Null)")
                return
            }
            
            // Save to MediaStore
            Log.d(TAG, "Saving to MediaStore...")
            showToast("กำลังบันทึกรูปภาพลงอัลบั้ม...")
            saveImageToMediaStore(bitmap)
            showToast("บันทึกรูปลงอัลบั้มเรียบร้อยแล้ว")
            Log.d(TAG, "Image saved to MediaStore successfully.")
        } catch (e: Exception) {
            Log.e(TAG, "Save process failed: ${e.message}")
            showToast("พังที่ Native: ${e.message}")
            throw e
        }
    }
    
    private fun saveImageToMediaStore(bitmap: Bitmap) {
        val filename = "coop_${System.currentTimeMillis()}.png"
        val contentValues = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Coop")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }
        
        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
        
        uri?.let {
            var outputStream: OutputStream? = null
            try {
                outputStream = resolver.openOutputStream(it)
                outputStream?.let { stream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                }
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    contentValues.clear()
                    contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                    resolver.update(it, contentValues, null, null)
                }
                Log.d(TAG, "Saved: $filename")
            } catch (e: Exception) {
                resolver.delete(it, null, null)
                throw e
            } finally {
                outputStream?.close()
            }
        } ?: throw Exception("Failed to create MediaStore entry")
    }

    private fun showToast(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
    }
}
