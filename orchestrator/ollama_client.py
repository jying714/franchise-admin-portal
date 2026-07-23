"""
ollama_client.py
----------------
Thin async wrapper around the Ollama HTTP API.
Uses the internal Docker network hostname (http://ollama:11434).
"""

from __future__ import annotations

import logging
from typing import AsyncIterator, Optional

import httpx
from tenacity import retry, stop_after_attempt, wait_exponential

logger = logging.getLogger("orchestrator.ollama")


class OllamaClient:
    def __init__(self, base_url: str = "http://ollama:11434"):
        self.base_url = base_url.rstrip("/")
        self._client = httpx.AsyncClient(timeout=120.0)

    async def close(self):
        await self._client.aclose()

    @retry(stop=stop_after_attempt(5), wait=wait_exponential(multiplier=1, min=2, max=30))
    async def list_models(self) -> list[str]:
        resp = await self._client.get(f"{self.base_url}/api/tags")
        resp.raise_for_status()
        data = resp.json()
        return [m["name"] for m in data.get("models", [])]

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=20))
    async def generate(
        self,
        model: str,
        system: str,
        prompt: str,
        temperature: float = 0.2,
        stream: bool = False,
    ) -> str:
        """
        Non-streaming generation (preferred for agent replies).
        Returns the full response text.
        """
        payload = {
            "model": model,
            "system": system,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_ctx": 16384,          # generous context for docs + code
            },
        }

        logger.info(f"Calling Ollama model={model}  temp={temperature}")
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
    ) -> AsyncIterator[str]:
        """Streaming variant (useful for long responses)."""
        payload = {
            "model": model,
            "system": system,
            "prompt": prompt,
            "stream": True,
            "options": {
                "temperature": temperature,
                "num_ctx": 16384,
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
