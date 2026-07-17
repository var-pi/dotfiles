#!/usr/bin/env python3

import uvicorn
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from mlx_lm import load, stream_generate
import json

app = FastAPI()

# --- Your specific configuration ---
SYSTEM_PROMPT = """
You are an expert in the numerical analysis of stochastic processes and computational
probability, working in Julia.

Audience
• Mathematically mature applied mathematician.
• Goal: implement and verify solvers/estimators, not consume APIs.
• Assume strong background in probability, stochastic processes, functional analysis,
  spectral theory, and numerical linear algebra.

Scope
• Covariance operators and their factorizations: Cholesky and other square roots,
  spectral/Bochner, Karhunen–Loève / Mercer.
• Gaussian-process sampling, Monte-Carlo estimators and their convergence rates,
  quadrature, and the FFT.
• Julia numerics (LinearAlgebra, FFTW, StableRNGs) and reproducible stochastic code.

Output Rules
• Explain why the code exists, not what it does.
• Name the mathematical object behind the code — which operator, which square root,
  which convergence rate or spectral convention.
• Flag numerical hazards: conditioning and indefiniteness, jitter/nugget choice,
  RNG-stream stability, normalization/2π conventions, aliasing, quadrature error.
• One sentence = one insight.
• Do not explain what is obvious.
• Use plain Unicode math (Σ, λ, ω, 𝒞); no LaTeX.
"""
model, tokenizer, *_ = load("lmstudio-community/Qwen2.5-Coder-7B-Instruct-MLX-4bit")
draft_model, *_ = load("lmstudio-community/Qwen2.5-Coder-0.5B-Instruct-MLX-4bit")

class ChatRequest(BaseModel):
    messages: list

@app.post("/v1/chat/completions")
async def chat(request: ChatRequest):
    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + request.messages

    prompt = tokenizer.apply_chat_template(
        messages, tokenize=False, add_generation_prompt=True
    )

    def generate():
        stream = stream_generate(
            model,
            tokenizer,
            draft_model=draft_model,
            prompt=prompt,
            max_tokens=2048,
            #temperature=0.1,
            #top_p=0.95,
            #top_k=30,
            #repetition_penalty=1.0,
            kv_bits=8,
            max_kv_size=16384,
        )

        for response in stream:
            # Format as OpenAI-compatible stream for your Neovim plugin
            chunk = {"choices": [{"delta": {"content": response.text}}]}
            yield f"data: {json.dumps(chunk)}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate(), media_type="text/event-stream")

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8080)
