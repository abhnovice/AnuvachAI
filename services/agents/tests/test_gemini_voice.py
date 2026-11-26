from __future__ import annotations

import asyncio
import base64
import json
import logging
import os
import shutil
import subprocess
import time
from collections import Counter
import unicodedata

import pytest
import uvicorn
import websockets

from anuvach_agents.fake_adapters import SQLiteFakeAdapters
from anuvach_agents.workbench import create_app, gemini_configured
from test_language_matrix import LANGUAGE_CASES, free_port


def make_pcm(language, statement):
    speech = subprocess.check_output(["espeak-ng", "--stdout", "-v", language, statement])
    return subprocess.check_output([
        "ffmpeg", "-hide_banner", "-loglevel", "error", "-i", "pipe:0",
        "-f", "s16le", "-ar", "16000", "-ac", "1", "pipe:1",
    ], input=speech)


def words(text):
    return Counter(unicodedata.normalize("NFC", "".join(
        char for char in text.casefold() if not unicodedata.category(char).startswith("P")
    )).split())


@pytest.mark.gemini_voice
def test_gemini_synthesized_speech_matrix(tmp_path):
    assert gemini_configured(), "Gemini credential missing from services/agents/.env"
    assert shutil.which("espeak-ng") and shutil.which("ffmpeg"), "Speech fixture binaries missing"
    port = free_port()
    adapter = SQLiteFakeAdapters(tmp_path / "voice.sqlite")

    app = create_app(adapter)

    async def run():
        peer = uvicorn.Server(uvicorn.Config(
            app, host="127.0.0.1", port=port, log_config=None,
        ))
        task = asyncio.create_task(peer.serve())
        results = []
        try:
            async with asyncio.timeout(10):
                while not peer.started:
                    await asyncio.sleep(0.02)
            for language, statement in LANGUAGE_CASES.items():
                selected = os.getenv("STAGE3_VOICE_LANGUAGES")
                if "-" in language or (selected and language not in selected.split(",")):
                    continue
                pcm = make_pcm(language, statement)
                row = {"language": language, "fixture": "eSpeak NG PCM over workbench WebSocket",
                       "reference": statement, "input": None, "output": None,
                       "time_to_first_audio_ms": None}
                results.append(row)
                uri = f"ws://127.0.0.1:{port}/api/live?language={language}"
                try:
                    async with websockets.connect(uri) as socket, asyncio.timeout(30):
                        await socket.recv()
                        started = time.perf_counter()

                        async def speak():
                            for offset in range(0, len(pcm), 3200):
                                await socket.send(json.dumps({
                                    "type": "audio", "data": base64.b64encode(
                                        pcm[offset:offset + 3200]
                                    ).decode("ascii"),
                                }))
                                await asyncio.sleep(0.1)
                            await socket.send('{"type":"audio_end"}')

                        speaker = asyncio.create_task(speak())
                        try:
                            while not all(row[key] for key in ("input", "output", "time_to_first_audio_ms")):
                                message = json.loads(await socket.recv())
                                if message["type"] == "error":
                                    row["error"] = message["message"]
                                    break
                                if message["type"] == "audio" and row["time_to_first_audio_ms"] is None:
                                    row["time_to_first_audio_ms"] = round((time.perf_counter() - started) * 1000)
                                if message["type"] == "transcript" and not message["partial"]:
                                    if message["role"] == "employee":
                                        row["input"] = message["text"]
                                        row["saved_verbatim"] = message["draft"]["facts"][-1]["text"] == message["text"]
                                        row["reference_word_recall"] = sum(
                                            (words(statement) & words(message["text"])).values()
                                        ) / words(statement).total()
                                    else:
                                        row["output"] = message["text"]
                        finally:
                            if all(row[key] for key in ("input", "output", "time_to_first_audio_ms")):
                                await speaker
                            speaker.cancel()
                            await asyncio.gather(speaker, return_exceptions=True)
                except (TimeoutError, websockets.ConnectionClosed) as error:
                    row["error"] = type(error).__name__
                row["corrected_reference"] = statement
                row["input_quality_pass"] = row.get("reference_word_recall", 0) >= 0.8
                for _ in range(30):
                    summaries = [item["result"] for item in app.state.tool_events
                                 if item["tool"] == "reporting_voice"
                                 and item["result"].get("language") == language
                                 and "usage" in item["result"]]
                    if summaries:
                        row["usage"] = summaries[-1]["usage"]
                        break
                    await asyncio.sleep(0.02)
                print(json.dumps(row, ensure_ascii=False), flush=True)
            assert all(row.get("saved_verbatim") and row["input_quality_pass"]
                       and row["output"] and row["time_to_first_audio_ms"]
                       for row in results), "See per-language audio transport results above"
        finally:
            peer.should_exit = True
            await task

    previous_disable = logging.root.manager.disable
    logging.disable(logging.CRITICAL)
    try:
        asyncio.run(run())
    finally:
        logging.disable(previous_disable)
