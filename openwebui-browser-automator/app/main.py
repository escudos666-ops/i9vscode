import os
from typing import List, Literal, Optional
from urllib.parse import urlparse

from fastapi import Depends, FastAPI, Header, HTTPException
from pydantic import BaseModel, Field
from playwright.async_api import async_playwright


def _env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


API_TOKEN = os.getenv("AUTOMATOR_API_TOKEN", "")
ALLOWED_HOSTS = {
    h.strip().lower()
    for h in os.getenv("AUTOMATOR_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
    if h.strip()
}
HEADLESS = _env_bool("AUTOMATOR_HEADLESS", True)


class FormField(BaseModel):
    selector: str = Field(..., description="CSS selector for an input/select element")
    value: str = Field(..., description="Value to type/select/set")
    action: Literal["type", "select", "check", "uncheck"] = "type"


class FillFormRequest(BaseModel):
    url: str
    fields: List[FormField]
    submit_selector: Optional[str] = None
    wait_for_selector: Optional[str] = None
    wait_after_ms: int = 1000
    timeout_ms: int = 15000


class FillFormResponse(BaseModel):
    ok: bool
    final_url: str
    title: str


def _validate_url(url: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise HTTPException(status_code=400, detail="Only http/https URLs are allowed")
    host = (parsed.hostname or "").lower()
    if host not in ALLOWED_HOSTS:
        raise HTTPException(
            status_code=403,
            detail=f"Host '{host}' is not in allowlist: {sorted(ALLOWED_HOSTS)}",
        )


def _auth(authorization: Optional[str] = Header(default=None)) -> None:
    if not API_TOKEN:
        return
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.split(" ", 1)[1].strip()
    if token != API_TOKEN:
        raise HTTPException(status_code=401, detail="Invalid bearer token")


app = FastAPI(title="OpenWebUI Browser Automator", version="1.0.0")


@app.get("/health")
async def health() -> dict:
    return {"ok": True, "allowed_hosts": sorted(ALLOWED_HOSTS), "headless": HEADLESS}


@app.post("/fill-form", response_model=FillFormResponse, dependencies=[Depends(_auth)])
async def fill_form(req: FillFormRequest) -> FillFormResponse:
    _validate_url(req.url)

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=HEADLESS)
        context = await browser.new_context()
        page = await context.new_page()
        page.set_default_timeout(req.timeout_ms)

        await page.goto(req.url, wait_until="domcontentloaded")

        for field in req.fields:
            match field.action:
                case "type":
                    await page.fill(field.selector, field.value)
                case "select":
                    await page.select_option(field.selector, field.value)
                case "check":
                    await page.check(field.selector)
                case "uncheck":
                    await page.uncheck(field.selector)

        if req.submit_selector:
            await page.click(req.submit_selector)

        if req.wait_for_selector:
            await page.wait_for_selector(req.wait_for_selector)

        if req.wait_after_ms > 0:
            await page.wait_for_timeout(req.wait_after_ms)

        result = FillFormResponse(ok=True, final_url=page.url, title=await page.title())
        await context.close()
        await browser.close()
        return result
