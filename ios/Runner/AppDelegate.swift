/// A description
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "com.example.flowo_client/llama_inference"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let llamaChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )

    setupMethodChannel(llamaChannel)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupMethodChannel(_ channel: FlutterMethodChannel) {
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "initializeModel":
        self.handleInitializeModel(call, result: result)
      case "generateText":
        self.handleGenerateText(call, result: result)
      case "releaseModel":
        self.handleReleaseModel(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func handleInitializeModel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let modelPath = args["modelPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Model path is required", details: nil))
      return
    }

    let contextSize = args["contextSize"] as? Int ?? 2048
    let quantizationLevel = args["quantizationLevel"] as? Int ?? 2
    let useGPU = args["useGPU"] as? Bool ?? false

    print("Initializing model with quantization level: \(quantizationLevel), GPU: \(useGPU)")

    // Call the Swift wrapper for llama.cpp
    let success = LlamaInference.initializeModel(modelPath, contextSize: contextSize,
                                                quantizationLevel: quantizationLevel, useGPU: useGPU)
    result(success)
  }

  private func handleGenerateText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let prompt = args["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Prompt is required", details: nil))
      return
    }

    let maxTokens = args["maxTokens"] as? Int ?? 256
    let temperature = args["temperature"] as? Float ?? 0.7

    print("Generating text with max tokens: \(maxTokens), temperature: \(temperature)")

    // Call the Swift wrapper for llama.cpp
    let generatedText = LlamaInference.runInference(prompt, maxTokens: maxTokens, temperature: temperature)
    result(generatedText)
  }

  private func handleReleaseModel(result: @escaping FlutterResult) {
    // Call the Swift wrapper for llama.cpp to release resources
    LlamaInference.releaseResources()
    result(nil)
  }
}
