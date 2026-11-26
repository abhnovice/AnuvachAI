import pytest


def pytest_addoption(parser):
    parser.addoption("--gemini", action="store_true", help="Run the live Gemini text gate")
    parser.addoption("--gemini-voice", action="store_true", help="Run the live PCM speech gate")


@pytest.fixture(autouse=True)
def isolate_offline_tests(monkeypatch, request):
    if request.node.get_closest_marker("gemini_voice"):
        if not request.config.getoption("--gemini-voice"):
            pytest.skip("live speech gate requires --gemini-voice")
        return
    if request.node.get_closest_marker("gemini"):
        if not request.config.getoption("--gemini"):
            pytest.skip("live Gemini gate requires --gemini")
        return
    for key in ("GOOGLE_API_KEY", "GEMINI_API_KEY"):
        monkeypatch.delenv(key, raising=False)
