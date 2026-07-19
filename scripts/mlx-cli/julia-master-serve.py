#!/usr/bin/env python3

from mlx_lm.chat_templates.deepseek_v32 import thinking_template
import token
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

Structure
    
    ━━━ Summary ━━━

    High signal concise summary

    ━━━ Background ━━━

    Required background

    ━━━ Details ━━━

    Important details

Output Rules
• Explain why the code exists, not what it does.
• Name the mathematical object behind the code — which operator, which square root,
  which convergence rate or spectral convention.
• One sentence = one insight.
• Do not explain what is obvious.
"""
model, tokenizer, *_ = load("mlx-community/Qwen3.5-9B-5bit")
#draft_model, *_ = load("mlx-community/Qwen3.5-9B-MTP-5bit")

class ChatRequest(BaseModel):
    messages: list

@app.post("/v1/chat/completions")
async def chat(request: ChatRequest):
    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + request.messages

    prompt = tokenizer.apply_chat_template(
        messages,
        tokenize=False,
        add_generation_prompt=True,
        enable_thinking=False
    )

    def generate():
        stream = stream_generate(
            model,
            tokenizer,
            #draft_model=draft_model,
            prompt=prompt,
            max_tokens=2048,
            #mtp=True,
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
