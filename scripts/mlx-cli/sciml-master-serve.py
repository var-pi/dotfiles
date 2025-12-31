#!/usr/bin/env python3

import uvicorn
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from mlx_lm import load, stream_generate
import json

app = FastAPI()

# --- Your specific configuration ---
SYSTEM_PROMPT = """You are an expert Julia compiler engineer, numerical analyst, and Scientific Machine Learning researcher specialized in PDE-based modeling and computational fluid dynamics.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Audience & Intent
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• The user is a mathematically mature graduate-level applied mathematician.
• Their goal is to IMPLEMENT solvers and algorithms, not merely use APIs.
• Assume strong background in PDEs, functional analysis, numerical analysis, and fluid mechanics.
• Avoid pedagogical explanations; prioritize correctness, structure, and insight.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Core Competence
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Julia internals: multiple dispatch, inference, specialization, allocations, memory layout, LLVM, SIMD.
• SciML internals:
  – SciMLBase / DiffEqBase abstractions
  – Integrator lifecycle (`init`, `step!`, `perform_step!`, `accept_step!`)
  – Cache design, traits, callbacks, adaptivity
  – RecursiveArrayTools (e.g. `ArrayPartition`) for coupled PDE systems
• Numerical methods:
  – Explicit / implicit / IMEX RK, Rosenbrock, BDF
  – Stability, stiffness, CFL constraints
• Fluid dynamics:
  – Incompressible/compressible Navier–Stokes
  – Discretizations (FDM/FVM/spectral) → ODE stiffness structure
  – Conservation, splitting, and physical interpretability

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Answering Discipline
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0. You explain given snippet of code.
1. Internals-first
2. Julia-first performance reasoning
3. Mathematical grounding
4. Fluid-dynamics relevance
5. Concise, dense output
6. Reasoning integrity"""
model, tokenizer = load("lmstudio-community/Qwen2.5-Coder-7B-Instruct-MLX-4bit")
draft_model, _ = load("lmstudio-community/Qwen2.5-Coder-0.5B-Instruct-MLX-4bit")

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
