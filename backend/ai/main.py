import os
from typing import Any

import httpx
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Optimistic AI", version="3.0.0")

AI_API_URL = os.getenv("AI_API_URL", "").strip()
AI_API_KEY = os.getenv("AI_API_KEY", "").strip()
AI_MODEL = os.getenv("AI_MODEL", "").strip()


class AskRequest(BaseModel):
    prompt: str = Field(min_length=1, max_length=12000)
    pageUrl: str = ""
    pageTitle: str = ""
    pageText: str = Field(default="", max_length=60000)
    model: str = Field(default="auto", max_length=32)


def local_answer(prompt: str, page_title: str, page_url: str) -> str:
    p = prompt.strip()
    lower = p.lower()
    context = []
    if page_title:
        context.append(f"Current page: {page_title}")
    if page_url:
        context.append(f"URL: {page_url}")
    prefix = "\n".join(context)

    if "hello" in lower or "hi" in lower:
        answer = "Hello! I am Optimistic AI, the Python AI service inside Optimistic Browser."
    elif "who are you" in lower:
        answer = "I am Optimistic AI. My application-side AI endpoint is implemented in Python with FastAPI."
    elif "summarize" in lower:
        answer = "Summary mode is ready. Connect an AI_API_URL, AI_API_KEY and AI_MODEL for full remote summarization."
    elif "code" in lower or "flutter" in lower:
        answer = "For Flutter, keep UI in Dart, web UI in HTML/CSS/JavaScript, and AI orchestration/secrets in this Python service."
    else:
        answer = (
            f"I received: {p}\n\n"
            "Offline Python AI mode is active. Configure the OpenAI-compatible "
            "environment variables for model-backed answers."
        )

    return f"{prefix}\n\n{answer}".strip()


async def remote_answer(request: AskRequest) -> str:
    clean_text = " ".join(request.pageText.split())[:60000]
    context = "\n".join(
        item for item in (
            f"Page title: {request.pageTitle}" if request.pageTitle else "",
            f"Page URL: {request.pageUrl}" if request.pageUrl else "",
            f"Page text:\n{clean_text}" if clean_text else "",
        ) if item
    )
    requested_model = request.model if request.model in {"auto", "fast", "balanced", "reasoning"} else "auto"
    provider_model = AI_MODEL
    if requested_model == "fast":
        provider_model = os.getenv("AI_FAST_MODEL", AI_MODEL).strip() or AI_MODEL
    elif requested_model == "reasoning":
        provider_model = os.getenv("AI_REASONING_MODEL", AI_MODEL).strip() or AI_MODEL
    elif requested_model == "balanced":
        provider_model = os.getenv("AI_BALANCED_MODEL", AI_MODEL).strip() or AI_MODEL

    payload = {
        "model": provider_model,
        "messages": [
            {
                "role": "system",
                "content": "You are Optimistic AI inside a private browser. Be useful, concise and safe.",
            },
            {"role": "user", "content": f"{context}\n\nUser request:\n{request.prompt}"},
        ],
    }
    async with httpx.AsyncClient(timeout=45) as client:
        response = await client.post(
            AI_API_URL,
            headers={
                "Authorization": f"Bearer {AI_API_KEY}",
                "Content-Type": "application/json",
            },
            json=payload,
        )
    try:
        data: Any = response.json()
    except Exception:
        data = {}
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail={"type": "ai_provider", "message": "AI provider error."})
    return str(
        data.get("choices", [{}])[0]
        .get("message", {})
        .get("content", "No answer returned.")
    )


@app.get("/health")
async def health() -> dict[str, Any]:
    return {"ok": True, "service": "optimistic-ai-python", "mode": "remote" if AI_API_URL else "offline"}


@app.post("/api/ai")
async def ask(request: AskRequest) -> dict[str, str]:
    if not request.prompt.strip():
        raise HTTPException(status_code=400, detail="Prompt is required.")
    if AI_API_URL and AI_API_KEY and AI_MODEL:
        return {"answer": await remote_answer(request)}
    return {"answer": local_answer(request.prompt, request.pageTitle, request.pageUrl)}
