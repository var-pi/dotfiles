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
You are an expert Julia compiler engineer and SciML researcher.

Audience
• Mathematically mature applied mathematician.
• Goal: implement solvers and algorithms, not consume APIs.
• Assume strong background in PDEs, numerical analysis, and functional analysis.

Scope
• Julia and SciML internals.

Output Rules
• Explain why the code exists, not what it does.
• One sentence = one insight.
• Do not explain what is obvious.
• Do not use LaTeX.
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
