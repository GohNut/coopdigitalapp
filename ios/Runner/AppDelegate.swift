import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Setup Method Channel
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let nativeBridgeChannel = FlutterMethodChannel(
      name: "com.example.coop_digital_app/native_bridge",
      binaryMessenger: controller.binaryMessenger
    )
    
    nativeBridgeChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "downloadImage" {
        if let args = call.arguments as? [String: Any],
           let dataUrl = args["dataUrl"] as? String {
          self?.saveDataUrlToPhotos(dataUrl: dataUrl, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "dataUrl is missing", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func saveDataUrlToPhotos(dataUrl: String, result: @escaping FlutterResult) {
    // Extract Base64 data from Data URL
    let base64String: String
    if dataUrl.hasPrefix("data:image") {
      if let commaIndex = dataUrl.firstIndex(of: ",") {
        base64String = String(dataUrl[dataUrl.index(after: commaIndex)...])
      } else {
        result(FlutterError(code: "INVALID_FORMAT", message: "Invalid Data URL format", details: nil))
        return
      }
    } else {
      base64String = dataUrl
    }
    
    // Decode Base64 to Data
    guard let imageData = Data(base64Encoded: base64String),
          let image = UIImage(data: imageData) else {
      result(FlutterError(code: "DECODE_ERROR", message: "Failed to decode image", details: nil))
      return
    }
    
    // Request permission and save to Photos
    PHPhotoLibrary.requestAuthorization { status in
      guard status == .authorized else {
        result(FlutterError(code: "PERMISSION_DENIED", message: "Photos permission denied", details: nil))
        return
      }
      
      PHPhotoLibrary.shared().performChanges({
        let creationRequest = PHAssetCreationRequest.forAsset()
        creationRequest.addResource(with: .photo, data: imageData, options: nil)
      }) { success, error in
        if success {
          print("Image saved to Photos successfully")
          result(true)
        } else {
          result(FlutterError(code: "SAVE_ERROR", message: error?.localizedDescription ?? "Failed to save image", details: nil))
        }
      }
    }
  }
}
