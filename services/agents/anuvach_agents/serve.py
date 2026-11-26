from __future__ import annotations

import asyncio
import logging
import os
from pathlib import Path

import uvicorn
from dotenv import load_dotenv


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

from .a2a_server import HOST as A2A_HOST
from .a2a_server import PORT as A2A_PORT
from .a2a_server import a2a_app
from .workbench import app as workbench_app


class CredentialRedactingFormatter(logging.Formatter):
    def __init__(self, formatter: logging.Formatter | None) -> None:
        super().__init__()
        self.formatter = formatter or logging.Formatter()

    def format(self, record: logging.LogRecord) -> str:
        message = self.formatter.format(record)
        for name in ("GOOGLE_API_KEY", "GEMINI_API_KEY"):
            if secret := os.getenv(name):
                message = message.replace(secret, "[redacted]")
        return message


async def serve() -> None:
    logging.basicConfig(level=logging.WARNING)
    workbench_host = os.getenv("WORKBENCH_HOST", "127.0.0.1")
    workbench_port = int(os.getenv("WORKBENCH_PORT", "8000"))
    servers = [
        uvicorn.Server(
            uvicorn.Config(a2a_app, host=A2A_HOST, port=A2A_PORT, log_level="info")
        ),
        uvicorn.Server(
            uvicorn.Config(
                workbench_app,
                host=workbench_host,
                port=workbench_port,
                log_level="info",
            )
        ),
    ]
    for name in ("", "uvicorn", "uvicorn.access"):
        for handler in logging.getLogger(name).handlers:
            handler.setFormatter(CredentialRedactingFormatter(handler.formatter))
    print(f"A2A triage endpoint: http://{A2A_HOST}:{A2A_PORT}")
    print(f"Developer workbench: http://{workbench_host}:{workbench_port}")
    try:
        await asyncio.gather(*(server.serve() for server in servers))
    finally:
        for server in servers:
            server.should_exit = True


def main() -> None:
    asyncio.run(serve())


if __name__ == "__main__":
    main()