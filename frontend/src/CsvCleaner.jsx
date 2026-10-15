import { useRef, useState } from "react";
import axios from "axios";
import {
  UploadCloud, Sparkles, Loader2, Play, Download, FileCode2, ClipboardList,
  CheckCircle2, Wand2, Database, AlertTriangle, X, Plus,
} from "lucide-react";

const API = `${process.env.REACT_APP_BACKEND_URL}/api`;
const TYPES = ["numeric", "integer", "date", "category", "text"];

const downloadText = (filename, text, mime) => {
  const blob = new Blob([text], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url; a.download = filename; a.click();
  URL.revokeObjectURL(url);
};

const Table = ({ rows, testid }) => {
  if (!rows || rows.length === 0) return <p className="p-4 text-sm text-muted-foreground">No data.</p>;
  const cols = Object.keys(rows[0]);
  return (
    <div className="overflow-x-auto max-h-80">
      <table data-testid={testid} className="w-full text-xs">
        <thead className="sticky top-0">
          <tr className="bg-secondary text-left">
            {cols.map((c) => <th key={c} className="px-3 py-2 font-semibold whitespace-nowrap border-b border-border">{c}</th>)}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i} className="odd:bg-background even:bg-secondary/30">
              {cols.map((c) => (
                <td key={c} className="px-3 py-1.5 font-mono whitespace-nowrap border-b border-border/50">
                  {r[c] === "" || r[c] == null ? <span className="text-rose-500">NA</span> : String(r[c])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default function CsvCleaner() {
  const fileRef = useRef(null);
  const [file, setFile] = useState(null);
  const [profile, setProfile] = useState(null);
  const [rules, setRules] = useState(null);
  const [source, setSource] = useState(null);
  const [result, setResult] = useState(null);
  const [busy, setBusy] = useState("");
  const [error, setError] = useState(null);

  const reset = () => { setProfile(null); setRules(null); setResult(null); setSource(null); setError(null); };

  const onPick = async (f) => {
    if (!f) return;
    setFile(f); reset(); setBusy("profile");
    try {
      const fd = new FormData(); fd.append("file", f);
      const { data } = await axios.post(`${API}/clean/profile`, fd);
      setProfile(data.profile);
    } catch (e) {
      setError(e?.response?.data?.detail || "Could not read this CSV.");
    } finally { setBusy(""); }
  };

  const getSuggestions = async () => {
    setBusy("suggest"); setError(null);
    try {
      const { data } = await axios.post(`${API}/clean/suggest`, { profile });
      const cols = (data.rules.columns || []).map((c) => ({
        ...c,
        _include: true,
        label_pairs: Object.entries(c.label_map || {}),
      }));
      setRules({ ...data.rules, columns: cols });
      setSource(data.source);
    } catch (e) {
      setError("AI suggestion failed.");
    } finally { setBusy(""); }
  };

  const setCol = (i, patch) => setRules((r) => {
    const cols = r.columns.slice(); cols[i] = { ...cols[i], ...patch }; return { ...r, columns: cols };
  });

  const setPair = (i, j, field, value) => setRules((r) => {
    const cols = r.columns.slice();
    const pairs = cols[i].label_pairs.map((p) => p.slice());
    pairs[j][field === "raw" ? 0 : 1] = value;
    cols[i] = { ...cols[i], label_pairs: pairs };
    return { ...r, columns: cols };
  });
  const removePair = (i, j) => setRules((r) => {
    const cols = r.columns.slice();
    cols[i] = { ...cols[i], label_pairs: cols[i].label_pairs.filter((_, k) => k !== j) };
    return { ...r, columns: cols };
  });
  const addPair = (i) => setRules((r) => {
    const cols = r.columns.slice();
    cols[i] = { ...cols[i], label_pairs: [...cols[i].label_pairs, ["", ""]] };
    return { ...r, columns: cols };
  });

  const applyRules = async () => {
    setBusy("apply"); setError(null);
    try {
      const payload = {
        ...rules,
        columns: rules.columns
          .filter((c) => c._include !== false)
          .map(({ _include, label_pairs, ...c }) => {
            const lm = {};
            (label_pairs || []).forEach(([k, v]) => {
              if (k && k.trim() && v && v.trim()) lm[k] = v;
            });
            if (Object.keys(lm).length > 0) c.label_map = lm;
            else delete c.label_map;
            return c;
          }),
      };
      const fd = new FormData();
      fd.append("file", file);
      fd.append("rules", JSON.stringify(payload));
      const { data } = await axios.post(`${API}/clean/apply`, fd);
      setResult(data);
    } catch (e) {
      setError(e?.response?.data?.detail?.message || "Cleaning failed in R.");
    } finally { setBusy(""); }
  };

  return (
    <section id="cleaner" data-testid="csv-cleaner-section" className="rounded-xl border-2 border-primary/30 bg-card shadow-sm overflow-hidden">
      {/* banner */}
      <div className="bg-primary/5 border-b border-border px-5 md:px-7 py-5">
        <div className="flex items-center gap-2 text-primary">
          <Wand2 className="h-5 w-5" />
          <span className="text-xs font-bold uppercase tracking-widest">Unique Feature</span>
        </div>
        <h2 className="font-display text-xl md:text-2xl font-extrabold tracking-tight mt-1">
          Universal CSV Cleaner — <span className="text-primary">AI suggests, R proves</span>
        </h2>
        <p className="text-sm text-muted-foreground mt-1 max-w-3xl">
          Upload <b>any</b> messy CSV. The AI proposes cleaning rules, <b>you approve them</b>, and real R executes them
          deterministically — then you download the tidy CSV, a full audit, and a <b>reproducible R script</b> that reproduces it.
        </p>
      </div>

      <div className="p-5 md:p-7 space-y-6">
        {/* step 1: upload */}
        <div className="flex flex-wrap items-center gap-3">
          <input ref={fileRef} type="file" accept=".csv,text/csv" className="hidden"
            data-testid="csv-file-input"
            onChange={(e) => onPick(e.target.files?.[0])} />
          <button data-testid="csv-upload-button" onClick={() => fileRef.current?.click()}
            className="inline-flex items-center gap-2 rounded-md border-2 border-dashed border-primary/40 bg-primary/5 px-5 py-3 text-sm font-semibold text-primary hover:bg-primary/10 transition-colors">
            {busy === "profile" ? <Loader2 className="h-4 w-4 animate-spin" /> : <UploadCloud className="h-4 w-4" />}
            {file ? "Choose a different CSV" : "Upload a CSV"}
          </button>
          {file && <span data-testid="csv-filename" className="font-mono text-xs text-muted-foreground">{file.name}</span>}
          <a href="/sample_messy.csv" download className="ml-auto text-xs text-primary hover:underline inline-flex items-center gap-1">
            <Download className="h-3.5 w-3.5" /> try a sample messy file
          </a>
        </div>

        {error && (
          <div data-testid="cleaner-error" className="rounded-md border border-rose-400/50 bg-rose-50 dark:bg-rose-950/30 px-4 py-3 text-sm text-rose-700 dark:text-rose-300 flex items-center gap-2">
            <AlertTriangle className="h-4 w-4" /> {String(error)}
          </div>
        )}

        {/* step 2: profile */}
        {profile && (
          <div data-testid="csv-profile-block" className="rounded-md border border-border">
            <div className="flex items-center justify-between border-b border-border px-4 py-3">
              <div className="flex items-center gap-2 text-sm font-semibold"><Database className="h-4 w-4 text-primary" /> Column profile (by R)</div>
              <div className="flex items-center gap-3 text-xs text-muted-foreground">
                <span data-testid="profile-rows">{profile.n_rows} rows</span>
                <span>{profile.n_cols} cols</span>
                <span className="text-rose-500">{profile.duplicate_rows} dup rows</span>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-xs">
                <thead><tr className="bg-secondary text-left">
                  {["column", "inferred type", "missing", "distinct", "sample"].map((h) => <th key={h} className="px-3 py-2 font-semibold border-b border-border">{h}</th>)}
                </tr></thead>
                <tbody>
                  {profile.columns.map((c) => (
                    <tr key={c.name} className="odd:bg-background even:bg-secondary/30">
                      <td className="px-3 py-1.5 font-mono font-medium border-b border-border/50">{c.name}</td>
                      <td className="px-3 py-1.5 border-b border-border/50"><span className="rounded bg-secondary px-1.5 py-0.5 font-mono">{c.inferred_type}</span></td>
                      <td className="px-3 py-1.5 font-mono border-b border-border/50">{c.n_missing} ({c.pct_missing}%)</td>
                      <td className="px-3 py-1.5 font-mono border-b border-border/50">{c.n_distinct}</td>
                      <td className="px-3 py-1.5 font-mono text-muted-foreground border-b border-border/50 truncate max-w-xs">{(c.sample || []).join(", ")}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {!rules && (
              <div className="border-t border-border p-4">
                <button data-testid="get-ai-suggestions-button" onClick={getSuggestions} disabled={busy === "suggest"}
                  className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60 transition-opacity">
                  {busy === "suggest" ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />}
                  Get AI cleaning suggestions
                </button>
              </div>
            )}
          </div>
        )}

        {/* step 3: review rules */}
        {rules && (
          <div data-testid="rules-review-block" className="rounded-md border border-border">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border px-4 py-3">
              <div className="flex items-center gap-2 text-sm font-semibold">
                <ClipboardList className="h-4 w-4 text-primary" /> Review &amp; approve cleaning rules
                <span data-testid="rules-source-badge" className={`ml-1 rounded px-2 py-0.5 text-xs font-medium ${source === "ai" ? "bg-violet-100 dark:bg-violet-950/40 text-violet-700 dark:text-violet-300" : "bg-secondary text-muted-foreground"}`}>
                  {source === "ai" ? "AI-suggested" : "auto (fallback)"}
                </span>
              </div>
              <div className="flex items-center gap-4 text-xs">
                <label className="inline-flex items-center gap-1.5 cursor-pointer">
                  <input type="checkbox" data-testid="toggle-clean-names" checked={!!rules.clean_column_names}
                    onChange={(e) => setRules({ ...rules, clean_column_names: e.target.checked })} />
                  clean column names
                </label>
                <label className="inline-flex items-center gap-1.5 cursor-pointer">
                  <input type="checkbox" data-testid="toggle-remove-dupes" checked={!!rules.remove_duplicate_rows}
                    onChange={(e) => setRules({ ...rules, remove_duplicate_rows: e.target.checked })} />
                  remove duplicate rows
                </label>
              </div>
            </div>
            <div className="divide-y divide-border">
              {rules.columns.map((c, i) => (
                <div key={c.name} data-testid={`rule-row-${c.name}`} className="flex flex-wrap items-center gap-3 px-4 py-2.5">
                  <label className="inline-flex items-center gap-2 cursor-pointer min-w-[180px]">
                    <input type="checkbox" data-testid={`rule-include-${c.name}`} checked={c._include !== false}
                      onChange={(e) => setCol(i, { _include: e.target.checked })} />
                    <span className="font-mono text-sm font-medium">{c.name}</span>
                  </label>
                  <select data-testid={`rule-type-${c.name}`} value={c.type || "text"}
                    disabled={c._include === false}
                    onChange={(e) => setCol(i, { type: e.target.value })}
                    className="rounded border border-border bg-card px-2 py-1 text-xs font-mono disabled:opacity-40">
                    {TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
                  </select>
                  {(c.numeric_min != null || c.numeric_max != null) && (
                    <span className="text-xs text-muted-foreground font-mono">range [{c.numeric_min ?? "−∞"}, {c.numeric_max ?? "∞"}]</span>
                  )}
                  {(c.type === "category" || (c.label_pairs && c.label_pairs.length > 0)) && c._include !== false && (
                    <details data-testid={`labelmap-${c.name}`} className="w-full text-xs" open={c.label_pairs?.length > 0 && c.label_pairs.length <= 6}>
                      <summary className="cursor-pointer text-primary">
                        {c.label_pairs?.length || 0} label fix{(c.label_pairs?.length || 0) === 1 ? "" : "es"} · edit
                      </summary>
                      <div className="mt-2 space-y-1.5 pl-1">
                        {(c.label_pairs || []).map(([k, v], j) => (
                          <div key={j} className="flex items-center gap-1.5">
                            <input data-testid={`labelmap-${c.name}-raw-${j}`} value={k}
                              onChange={(e) => setPair(i, j, "raw", e.target.value)}
                              placeholder="raw value"
                              className="w-32 rounded border border-border bg-card px-2 py-1 font-mono" />
                            <span className="text-muted-foreground">→</span>
                            <input data-testid={`labelmap-${c.name}-canon-${j}`} value={v}
                              onChange={(e) => setPair(i, j, "canon", e.target.value)}
                              placeholder="canonical"
                              className="w-32 rounded border border-primary/40 bg-card px-2 py-1 font-mono" />
                            <button data-testid={`labelmap-${c.name}-remove-${j}`} onClick={() => removePair(i, j)}
                              className="rounded p-1 text-muted-foreground hover:text-rose-500" title="remove">
                              <X className="h-3.5 w-3.5" />
                            </button>
                          </div>
                        ))}
                        <button data-testid={`labelmap-${c.name}-add`} onClick={() => addPair(i)}
                          className="inline-flex items-center gap-1 text-primary hover:underline">
                          <Plus className="h-3.5 w-3.5" /> add mapping
                        </button>
                      </div>
                    </details>
                  )}
                </div>
              ))}
            </div>
            <div className="border-t border-border p-4">
              <button data-testid="apply-cleaning-button" onClick={applyRules} disabled={busy === "apply"}
                className="inline-flex items-center gap-2 rounded-md bg-primary px-5 py-2.5 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60 transition-opacity">
                {busy === "apply" ? <Loader2 className="h-4 w-4 animate-spin" /> : <Play className="h-4 w-4" />}
                Apply cleaning in R
              </button>
            </div>
          </div>
        )}

        {/* step 4: results */}
        {result && (
          <div data-testid="clean-result-block" className="rounded-md border border-emerald-400/40 bg-emerald-50/40 dark:bg-emerald-950/10">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border px-4 py-3">
              <div className="flex items-center gap-2 text-sm font-semibold text-emerald-700 dark:text-emerald-400">
                <CheckCircle2 className="h-4 w-4" /> Cleaned in R · {result.rows_before} → {result.rows_after} rows
              </div>
              <div className="flex flex-wrap gap-2">
                <button data-testid="download-cleaned-csv" onClick={() => downloadText("cleaned.csv", result.cleaned_csv, "text/csv")}
                  className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground hover:opacity-90">
                  <Download className="h-3.5 w-3.5" /> Cleaned CSV
                </button>
                <button data-testid="download-r-script" onClick={() => downloadText("cleaning_script.R", result.script, "text/plain")}
                  className="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-xs font-semibold hover:bg-accent">
                  <FileCode2 className="h-3.5 w-3.5" /> R script
                </button>
                <button data-testid="download-audit" onClick={() => downloadText("audit.json", JSON.stringify(result.audit, null, 2), "application/json")}
                  className="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-xs font-semibold hover:bg-accent">
                  <ClipboardList className="h-3.5 w-3.5" /> Audit
                </button>
              </div>
            </div>

            <div className="grid lg:grid-cols-2 gap-px bg-border">
              <div className="bg-card">
                <p className="px-4 pt-3 pb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">What changed (audit)</p>
                <Table testid="audit-table" rows={result.audit.map((a) => ({ operation: a.operation, column: a.column ?? "—", cells_changed: a.cells_changed }))} />
              </div>
              <div className="bg-card">
                <p className="px-4 pt-3 pb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Cleaned preview</p>
                <Table testid="cleaned-preview-table" rows={result.preview} />
              </div>
            </div>

            <div className="p-4">
              <p className="mb-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Reproducible R script (generated)</p>
              <pre data-testid="generated-script" className="max-h-64 overflow-auto rounded-md bg-[#0B0F17] p-4 font-mono text-[11px] leading-relaxed text-emerald-300">{result.script}</pre>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
