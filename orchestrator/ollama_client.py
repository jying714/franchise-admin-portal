"""
ollama_client.py
----------------
Thin async wrapper around the Ollama HTTP API.
Uses the internal Docker network hostname (http://ollama:11434).

Features:
  - Configurable num_ctx (default 8192 — safer for 14B models)
  - Automatic fallback to 7B model on HTTP 500 (OOM / internal error)
  - Retry decorator no longer swallows 500s before fallback can run
"""

from __future__ import annotations

import logging
from typing import AsyncIterator, Optional

import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception

logger = logging.getLogger("orchestrator.ollama")

FALLBACK_MODEL = "qwen2.5-coder:7b"


def _is_retryable(exc: BaseException) -> bool:
    """Only retry transient network / 429 / 503 errors — never retry 500 (OOM)."""
    if isinstance(exc, httpx.HTTPStatusError):
        # 500 is usually OOM / model crash → fall through to fallback, do not retry same model
        return exc.response.status_code in (429, 502, 503, 504)
    # Network blips are retryable
    return isinstance(exc, (httpx.ConnectError, httpx.ReadTimeout, httpx.WriteTimeout))


class OllamaClient:
    def __init__(self, base_url: str = "http://ollama:11434"):
        self.base_url = base_url.rstrip("/")
        self._client = httpx.AsyncClient(timeout=180.0)  # longer timeout for large models

    async def close(self):
        await self._client.aclose()

    @retry(stop=stop_after_attempt(5), wait=wait_exponential(multiplier=1, min=2, max=30))
    async def list_models(self) -> list[str]:
        resp = await self._client.get(f"{self.base_url}/api/tags")
        resp.raise_for_status()
        data = resp.json()
        return [m["name"] for m in data.get("models", [])]

    async def generate(
        self,
        model: str,
        system: str,
        prompt: str,
        temperature: float = 0.2,
        num_ctx: int = 8192,
        stream: bool = False,
    ) -> str:
        """
        Non-streaming generation.
        On HTTP 500 (typical OOM / internal error) automatically retries once
        with the lighter 7B model and a safer context window.
        """
        try:
            return await self._generate_once(
                model=model,
                system=system,
                prompt=prompt,
                temperature=temperature,
                num_ctx=num_ctx,
            )
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 500 and model != FALLBACK_MODEL:
                logger.warning(
                    f"Model {model} returned 500 — falling back to {FALLBACK_MODEL} with num_ctx=8192"
                )
                return await self._generate_once(
                    model=FALLBACK_MODEL,
                    system=system,
                    prompt=prompt,
                    temperature=temperature,
                    num_ctx=8192,
                )
            raise

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=15),
        retry=retry_if_exception(_is_retryable),
        reraise=True,
    )
    async def _generate_once(
        self,
        model: str,
        system: str,
        prompt: str,
        temperature: float,
        num_ctx: int,
    ) -> str:
        payload = {
            "model": model,
            "system": system,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_ctx": num_ctx,
            },
        }

        logger.info(f"Calling Ollama model={model}  temp={temperature}  num_ctx={num_ctx}")
        resp = await self._client.post(f"{self.base_url}/api/generate", json=payload)
        resp.raise_for_status()
        data = resp.json()
        return data.get("response", "").strip()

    async def stream_generate(
        self,
        model: str,
        system: str,
        prompt: str,
        temperature: float = 0.2,
        num_ctx: int = 8192,
    ) -> AsyncIterator[str]:
        """Streaming variant (useful for long responses)."""
        payload = {
            "model": model,
            "system": system,
            "prompt": prompt,
            "stream": True,
            "options": {
                "temperature": temperature,
                "num_ctx": num_ctx,
            },
        }

        async with self._client.stream("POST", f"{self.base_url}/api/generate", json=payload) as resp:
            resp.raise_for_status()
            async for line in resp.aiter_lines():
                if not line:
                    continue
                import json
                chunk = json.loads(line)
                if token := chunk.get("response"):
                    yield token
                if chunk.get("done"):
                    break
