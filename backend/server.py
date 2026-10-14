from fastapi import FastAPI, APIRouter, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse, PlainTextResponse
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import logging
import subprocess
import csv
import json
import uuid
import asyncio
import tempfile
from pathlib import Path


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# The R project lives at the repository root (one level above /app/backend).
R_PROJECT_DIR = ROOT_DIR.parent
RSCRIPT = os.environ.get("RSCRIPT_BIN", "Rscript")
R_TIMEOUT = int(os.environ.get("R_TIMEOUT_SECONDS", "240"))

app = FastAPI(title="Reproducible Research Data Quality API")
api_router = APIRouter(prefix="/api")

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


# --------------------------------------------------------------------------
# Helpers that invoke the REAL R workflow via Rscript
# --------------------------------------------------------------------------
def _run_r(script_rel_path: str, args=None, stdin_data=None) -> dict:
    """Run an R script from the project root and capture its output."""
    script = R_PROJECT_DIR / script_rel_path
    if not script.exists():
        raise HTTPException(status_code=500, detail=f"R script not found: {script_rel_path}")
    cmd = [RSCRIPT, str(script)] + ([str(a) for a in args] if args else [])
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(R_PROJECT_DIR),
            input=stdin_data,
            capture_output=True, text=True, timeout=R_TIMEOUT,
        )
    except FileNotFoundError:
        raise HTTPException(status_code=500,
                            detail="Rscript not found. R is not installed in this environment.")
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="R execution timed out.")
    return {
        "script": script_rel_path,
        "exit_code": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "success": proc.returncode == 0,
    }


def _read_csv(rel_path: str):
    """Read a generated CSV table into a list of dict rows."""
    path = R_PROJECT_DIR / rel_path
    if not path.exists():
        return None
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def _ensure_raw():
    if not (R_PROJECT_DIR / "data/raw/sleep_wellbeing_raw.csv").exists():
        res = _run_r("scripts/make_dataset.R")
        if not res["success"]:
            raise HTTPException(status_code=500, detail="Failed to generate synthetic dataset.")


# --------------------------------------------------------------------------
# API routes
# --------------------------------------------------------------------------
@api_router.get("/")
async def root():
    return {"message": "Reproducible Research Data Quality API", "engine": "R"}


@api_router.get("/health")
def health():
    """Report whether R and the key packages are available."""
    try:
        proc = subprocess.run(
            [RSCRIPT, "-e",
             'cat(as.character(getRversion())); '
             'cat("|"); '
             'cat(all(c("tidyverse","janitor","ggplot2","testthat") %in% rownames(installed.packages())))'],
            capture_output=True, text=True, timeout=60,
        )
        version, _, pkgs = proc.stdout.partition("|")
        return {"r_available": proc.returncode == 0, "r_version": version.strip(),
                "packages_ok": pkgs.strip() == "TRUE"}
    except Exception as e:  # noqa: BLE001
        return {"r_available": False, "error": str(e)}


@api_router.post("/analysis/run")
def run_analysis():
    """Generate the synthetic data (if needed) and run the full R pipeline."""
    _ensure_raw()
    result = _run_r("scripts/run_analysis.R")
    if not result["success"]:
        logger.error("R analysis failed: %s", result["stderr"])
        raise HTTPException(status_code=500,
                            detail={"message": "R analysis failed", **result})
    return result


@api_router.post("/tests/run")
def run_tests():
    """Run the testthat suite via Rscript and return the real console output."""
    result = _run_r("scripts/run_tests.R")
    combined = (result["stdout"] + "\n" + result["stderr"])
    return {**result, "passed": result["success"], "output": combined}


@api_router.get("/analysis/results")
async def analysis_results():
    """Return every generated R output table as JSON (after running the pipeline)."""
    tables_dir = R_PROJECT_DIR / "outputs/tables"
    if not tables_dir.exists():
        raise HTTPException(status_code=404,
                            detail="No results yet. Run the analysis first.")

    summary_rows = _read_csv("outputs/tables/validation_summary.csv") or []
    summary = {r["metric"]: float(r["value"]) for r in summary_rows}

    def corr_matrix():
        rows = _read_csv("outputs/tables/correlation_matrix.csv")
        if not rows:
            return None
        header = [c for c in rows[0].keys()]
        var_key = header[0]
        variables = [r[var_key] for r in rows]
        matrix = [[r[c] for c in header[1:]] for r in rows]
        return {"variables": variables, "columns": header[1:], "matrix": matrix}

    return {
        "summary": summary,
        "missing": _read_csv("outputs/tables/missing_report.csv"),
        "invalid": _read_csv("outputs/tables/invalid_entries_report.csv"),
        "descriptive": _read_csv("outputs/tables/descriptive_stats.csv"),
        "frequency": {
            "gender": _read_csv("outputs/tables/gender_frequency.csv"),
            "sleep_quality": _read_csv("outputs/tables/sleep_quality_frequency.csv"),
            "mood": _read_csv("outputs/tables/mood_frequency.csv"),
        },
        "correlation_matrix": corr_matrix(),
        "key_correlations": _read_csv("outputs/tables/key_correlations.csv"),
        "raw_preview": _read_csv("outputs/tables/raw_preview.csv"),
        "cleaned_preview": _read_csv("outputs/tables/cleaned_preview.csv"),
    }


@api_router.get("/analysis/regression")
def regression():
    """Multiple linear regression of wellbeing on the numeric predictors (lm in R)."""
    import json as _json
    res = _run_r("scripts/regression.R")
    if not res["success"]:
        raise HTTPException(status_code=500, detail={"message": "R regression failed", **res})
    try:
        return _json.loads(res["stdout"])
    except ValueError:
        raise HTTPException(status_code=500, detail="Could not parse R output.")


@api_router.get("/analysis/anova")
def anova(factor: str = "sleep_quality"):
    """One-way ANOVA of wellbeing across a categorical factor, computed in R."""
    import json as _json
    if factor not in ("sleep_quality", "gender", "mood"):
        raise HTTPException(status_code=400, detail="Invalid factor.")
    res = _run_r("scripts/group_comparison.R", [factor])
    if not res["success"]:
        raise HTTPException(status_code=500, detail={"message": "R ANOVA failed", **res})
    try:
        return _json.loads(res["stdout"])
    except ValueError:
        raise HTTPException(status_code=500, detail="Could not parse R output.")


@api_router.get("/analysis/subset")
def subset_analysis(gender: str = "all", sleep_quality: str = "all"):
    """Recompute descriptive stats + key correlations in R on a filtered subset."""
    import json as _json
    allowed_g = {"all", "Male", "Female", "Other"}
    allowed_q = {"all", "Poor", "Fair", "Good", "Excellent"}
    if gender not in allowed_g or sleep_quality not in allowed_q:
        raise HTTPException(status_code=400, detail="Invalid filter value.")
    res = _run_r("scripts/subset_analysis.R", [gender, sleep_quality])
    if not res["success"]:
        raise HTTPException(status_code=500, detail={"message": "R subset failed", **res})
    try:
        return _json.loads(res["stdout"])
    except ValueError:
        raise HTTPException(status_code=500, detail="Could not parse R output.")


@api_router.get("/analysis/correlations")
def correlations(method: str = "pearson"):
    """Recompute correlations in R for the chosen method (pearson/spearman)."""
    method = method.lower()
    if method not in ("pearson", "spearman", "kendall"):
        raise HTTPException(status_code=400, detail="Invalid method.")
    mat_file = f"outputs/tables/correlation_matrix_{method}.csv"
    key_file = f"outputs/tables/key_correlations_{method}.csv"
    if not (R_PROJECT_DIR / mat_file).exists():
        res = _run_r("scripts/correlate.R", [method])
        if not res["success"]:
            raise HTTPException(status_code=500, detail={"message": "R correlation failed", **res})

    rows = _read_csv(mat_file)
    matrix = None
    if rows:
        header = list(rows[0].keys())
        var_key = header[0]
        matrix = {
            "variables": [r[var_key] for r in rows],
            "columns": header[1:],
            "matrix": [[r[c] for c in header[1:]] for r in rows],
        }
    return {"method": method, "correlation_matrix": matrix,
            "key_correlations": _read_csv(key_file)}


FIGURES = {
    "sleep_hist": "01_sleep_hist.png",
    "sleep_wellbeing": "02_sleep_wellbeing.png",
    "wellbeing_by_quality": "03_wellbeing_by_quality.png",
    "corr_heatmap": "04_corr_heatmap.png",
}


@api_router.get("/analysis/figures")
async def list_figures():
    out = []
    for key, fname in FIGURES.items():
        if (R_PROJECT_DIR / "outputs/figures" / fname).exists():
            out.append({"key": key, "file": fname})
    return {"figures": out}


@api_router.get("/analysis/figures/{key}")
async def get_figure(key: str, download: bool = False):
    fname = FIGURES.get(key)
    if not fname:
        raise HTTPException(status_code=404, detail="Unknown figure.")
    path = R_PROJECT_DIR / "outputs/figures" / fname
    if not path.exists():
        raise HTTPException(status_code=404, detail="Figure not generated yet.")
    return FileResponse(str(path), media_type="image/png",
                        filename=(fname if download else None))


@api_router.get("/dataset/download")
async def download_dataset(which: str = "raw"):
    rel = ("data/raw/sleep_wellbeing_raw.csv" if which == "raw"
           else "data/processed/sleep_wellbeing_clean.csv")
    path = R_PROJECT_DIR / rel
    if not path.exists():
        raise HTTPException(status_code=404, detail="Dataset not generated yet.")
    return FileResponse(str(path), media_type="text/csv", filename=path.name)


@api_router.get("/report", response_class=PlainTextResponse)
async def get_report():
    path = R_PROJECT_DIR / "report/report.html"
    if not path.exists():
        raise HTTPException(status_code=404, detail="Report not rendered yet.")
    return PlainTextResponse(path.read_text(), media_type="text/html")


# ==========================================================================
# Universal CSV Cleaner — AI suggests cleaning rules, R executes them
# (deterministic & reproducible). All actual cleaning is done by R.
# ==========================================================================
EMERGENT_LLM_KEY = os.environ.get("EMERGENT_LLM_KEY")

CLEAN_SYSTEM_PROMPT = (
    "You are a meticulous data-cleaning assistant. You are given a JSON profile of "
    "the columns of a messy CSV (name, inferred_type, missing counts, distinct counts, "
    "sample values, and raw category labels). Propose deterministic cleaning rules.\n\n"
    "Return ONLY a JSON object (no prose, no markdown fences) with this schema:\n"
    "{\n"
    '  "clean_column_names": true,\n'
    '  "remove_duplicate_rows": true,\n'
    '  "na_sentinels": ["", "NA", "N/A", "null", "-"],\n'
    '  "columns": [\n'
    '    {"name": "<exact column name from profile>",\n'
    '     "type": "numeric|integer|date|category|text",\n'
    '     "trim_whitespace": true,\n'
    '     "numeric_min": <number or null>, "numeric_max": <number or null>,\n'
    '     "date_format": <R strptime format string or null>,\n'
    '     "label_map": {"<raw variant>": "<canonical label>"}}\n'
    "  ]\n"
    "}\n\n"
    "Rules:\n"
    "- Use the EXACT column names from the profile; include every column.\n"
    "- For categorical columns, build label_map that maps each messy raw variant to a single "
    "canonical, human-readable label. Merge case/whitespace variants (e.g. 'good','GOOD','Good ' -> 'Good') "
    "and obvious synonyms/abbreviations ONLY when clearly the same category (e.g. 'NYC','new york city' -> 'New York'). "
    "Do NOT merge values you are unsure about.\n"
    "- For numeric columns, set numeric_min/numeric_max only when an obvious plausible range exists "
    "(e.g. age 0-120, percentage 0-100); otherwise null.\n"
    "- Pick type='integer' for whole-number counts, 'numeric' for decimals.\n"
    "- Keep free-text / identifier columns as type='text' with no label_map."
)


async def _suggest_rules(profile: dict) -> dict:
    """Ask the LLM to propose rules; fall back to deterministic rules on any failure."""
    if EMERGENT_LLM_KEY:
        try:
            from emergentintegrations.llm.chat import LlmChat, UserMessage
            chat = LlmChat(
                api_key=EMERGENT_LLM_KEY,
                session_id="csv-clean-" + uuid.uuid4().hex[:8],
                system_message=CLEAN_SYSTEM_PROMPT,
            ).with_model("openai", "gpt-5.4")
            prompt = "Here is the CSV column profile. Return the cleaning-rules JSON only:\n\n" + json.dumps(profile)
            resp = await chat.send_message(UserMessage(text=prompt))
            rules = _parse_rules_json(str(resp))
            if rules and isinstance(rules.get("columns"), list):
                rules["_source"] = "ai"
                return rules
        except Exception as e:  # noqa: BLE001
            logger.error("LLM rule suggestion failed, using fallback: %s", e)
    rules = _fallback_rules(profile)
    rules["_source"] = "fallback"
    return rules


def _parse_rules_json(text: str):
    t = text.strip()
    if "```" in t:
        t = t.split("```")[1]
        if t.lstrip().lower().startswith("json"):
            t = t.lstrip()[4:]
    start, end = t.find("{"), t.rfind("}")
    if start == -1 or end == -1:
        return None
    try:
        return json.loads(t[start:end + 1])
    except ValueError:
        return None


def _fallback_rules(profile: dict) -> dict:
    cols = []
    for c in profile.get("columns", []):
        t = c.get("inferred_type", "text")
        rule = {"name": c["name"], "trim_whitespace": True, "type": t}
        labels = c.get("labels") or []
        if labels and c.get("n_distinct", 999) <= 25 and t not in ("date",):
            rule["type"] = "category"
            groups = {}
            for l in labels:
                key = " ".join(str(l["label"]).split()).lower()
                groups.setdefault(key, []).append((l["label"], l["n"]))
            lm = {}
            for _, variants in groups.items():
                canon = max(variants, key=lambda z: z[1])[0].strip()
                for lbl, _n in variants:
                    if lbl != canon:
                        lm[lbl] = canon
            if lm:
                rule["label_map"] = lm
        cols.append(rule)
    return {
        "clean_column_names": True,
        "remove_duplicate_rows": True,
        "na_sentinels": ["", "NA", "N/A", "na", "n/a", "null", "NULL", "-", "?", "."],
        "columns": cols,
    }


class SuggestReq(BaseModel):
    profile: dict


def _decode_csv(data: bytes) -> str:
    if len(data) > 15 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="File too large (max 15 MB).")
    if not data:
        raise HTTPException(status_code=400, detail="Empty file.")
    return data.decode("utf-8", errors="replace")


@api_router.post("/clean/profile")
async def clean_profile(file: UploadFile = File(...)):
    """Profile ANY uploaded CSV in R (streamed via stdin, never stored)."""
    text = _decode_csv(await file.read())
    res = await asyncio.to_thread(_run_r, "rclean/profile.R", None, text)
    if not res["success"]:
        raise HTTPException(status_code=500, detail={"message": "Profiling failed", **res})
    try:
        profile = json.loads(res["stdout"])
    except ValueError:
        raise HTTPException(status_code=500, detail="Could not profile this CSV.")
    return {"filename": file.filename, "profile": profile}


@api_router.post("/clean/suggest")
async def clean_suggest(req: SuggestReq):
    """AI proposes cleaning rules from the column profile (deterministic fallback)."""
    rules = await _suggest_rules(req.profile)
    source = rules.pop("_source", "ai")
    return {"rules": rules, "source": source}


@api_router.post("/clean/apply")
async def clean_apply(file: UploadFile = File(...), rules: str = Form(...)):
    """Apply the approved rules in R; return cleaned CSV, audit and reproducible script inline."""
    text = _decode_csv(await file.read())
    try:
        rules_obj = json.loads(rules)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid rules JSON.")
    rules_obj.pop("_source", None)
    tf = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
    try:
        json.dump(rules_obj, tf)
        tf.close()
        res = await asyncio.to_thread(_run_r, "rclean/apply.R", [tf.name], text)
    finally:
        os.unlink(tf.name)
    if not res["success"]:
        raise HTTPException(status_code=500, detail={"message": "Cleaning failed", **res})
    try:
        return json.loads(res["stdout"])
    except ValueError:
        raise HTTPException(status_code=500, detail="Could not parse R output.")


app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)
