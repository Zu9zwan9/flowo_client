package com.example.flowo_client;

import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Java interface for the native llama.cpp inference module.
 * This class provides methods to initialize the model, generate text, and release resources.
 */
public class LlamaInference {
    private static final String TAG = "LlamaInference";
    private static volatile LlamaInference instance;
    private boolean isModelInitialized = false;

    // Load the native library
    static {
        System.loadLibrary("llama_inference");
    }

    // Private constructor to enforce singleton pattern
    private LlamaInference() {
        // Prevent instantiation outside of getInstance()
    }

    /**
     * Get the singleton instance of LlamaInference
     * @return The LlamaInference instance
     */
    public static LlamaInference getInstance() {
        if (instance == null) {
            synchronized (LlamaInference.class) {
                if (instance == null) {
                    instance = new LlamaInference();
                }
            }
        }
        return instance;
    }

    /**
     * Initialize the model with the given model file and parameters
     * @param context Android context used to access assets
     * @param modelAssetPath Path to the model file in the assets directory
     * @param contextSize Size of the context window for inference
     * @param quantizationLevel Level of quantization to apply (0-4):
     *                         0: No quantization (F32)
     *                         1: Q4_0 quantization (4-bit, small)
     *                         2: Q4_1 quantization (4-bit, medium)
     *                         3: Q5_0 quantization (5-bit, medium)
     *                         4: Q8_0 quantization (8-bit, high accuracy)
     * @param useGPU Whether to use GPU acceleration if available
     * @return True if initialization was successful, false otherwise
     */
    public boolean initializeModel(Context context, String modelAssetPath, int contextSize,
                                  int quantizationLevel, boolean useGPU) {
        if (isModelInitialized) {
            Log.w(TAG, "Model already initialized");
            return true;
        }

        try {
            // Copy the model file from assets to the app's files directory
            File modelFile = copyAssetToFile(context, modelAssetPath);
            if (modelFile == null) {
                Log.e(TAG, "Failed to copy model file from assets");
                return false;
            }

            // Log quantization level
            Log.i(TAG, "Using quantization level: " + quantizationLevel);
            Log.i(TAG, "GPU acceleration: " + (useGPU ? "enabled" : "disabled"));

            // Initialize the model using the native method
            isModelInitialized = initModel(modelFile.getAbsolutePath(), contextSize,
                                          quantizationLevel, useGPU);
            Log.i(TAG, "Model initialization " + (isModelInitialized ? "successful" : "failed"));
            return isModelInitialized;
        } catch (Exception e) {
            Log.e(TAG, "Error initializing model", e);
            return false;
        }
    }

    /**
     * Generate text using the initialized model
     * @param prompt The input prompt for text generation
     * @param maxTokens Maximum number of tokens to generate
     * @param temperature Temperature parameter for controlling randomness (0.0-1.0)
     * @return The generated text or an error message if generation failed
     */
    public String generate(String prompt, int maxTokens, float temperature) {
        if (!isModelInitialized) {
            Log.e(TAG, "Model not initialized. Call initializeModel() first.");
            return "Error: Model not initialized";
        }

        try {
            return generateText(prompt, maxTokens, temperature);
        } catch (Exception e) {
            Log.e(TAG, "Error generating text", e);
            return "Error: " + e.getMessage();
        }
    }

    /**
     * Release the model resources
     */
    public void release() {
        if (isModelInitialized) {
            releaseModel();
            isModelInitialized = false;
            Log.i(TAG, "Model resources released");
        }
    }

    /**
     * Copy an asset file to the app's files directory
     * @param context Android context
     * @param assetPath Path to the asset file
     * @return The File object for the copied file, or null if copying failed
     */
    private File copyAssetToFile(Context context, String assetPath) {
        try {
            File outputFile = new File(context.getFilesDir(), new File(assetPath).getName());

            // If the file already exists, return it
            if (outputFile.exists()) {
                Log.i(TAG, "Model file already exists at " + outputFile.getAbsolutePath());
                return outputFile;
            }

            // Copy the asset file to the output file
            InputStream inputStream = context.getAssets().open(assetPath);
            OutputStream outputStream = new FileOutputStream(outputFile);

            byte[] buffer = new byte[1024];
            int length;
            while ((length = inputStream.read(buffer)) > 0) {
                outputStream.write(buffer, 0, length);
            }

            outputStream.flush();
            outputStream.close();
            inputStream.close();

            Log.i(TAG, "Copied model file to " + outputFile.getAbsolutePath());
            return outputFile;
        } catch (IOException e) {
            Log.e(TAG, "Error copying asset to file", e);
            return null;
        }
    }

    // Native methods implemented in llama_inference.cpp
    private native boolean initModel(String modelPath, int contextSize, int quantizationLevel, boolean useGPU);
    private native String generateText(String prompt, int maxTokens, float temperature);
    private native void releaseModel();
}
