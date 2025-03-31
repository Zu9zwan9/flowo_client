package com.example.flowo_client;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * Plugin that handles the method channel for llama.cpp inference
 */
public class LlamaInferencePlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "LlamaInferencePlugin";
    private static final String CHANNEL = "com.example.flowo_client/llama_inference";

    private MethodChannel channel;
    private Context context;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
        context = binding.getApplicationContext();

        Log.i(TAG, "LlamaInferencePlugin attached to engine");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        context = null;

        Log.i(TAG, "LlamaInferencePlugin detached from engine");
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        Log.i(TAG, "Method call received: " + call.method);

        switch (call.method) {
            case "initializeModel":
                initializeModel(call, result);
                break;
            case "generateText":
                generateText(call, result);
                break;
            case "releaseModel":
                releaseModel(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void initializeModel(MethodCall call, Result result) {
        try {
            String modelPath = call.argument("modelPath");
            Integer contextSize = call.argument("contextSize");
            Integer quantizationLevel = call.argument("quantizationLevel");
            Boolean useGPU = call.argument("useGPU");

            if (modelPath == null) {
                result.error("INVALID_ARGUMENT", "Model path cannot be null", null);
                return;
            }

            if (contextSize == null) {
                contextSize = 2048; // Default context size
            }

            if (quantizationLevel == null) {
                quantizationLevel = 2; // Default to Q4_1 quantization
            }

            if (useGPU == null) {
                useGPU = false; // Default to not using GPU
            }

            Log.i(TAG, "Initializing model with quantization level: " + quantizationLevel + ", GPU: " + useGPU);
            boolean success = LlamaInference.getInstance().initializeModel(
                context, modelPath, contextSize, quantizationLevel, useGPU);
            result.success(success);

            Log.i(TAG, "Model initialization " + (success ? "successful" : "failed"));
        } catch (Exception e) {
            Log.e(TAG, "Error initializing model", e);
            result.error("INITIALIZATION_ERROR", "Failed to initialize model: " + e.getMessage(), null);
        }
    }

    private void generateText(MethodCall call, Result result) {
        try {
            String prompt = call.argument("prompt");
            Integer maxTokens = call.argument("maxTokens");
            Double temperature = call.argument("temperature");

            if (prompt == null) {
                result.error("INVALID_ARGUMENT", "Prompt cannot be null", null);
                return;
            }

            if (maxTokens == null) {
                maxTokens = 256; // Default max tokens
            }

            if (temperature == null) {
                temperature = 0.7; // Default temperature
            }

            String generatedText = LlamaInference.getInstance().generate(prompt, maxTokens, temperature.floatValue());
            result.success(generatedText);

            Log.i(TAG, "Text generation successful");
        } catch (Exception e) {
            Log.e(TAG, "Error generating text", e);
            result.error("GENERATION_ERROR", "Failed to generate text: " + e.getMessage(), null);
        }
    }

    private void releaseModel(Result result) {
        try {
            LlamaInference.getInstance().release();
            result.success(null);

            Log.i(TAG, "Model resources released");
        } catch (Exception e) {
            Log.e(TAG, "Error releasing model", e);
            result.error("RELEASE_ERROR", "Failed to release model: " + e.getMessage(), null);
        }
    }
}
