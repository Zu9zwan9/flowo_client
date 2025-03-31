import Foundation

@objc class LlamaInference: NSObject {
    @objc static func initializeModel(_ modelPath: String, contextSize: Int = 2048, quantizationLevel: Int = 2, useGPU: Bool = false) -> Bool {
        print("Initializing model at \(modelPath)")
        print("Context size: \(contextSize)")
        print("Quantization level: \(quantizationLevel)")
        print("Use GPU: \(useGPU)")
        return llamaInitialize(modelPath, Int32(contextSize), Int32(quantizationLevel), useGPU)
    }

    @objc static func runInference(_ prompt: String, maxTokens: Int, temperature: Float = 0.7) -> String {
        print("Running inference with prompt: \(prompt)")
        print("Max tokens: \(maxTokens)")
        print("Temperature: \(temperature)")
        return llamaRunInference(prompt, Int32(maxTokens), temperature)
    }

    @objc static func releaseResources() {
        print("Releasing model resources")
        llamaReleaseResources()
    }
}

// C bindings to interface with llama.cpp
@_silgen_name("llamaInitialize")
func llamaInitialize(_ modelPath: UnsafePointer<CChar>, _ contextSize: Int32, _ quantizationLevel: Int32, _ useGPU: Bool) -> Bool

@_silgen_name("llamaRunInference")
func llamaRunInference(_ prompt: UnsafePointer<CChar>, _ maxTokens: Int32, _ temperature: Float) -> String

@_silgen_name("llamaReleaseResources")
func llamaReleaseResources()
