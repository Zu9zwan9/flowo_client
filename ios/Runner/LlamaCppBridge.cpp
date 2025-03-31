#include "LlamaCppBridge.h"
#include <string>
#include <vector>
#include <memory>
#include "llama.h"  // Include the llama.cpp header

struct LlamaContext {
    llama_context* ctx = nullptr;
    llama_model* model = nullptr;
};

extern "C" {

void* llamacpp_initialize_model(const char* model_path, int32_t context_size,
                               int32_t quantization_level, bool use_gpu) {
    try {
        llama_backend_init(use_gpu);

        // Set up llama.cpp parameters
        llama_model_params model_params = llama_model_default_params();
        model_params.n_gpu_layers = use_gpu ? -1 : 0;  // -1 means all layers on GPU if available

        // Load the model
        auto model = llama_load_model_from_file(model_path, model_params);
        if (!model) {
            return nullptr;
        }

        // Set up context parameters
        llama_context_params ctx_params = llama_context_default_params();
        ctx_params.n_ctx = context_size;

        // Create context
        auto ctx = llama_new_context_with_model(model, ctx_params);
        if (!ctx) {
            llama_free_model(model);
            return nullptr;
        }

        // Create and return our wrapper
        auto* wrapper = new LlamaContext{ctx, model};
        return static_cast<void*>(wrapper);
    } catch (...) {
        return nullptr;
    }
}

char* llamacpp_generate_text(void* context_ptr, const char* prompt, int32_t max_tokens, float temperature) {
    if (!context_ptr) {
        return nullptr;
    }

    auto* context = static_cast<LlamaContext*>(context_ptr);

    try {
        // Tokenize the prompt
        auto tokens = llama_tokenize(context->ctx, prompt, true);

        // Setup generation parameters
        llama_sampling_params params = llama_sampling_default_params();
        params.temp = temperature;
        params.n_predict = max_tokens;

        // Run inference
        std::string result;
        llama_batch batch = llama_batch_init(tokens.size(), 0, 1);

        for (size_t i = 0; i < tokens.size(); ++i) {
            llama_batch_add(batch, tokens[i], i, {0}, false);
        }

        if (llama_decode(context->ctx, batch) != 0) {
            llama_batch_free(batch);
            return nullptr;
        }

        // Generate text
        llama_sampling_context* sampling_ctx = llama_sampling_init(params);
        llama_token new_token = 0;

        for (int i = 0; i < max_tokens; ++i) {
            new_token = llama_sampling_sample(sampling_ctx, context->ctx, NULL);

            if (new_token == llama_token_eos(context->model)) {
                break;
            }

            result += llama_token_to_string(context->ctx, new_token);

            // Prepare for next token
            llama_batch_clear(batch);
            llama_batch_add(batch, new_token, i + tokens.size(), {0}, false);

            if (llama_decode(context->ctx, batch) != 0) {
                break;
            }
        }

        llama_sampling_free(sampling_ctx);
        llama_batch_free(batch);

        // Return result (caller must free this memory)
        char* result_str = strdup(result.c_str());
        return result_str;
    } catch (...) {
        return nullptr;
    }
}

void llamacpp_release_model(void* context_ptr) {
    if (!context_ptr) return;

    auto* context = static_cast<LlamaContext*>(context_ptr);
    if (context->ctx) {
        llama_free(context->ctx);
    }
    if (context->model) {
        llama_free_model(context->model);
    }
    delete context;

    llama_backend_free();
}

void llamacpp_free_string(char* str) {
    if (str) free(str);
}

}
