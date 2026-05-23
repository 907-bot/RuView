from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
import logging
import os

logger = logging.getLogger("ruview")
handler = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s %(levelname)s %(name)s - %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO if os.getenv("ENVIRONMENT","development") == "production" else logging.DEBUG)

app = FastAPI(title="RuView Demo Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Instrument prometheus before the application starts (must not add middleware during startup)
try:
    Instrumentator().instrument(app).expose(app)
    logger.info("Prometheus instrumentation enabled")
except Exception:
    # If instrumentation fails for any reason at import time, log and continue.
    logger.exception("Prometheus instrumentation failed to initialize")


@app.get("/health")
def health():
    # Minimal health check for orchestrators
    return {"status": "ok", "demo_mode": True}


@app.get("/ws/pose")
def ws_placeholder():
    # This demo image exposes the WebSocket path in production servers.
    return {"msg": "Use a real WebSocket server for live poses. Use Docker compose demo mode."}


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled exception: %s", exc)
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})
