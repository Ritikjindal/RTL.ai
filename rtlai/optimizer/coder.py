# rtlai/optimizer/coder.py
from rtlai.optimizer.llm_client import call_claude
from rtlai.optimizer.config import CODER_MODEL

CODER_SYSTEM_PROMPT = """You are an expert Verilog RTL engineer. You will be given a baseline Verilog module and a
specific structural change to make to it. Your job is to write the COMPLETE modified Verilog code implementing
that exact change.

Rules you must follow:
- Keep the exact same top-level module name, and the exact same port list (names, directions, widths) as the
  baseline. This is required for equivalence checking - do not rename, reorder, add, or remove any port.
- Implement precisely the change described in the plan. Do not add unrelated changes or "improvements" that were
  not asked for.
- You may add helper submodules (e.g. a full_adder) in the same file if the plan calls for one.
- NEVER declare a `wire` inside an `always` block - this is illegal Verilog. If the plan describes intermediate
  combinational signals (e.g. "wire sub = ..."), declare them as `wire` at module scope with a separate
  `assign` statement BEFORE the always block, then just reference that wire's name inside the always block.
  Alternatively, compute the value inline as a plain expression inside the always block without declaring
  anything.
- Output ONLY the Verilog code, inside a single ```verilog code block. Do not include any explanation before or
  after the code block.
"""


def build_coder_prompt(rtl_code: str, plan: str) -> str:
    return (
        "Baseline Verilog module:\n"
        "```verilog\n"
        f"{rtl_code}\n"
        "```\n\n"
        "Plan to implement:\n"
        f"{plan}\n\n"
        "Write the complete modified Verilog module implementing this plan, following all the rules above."
    )


def extract_verilog(text: str) -> str:
    """Pulls the code out of a ```verilog ... ``` block. Falls back to the raw text if no block is found."""
    marker = "```verilog"
    start = text.find(marker)
    if start == -1:
        start = text.find("```")
        if start == -1:
            return text.strip()
        start += 3
    else:
        start += len(marker)
    end = text.find("```", start)
    if end == -1:
        return text[start:].strip()
    return text[start:end].strip()


def generate_code(rtl_code: str, plan: str) -> str:
    prompt = build_coder_prompt(rtl_code, plan)
    reply = call_claude(
        model=CODER_MODEL,
        system_prompt=CODER_SYSTEM_PROMPT,
        user_prompt=prompt,
        max_tokens=4096,
    )
    return extract_verilog(reply)