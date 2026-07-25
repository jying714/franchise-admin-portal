"""
xai_client.py
-------------
Async client for the xAI API (OpenAI-compatible chat completions).

- Reads XAI_API_KEY from the environment (never commit the key).
- Returns model text only — does NOT touch git, Firestore, or disk apply.
- Optional x-grok-conv-id for prompt-cache affinity (stable prefix per agent).

Docs: https://docs.x.ai
"""

from __future__ import annotations

import logging
import os
from typing import Optional

import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception

logger = logging.getLogger("orchestrator.xai")

DEFAULT_BASE_URL = "https://api.x.ai/v1"
DEFAULT_MODEL = os.getenv("XAI_MODEL", "grok-4.5")


def _is_retryable(exc: BaseException) -> bool:
    if isinstance(exc, httpx.HTTPStatusError):
        return exc.response.status_code in (429, 502, 503, 504)
    return isinstance(exc, (httpx.ConnectError, httpx.ReadTimeout, httpx.WriteTimeout))


class XaiClient:
    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,
        default_model: Optional[str] = None,
    ):
        self.api_key = (api_key or os.getenv("XAI_API_KEY", "")).strip()
        self.base_url = (base_url or os.getenv("XAI_BASE_URL", DEFAULT_BASE_URL)).rstrip("/")
        self.default_model = default_model or DEFAULT_MODEL
        self._client = httpx.AsyncClient(timeout=600.0)

    @property
    def configured(self) -> bool:
        return bool(self.api_key)

    async def close(self) -> None:
        await self._client.aclose()

    async def ping(self) -> bool:
        if not self.api_key:
            return False
        return True

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=20),
        retry=retry_if_exception(_is_retryable),
        reraise=True,
    )
    async def generate(
        self,
        *,
        system: str,
        prompt: str,
        model: Optional[str] = None,
        temperature: float = 0.1,
        max_tokens: Optional[int] = None,
        conv_id: Optional[str] = None,
    ) -> str:
        if not self.api_key:
            raise RuntimeError(
                "XAI_API_KEY is not set. Export it on the host/container before using backend: xai."
            )

        use_model = model or self.default_model
        # Stable message order: system (SCOPE/STATUS) first → better prefix cache hits
        messages = [
            {"role": "system", "content": system},
            {"role": "user", "content": prompt},
        ]
        payload: dict = {
            "model": use_model,
            "messages": messages,
            "temperature": temperature,
        }
        if max_tokens is not None:
            payload["max_tokens"] = max_tokens

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        # Prompt-cache affinity: same agent → prefer same route when platform supports it
        if conv_id:
            headers["x-grok-conv-id"] = conv_id

        logger.info(
            "Calling xAI model=%s temp=%s base=%s conv_id=%s",
            use_model,
            temperature,
            self.base_url,
            conv_id or "-",
        )

        resp = await self._client.post(
            f"{self.base_url}/chat/completions",
            headers=headers,
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()

        choices = data.get("choices") or []
        if not choices:
            return ""
        message = choices[0].get("message") or {}
        content = message.get("content") or ""
        if isinstance(content, list):
            texts = []
            for part in content:
                if isinstance(part, dict) and part.get("type") == "text":
                    texts.append(part.get("text") or "")
                elif isinstance(part, str):
                    texts.append(part)
            content = "".join(texts)
        return str(content).strip()
