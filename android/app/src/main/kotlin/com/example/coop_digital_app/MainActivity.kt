package com.example.coop_digital_app

import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val TAG = "CoopMainActivity"
    private val CHANNEL = "com.example.coop_digital_app/native_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "downloadImage" -> {
                    val dataUrl = call.argument<String>("dataUrl")
                    if (dataUrl != null) {
                        try {
                            saveDataUrlToGallery(dataUrl)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving image: ${e.message}", e)
                            result.error("SAVE_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "dataUrl is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun saveDataUrlToGallery(dataUrl: String) {
        Log.d(TAG, "saveDataUrlToGallery called with data URL length: ${dataUrl.length}")
        
        // Extract Base64 data from Data URL
        val base64Data = if (dataUrl.startsWith("data:image")) {
            dataUrl.substring(dataUrl.indexOf(",") + 1)
        } else {
            dataUrl
        }
        
        // Decode Base64 to byte array
        val imageBytes = Base64.decode(base64Data, Base64.DEFAULT)
        val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
        
        if (bitmap == null) {
            throw Exception("Failed to decode bitmap from Base64")
        }
        
        // Save to MediaStore
        saveImageToMediaStore(bitmap)
        Log.d(TAG, "Image saved successfully to gallery")
    }
    
    private fun saveImageToMediaStore(bitmap: Bitmap) {
        val filename = "coop_qr_${System.currentTimeMillis()}.png"
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
                
                Log.d(TAG, "Image saved to gallery: $filename in Coop folder")
            } catch (e: Exception) {
                Log.e(TAG, "Error writing to MediaStore: ${e.message}", e)
                resolver.delete(it, null, null)
                throw e
            } finally {
                outputStream?.close()
            }
        } ?: throw Exception("Failed to create MediaStore entry")
    }
}
