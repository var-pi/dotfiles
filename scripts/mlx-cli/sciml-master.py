#!/usr/bin/env python3
from mlx_lm import load, stream_generate


# ------------------------------------------------------------------------------
# System prompt
# ------------------------------------------------------------------------------

SYSTEM = """You are an expert Julia compiler engineer, numerical analyst, and Scientific Machine Learning researcher
specialized in PDE-based modeling and computational fluid dynamics.

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
1. Internals-first
2. Julia-first performance reasoning
3. Mathematical grounding
4. Fluid-dynamics relevance
5. Concise, dense output
6. Reasoning integrity
"""

# ------------------------------------------------------------------------------
# Load models
# ------------------------------------------------------------------------------

model, tokenizer = load("lmstudio-community/Qwen2.5-Coder-7B-Instruct-MLX-4bit")
draft_model, _ = load("lmstudio-community/Qwen2.5-Coder-0.5B-Instruct-MLX-4bit")

# ------------------------------------------------------------------------------
# Chat loop
# ------------------------------------------------------------------------------

def chat():
    print("Entering chat. Ctrl-D or Ctrl-C to exit.\n")

    messages = [{"role": "system", "content": SYSTEM}]

    while True:
        try:
            user_input = input(">>> ")
        except (EOFError, KeyboardInterrupt):
            print()
            break

        messages.append({"role": "user", "content": user_input})

        prompt = tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )

        response = stream_generate(
            model,
            tokenizer,
            draft_model=draft_model,
            prompt=prompt,
            max_tokens=2048,
            temperature=0.1,
            top_p=0.95,
            top_k=30,
            repetition_penalty=1.0,
            kv_bits=8,
            max_kv_size=16384,
        )

        response_total = ""
        for response in stream_generate(model, tokenizer, prompt, max_tokens=512):
            print(response.text, end="", flush=True)
            response_total += response.text
        print()

        assistant_text = response_total.strip()
        messages.append(
            {"role": "assistant", "content": assistant_text}
        )


if __name__ == "__main__":
    chat()

