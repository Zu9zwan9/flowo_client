import Foundation

@objc class LlamaInference: NSObject {
    @objc static func initializeModel(_ modelPath: String) -> Bool {
        print("Initializing model at \(modelPath)")
        return llamaInitialize(modelPath)
    }

    @objc static func runInference(_ prompt: String, maxTokens: Int) -> String {
        print("Running inference with prompt: \(prompt)")
        return llamaRunInference(prompt, Int32(maxTokens))
    }
}

// C bindings to interface with llama.cpp
@_silgen_name("llamaInitialize")
func llamaInitialize(_ modelPath: UnsafePointer<CChar>) -> Bool

@_silgen_name("llamaRunInference")
func llamaRunInference(_ prompt: UnsafePointer<CChar>, _ maxTokens: Int32) -> String
