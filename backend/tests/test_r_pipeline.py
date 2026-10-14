"""Backend tests for the Reproducible Research R-backed API."""
import os
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://sleep-analysis-r.preview.emergentagent.com").rstrip("/")
API = f"{BASE_URL}/api"


@pytest.fixture(scope="session")
def s():
    sess = requests.Session()
    return sess


def test_health(s):
    r = s.get(f"{API}/health", timeout=60)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data.get("r_available") is True
    assert data.get("r_version", "").startswith("4.2")
    assert data.get("packages_ok") is True


def test_run_analysis(s):
    r = s.post(f"{API}/analysis/run", timeout=180)
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["success"] is True
    assert data["exit_code"] == 0


def test_results(s):
    r = s.get(f"{API}/analysis/results", timeout=60)
    assert r.status_code == 200
    d = r.json()
    summary = d["summary"]
    assert int(summary["raw_rows"]) == 1020
    assert int(summary["cleaned_rows"]) == 1000
    assert int(summary["duplicate_rows_removed"]) == 20
    assert d["missing"] and d["invalid"] is not None
    assert d["descriptive"]
    assert d["frequency"]["gender"] and d["frequency"]["sleep_quality"] and d["frequency"]["mood"]
    cm = d["correlation_matrix"]
    assert cm and cm["variables"] and cm["matrix"]
    assert len(d["key_correlations"]) == 3
    assert d["raw_preview"] and d["cleaned_preview"]


def test_run_tests_endpoint(s):
    r = s.post(f"{API}/tests/run", timeout=120)
    assert r.status_code == 200, r.text
    d = r.json()
    assert d["passed"] is True
    assert d["success"] is True
    assert "test" in d["output"].lower()


@pytest.mark.parametrize("key", ["sleep_hist", "sleep_wellbeing", "wellbeing_by_quality", "corr_heatmap"])
def test_figures(s, key):
    r = s.get(f"{API}/analysis/figures/{key}", timeout=60)
    assert r.status_code == 200
    assert r.headers["content-type"].startswith("image/png")
    assert r.content[:8] == b"\x89PNG\r\n\x1a\n"


@pytest.mark.parametrize("which", ["raw", "clean"])
def test_dataset_download(s, which):
    r = s.get(f"{API}/dataset/download", params={"which": which}, timeout=60)
    assert r.status_code == 200
    assert "csv" in r.headers["content-type"]
    assert r.text.count("\n") > 100
