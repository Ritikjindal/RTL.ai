# rtlai/optimizer/llm_client.py
import os
from anthropic import Anthropic

_client = None


def get_client() -> Anthropic:
    global _client
    if _client is None:
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            raise RuntimeError(
                "ANTHROPIC_API_KEY is not set. Get a key from console.anthropic.com "
                "and run: export ANTHROPIC_API_KEY=\"your-key-here\""
            )
        _client = Anthropic(api_key=api_key)
    return _client


def call_claude(model: str, system_prompt: str, user_prompt: str, max_tokens: int = 8192) -> str:
    client = get_client()
    response = client.messages.create(
        model=model,
        max_tokens=max_tokens,
        system=system_prompt,
        messages=[{"role": "user", "content": user_prompt}],
    )
    if response.stop_reason == "max_tokens":
        raise RuntimeError(
            f"Model hit the {max_tokens}-token limit before finishing. Raise max_tokens for this call."
        )
    text_parts = [block.text for block in response.content if getattr(block, "type", None) == "text"]
    return "\n".join(text_parts)