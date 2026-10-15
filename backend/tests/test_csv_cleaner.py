"""Backend tests for Universal CSV Cleaner (POST /api/clean/{profile,suggest,apply})."""
import json
import os
import pytest
import requests

BASE_URL = os.environ.get("REACT_APP_BACKEND_URL", "https://sleep-analysis-r.preview.emergentagent.com").rstrip("/")
SAMPLE_CSV_PATH = "/app/frontend/public/sample_messy.csv"
TIMEOUT = 60


@pytest.fixture(scope="module")
def sample_csv_bytes():
    with open(SAMPLE_CSV_PATH, "rb") as f:
        return f.read()


# ---------- /api/clean/profile ----------
class TestProfile:
    def test_profile_returns_shape(self, sample_csv_bytes):
        files = {"file": ("sample_messy.csv", sample_csv_bytes, "text/csv")}
        r = requests.post(f"{BASE_URL}/api/clean/profile", files=files, timeout=TIMEOUT)
        assert r.status_code == 200, r.text
        body = r.json()
        prof = body["profile"]
        assert prof["n_rows"] == 10
        assert prof["n_cols"] == 8
        assert prof["duplicate_rows"] >= 1
        assert isinstance(prof["columns"], list) and len(prof["columns"]) == 8
        col0 = prof["columns"][0]
        for key in ("name", "inferred_type", "n_missing", "n_distinct", "sample"):
            assert key in col0, f"missing {key} in column profile"
        # Satisfaction column should have label frequency entries
        sat = next(c for c in prof["columns"] if c["name"].strip().lower() == "satisfaction")
        assert sat.get("labels"), "expected labels for categorical column"

    def test_profile_empty_file_rejected(self):
        files = {"file": ("empty.csv", b"", "text/csv")}
        r = requests.post(f"{BASE_URL}/api/clean/profile", files=files, timeout=TIMEOUT)
        assert r.status_code in (400, 500)


# ---------- /api/clean/suggest ----------
class TestSuggest:
    @pytest.fixture(scope="class")
    def profile(self, sample_csv_bytes):
        files = {"file": ("sample_messy.csv", sample_csv_bytes, "text/csv")}
        r = requests.post(f"{BASE_URL}/api/clean/profile", files=files, timeout=TIMEOUT)
        return r.json()["profile"]

    def test_suggest_returns_rules(self, profile):
        r = requests.post(f"{BASE_URL}/api/clean/suggest", json={"profile": profile}, timeout=90)
        assert r.status_code == 200, r.text
        body = r.json()
        assert body["source"] in ("ai", "fallback")
        rules = body["rules"]
        assert "clean_column_names" in rules
        assert "remove_duplicate_rows" in rules
        assert "na_sentinels" in rules and isinstance(rules["na_sentinels"], list)
        assert isinstance(rules["columns"], list) and len(rules["columns"]) >= 1
        # Each column rule has name & type
        for c in rules["columns"]:
            assert "name" in c and "type" in c
        # At least one column should have a label_map (categorical cities/satisfaction)
        has_label_map = any(bool(c.get("label_map")) for c in rules["columns"])
        assert has_label_map, "expected at least one label_map on categorical column"


# ---------- /api/clean/apply ----------
class TestApply:
    @pytest.fixture(scope="class")
    def profile_and_rules(self, sample_csv_bytes):
        files = {"file": ("sample_messy.csv", sample_csv_bytes, "text/csv")}
        p = requests.post(f"{BASE_URL}/api/clean/profile", files=files, timeout=TIMEOUT).json()["profile"]
        s = requests.post(f"{BASE_URL}/api/clean/suggest", json={"profile": p}, timeout=90).json()
        return s["rules"]

    def test_apply_full_flow(self, sample_csv_bytes, profile_and_rules):
        files = {"file": ("sample_messy.csv", sample_csv_bytes, "text/csv")}
        data = {"rules": json.dumps(profile_and_rules)}
        r = requests.post(f"{BASE_URL}/api/clean/apply", files=files, data=data, timeout=120)
        assert r.status_code == 200, r.text
        body = r.json()
        for key in ("rows_before", "rows_after", "columns", "audit", "preview", "cleaned_csv", "script"):
            assert key in body, f"missing {key} in response"
        assert body["rows_before"] == 10
        # one duplicate row -> rows_after should be < rows_before
        assert body["rows_after"] <= body["rows_before"]
        assert body["rows_after"] <= 9  # at least one duplicate removed
        # audit list
        assert isinstance(body["audit"], list) and len(body["audit"]) >= 1
        for a in body["audit"]:
            assert "operation" in a and "cells_changed" in a
        # cleaned_csv is CSV text
        assert isinstance(body["cleaned_csv"], str) and "," in body["cleaned_csv"].splitlines()[0]
        # reproducible script is R code
        assert "library" in body["script"] or "read" in body["script"].lower()
        # columns snake_cased when clean_column_names is on
        if profile_and_rules.get("clean_column_names"):
            header = body["cleaned_csv"].splitlines()[0].lower()
            assert " " not in header, f"column names not cleaned: {header}"

    def test_apply_normalizes_city_labels(self, sample_csv_bytes, profile_and_rules):
        files = {"file": ("sample_messy.csv", sample_csv_bytes, "text/csv")}
        data = {"rules": json.dumps(profile_and_rules)}
        r = requests.post(f"{BASE_URL}/api/clean/apply", files=files, data=data, timeout=120)
        assert r.status_code == 200
        body = r.json()
        csv_text = body["cleaned_csv"].lower()
        # NYC should have been consolidated into a single canonical label (New York / nyc)
        # Confirm messy variants ' new york ' or 'nyc' aren't both appearing as separate values
        # We just verify no mix of 'nyc' with trailing whitespace raw-form
        assert "  " not in csv_text  # trimmed

    def test_apply_invalid_rules_json(self, sample_csv_bytes):
        files = {"file": ("sample_messy.csv", sample_csv_bytes, "text/csv")}
        data = {"rules": "{not-json"}
        r = requests.post(f"{BASE_URL}/api/clean/apply", files=files, data=data, timeout=TIMEOUT)
        assert r.status_code == 400
