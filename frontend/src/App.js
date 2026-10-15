import { useEffect, useState, useCallback } from "react";
import "@/App.css";
import axios from "axios";
import { motion } from "framer-motion";
import {
  FlaskConical, Play, Moon, Sun, Loader2, CheckCircle2, AlertTriangle,
  XCircle, Download, FileText, Beaker, TerminalSquare, Sigma, RefreshCw, Filter,
} from "lucide-react";

import CsvCleaner from "@/CsvCleaner";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
const API = `${BACKEND_URL}/api`;

const CHART = ["#1E3A8A", "#059669", "#D97706", "#6D28D9", "#0284C7", "#DB2777"];

/* ----------------------------- tiny UI atoms ---------------------------- */
const Card = ({ children, className = "", testid }) => (
  <div data-testid={testid}
    className={`rounded-md border border-border bg-card shadow-sm ${className}`}>
    {children}
  </div>
);

const CardHead = ({ icon: Icon, title, sub, right }) => (
  <div className="flex items-start justify-between gap-4 border-b border-border px-5 py-4">
    <div className="flex items-start gap-3">
      {Icon && <Icon className="mt-0.5 h-5 w-5 text-primary" strokeWidth={2} />}
      <div>
        <h3 className="font-display text-base md:text-lg font-semibold tracking-tight">{title}</h3>
        {sub && <p className="text-xs text-muted-foreground mt-0.5">{sub}</p>}
      </div>
    </div>
    {right}
  </div>
);

const Section = ({ id, children }) => (
  <motion.section id={id}
    initial={{ opacity: 0, y: 14 }} whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true, margin: "-60px" }} transition={{ duration: 0.4 }}>
    {children}
  </motion.section>
);

/* generic table from array-of-objects */
const DataTable = ({ rows, testid, highlightCol, moneyFmt }) => {
  if (!rows || rows.length === 0) return <p className="p-5 text-sm text-muted-foreground">No data.</p>;
  const cols = Object.keys(rows[0]);
  return (
    <div className="overflow-x-auto">
      <table data-testid={testid} className="w-full text-sm">
        <thead>
          <tr className="bg-secondary/70 text-left">
            {cols.map((c) => (
              <th key={c} className="px-4 py-2.5 font-semibold text-foreground/80 whitespace-nowrap border-b border-border">
                {c}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={i} className="odd:bg-background even:bg-secondary/30 hover:bg-accent/60 transition-colors">
              {cols.map((c) => (
                <td key={c}
                  className={`px-4 py-2 font-mono text-xs md:text-[13px] whitespace-nowrap border-b border-border/60 ${c === highlightCol ? "font-semibold text-primary" : "text-foreground/80"}`}>
                  {r[c] === "" || r[c] == null ? <span className="text-rose-500">NA</span> : r[c]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

const Stat = ({ label, value, tone = "primary", testid }) => {
  const tones = {
    primary: "text-primary", emerald: "text-emerald-600 dark:text-emerald-400",
    amber: "text-amber-600 dark:text-amber-400", rose: "text-rose-600 dark:text-rose-400",
    violet: "text-violet-600 dark:text-violet-400",
  };
  return (
    <div data-testid={testid} className="rounded-md border border-border bg-card px-4 py-4">
      <div className={`font-mono text-2xl md:text-3xl font-semibold ${tones[tone]}`}>{value}</div>
      <div className="mt-1 text-xs uppercase tracking-wider text-muted-foreground">{label}</div>
    </div>
  );
};

/* correlation heat cell color */
const corrColor = (v) => {
  const n = parseFloat(v);
  if (isNaN(n)) return "transparent";
  const a = Math.min(Math.abs(n), 1);
  return n >= 0
    ? `rgba(30,58,138,${0.12 + a * 0.6})`
    : `rgba(220,38,38,${0.12 + a * 0.6})`;
};

/* --------------------------------- App ---------------------------------- */
function App() {
  const [dark, setDark] = useState(false);
  const [health, setHealth] = useState(null);
  const [results, setResults] = useState(null);
  const [running, setRunning] = useState(false);
  const [testing, setTesting] = useState(false);
  const [testOut, setTestOut] = useState(null);
  const [figKey, setFigKey] = useState(Date.now());
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  const [corrMethod, setCorrMethod] = useState("pearson");
  const [corrData, setCorrData] = useState(null);
  const [corrLoading, setCorrLoading] = useState(false);
  const [showReport, setShowReport] = useState(false);
  const [subGender, setSubGender] = useState("all");
  const [subQuality, setSubQuality] = useState("all");
  const [subData, setSubData] = useState(null);
  const [subLoading, setSubLoading] = useState(false);
  const [anovaFactor, setAnovaFactor] = useState("sleep_quality");
  const [anovaData, setAnovaData] = useState(null);
  const [anovaLoading, setAnovaLoading] = useState(false);
  const [regData, setRegData] = useState(null);
  const [regLoading, setRegLoading] = useState(false);

  useEffect(() => {
    document.documentElement.classList.toggle("dark", dark);
  }, [dark]);

  const loadResults = useCallback(async () => {
    try {
      const { data } = await axios.get(`${API}/analysis/results`);
      setResults(data);
    } catch (e) {
      setResults(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    axios.get(`${API}/health`).then((r) => setHealth(r.data)).catch(() => setHealth({ r_available: false }));
    loadResults();
  }, [loadResults]);

  const runPipeline = async () => {
    setRunning(true); setError(null);
    try {
      await axios.post(`${API}/analysis/run`);
      await loadResults();
      setFigKey(Date.now());
    } catch (e) {
      setError(e?.response?.data?.detail?.message || "R analysis failed. See server logs.");
    } finally { setRunning(false); }
  };

  const selectCorr = async (method) => {
    setCorrMethod(method);
    if (method === "pearson" && !corrData) return; // base results already pearson
    setCorrLoading(true);
    try {
      const { data } = await axios.get(`${API}/analysis/correlations?method=${method}`);
      setCorrData(data);
    } catch (e) {
      /* keep previous */
    } finally { setCorrLoading(false); }
  };

  const runSubset = async () => {
    setSubLoading(true);
    try {
      const { data } = await axios.get(`${API}/analysis/subset?gender=${subGender}&sleep_quality=${subQuality}`);
      setSubData(data);
    } catch (e) {
      setSubData(null);
    } finally { setSubLoading(false); }
  };

  const runAnova = async (factor) => {
    const f = factor || anovaFactor;
    setAnovaFactor(f);
    setAnovaLoading(true);
    try {
      const { data } = await axios.get(`${API}/analysis/anova?factor=${f}`);
      setAnovaData(data);
    } catch (e) {
      setAnovaData(null);
    } finally { setAnovaLoading(false); }
  };

  const runRegression = async () => {
    setRegLoading(true);
    try {
      const { data } = await axios.get(`${API}/analysis/regression`);
      setRegData(data);
    } catch (e) {
      setRegData(null);
    } finally { setRegLoading(false); }
  };

  const runTests = async () => {
    setTesting(true);
    try {
      const { data } = await axios.post(`${API}/tests/run`);
      setTestOut(data);
    } catch (e) {
      setTestOut({ passed: false, output: "Failed to run tests." });
    } finally { setTesting(false); }
  };

  const summary = results?.summary || {};
  const cm = (corrMethod !== "pearson" || corrData) && corrData
    ? corrData.correlation_matrix : results?.correlation_matrix;
  const kc = (corrMethod !== "pearson" || corrData) && corrData
    ? corrData.key_correlations : results?.key_correlations;
  const fig = (k) => `${API}/analysis/figures/${k}?v=${figKey}`;
  const FIGS = [
    { key: "sleep_hist", title: "Distribution of nightly sleep", testid: "figure-card-sleep-hist" },
    { key: "sleep_wellbeing", title: "Sleep hours vs. wellbeing", testid: "figure-card-sleep-wellbeing" },
    { key: "wellbeing_by_quality", title: "Wellbeing by sleep quality", testid: "figure-card-wellbeing-quality" },
    { key: "corr_heatmap", title: "Correlation heatmap", testid: "figure-card-correlation-heatmap" },
  ];

  return (
    <div className="App min-h-screen bg-background text-foreground">
      {/* ---------------------------- Header --------------------------- */}
      <header data-testid="app-header"
        className="sticky top-0 z-40 border-b border-border bg-card/90 backdrop-blur-md">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex flex-wrap items-center justify-between gap-3 py-4">
            <div className="flex items-center gap-3">
              <div className="grid h-10 w-10 place-items-center rounded-md bg-primary text-primary-foreground">
                <FlaskConical className="h-5 w-5" />
              </div>
              <div>
                <h1 className="font-display text-lg md:text-xl font-extrabold tracking-tight leading-none">
                  Reproducible Research Console
                </h1>
                <p className="text-xs text-muted-foreground mt-1">
                  Data Quality &amp; Analysis · powered by real <span className="font-mono">R</span> (tidyverse · janitor · ggplot2)
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <span data-testid="synthetic-data-disclaimer"
                className="hidden sm:inline-flex items-center gap-1.5 rounded-md border border-amber-400/50 bg-amber-50 dark:bg-amber-950/40 px-3 py-1.5 text-xs font-mono font-bold uppercase tracking-widest text-amber-700 dark:text-amber-400">
                <AlertTriangle className="h-3.5 w-3.5" /> Synthetic data
              </span>
              <button data-testid="theme-toggle-button" onClick={() => setDark((d) => !d)}
                className="grid h-9 w-9 place-items-center rounded-md border border-border bg-card hover:bg-accent transition-colors">
                {dark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
              </button>
              <button data-testid="run-r-pipeline-button" onClick={runPipeline} disabled={running}
                className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60 transition-opacity">
                {running ? <Loader2 className="h-4 w-4 animate-spin" /> : <Play className="h-4 w-4" />}
                {running ? "Running R…" : "Run R Analysis"}
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8 space-y-10">
        <CsvCleaner />

        <div className="flex items-center gap-3 pt-2">
          <span className="text-xs font-bold uppercase tracking-widest text-muted-foreground">Example R project · sleep &amp; wellbeing demo</span>
          <div className="h-px flex-1 bg-border" />
        </div>

        {/* R engine status */}
        <div className="flex flex-wrap items-center gap-3 text-sm">
          {health && (
            <span data-testid="r-engine-status"
              className={`inline-flex items-center gap-2 rounded-md border px-3 py-1.5 font-mono text-xs ${health.r_available ? "border-emerald-400/50 text-emerald-600 dark:text-emerald-400" : "border-rose-400/50 text-rose-600"}`}>
              {health.r_available ? <CheckCircle2 className="h-3.5 w-3.5" /> : <XCircle className="h-3.5 w-3.5" />}
              R engine {health.r_available ? `online · v${health.r_version}` : "unavailable"}
            </span>
          )}
          <span className="text-muted-foreground">
            Every number &amp; figure below is produced live by <span className="font-mono">Rscript</span> — nothing is hardcoded.
          </span>
        </div>

        {error && (
          <div data-testid="error-banner" className="rounded-md border border-rose-400/50 bg-rose-50 dark:bg-rose-950/30 px-4 py-3 text-sm text-rose-700 dark:text-rose-300">
            {error}
          </div>
        )}

        {loading && (
          <div data-testid="loading-state" className="flex items-center gap-3 py-16 justify-center text-muted-foreground">
            <Loader2 className="h-5 w-5 animate-spin" /> Loading R analysis results…
          </div>
        )}

        {!loading && !results && (
          <Card testid="empty-state" className="p-10 text-center">
            <Beaker className="mx-auto h-10 w-10 text-primary" />
            <h2 className="font-display mt-3 text-xl font-bold">No analysis results yet</h2>
            <p className="mt-1 text-sm text-muted-foreground">Click “Run R Analysis” to generate the synthetic dataset and execute the full R pipeline.</p>
          </Card>
        )}

        {results && (
          <>
            {/* ----------------- Validation & Audit ----------------- */}
            <Section id="validation">
              <Card testid="validation-summary-card">
                <CardHead icon={AlertTriangle} title="Data Validation &amp; Audit"
                  sub="Detected by R before any cleaning — missing values, duplicates, invalid ranges & inconsistent labels." />
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 p-5">
                  <Stat testid="raw-row-count" label="Raw rows" value={summary.raw_rows} />
                  <Stat testid="missing-values-badge" label="Missing cells" tone="amber" value={summary.total_missing_cells} />
                  <Stat testid="duplicates-count-badge" label="Duplicate rows" tone="rose" value={summary.duplicate_rows_removed} />
                  <Stat testid="invalid-entries-badge" label="Invalid entries" tone="rose" value={summary.total_invalid_entries} />
                  <Stat testid="inconsistent-gender-badge" label="Raw gender labels" tone="violet" value={summary.distinct_raw_gender_labels} />
                  <Stat testid="inconsistent-quality-badge" label="Raw quality labels" tone="violet" value={summary.distinct_raw_quality_labels} />
                </div>
                <div className="grid lg:grid-cols-2 gap-px bg-border">
                  <div className="bg-card">
                    <p className="px-5 pt-4 pb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Missing values per column</p>
                    <DataTable rows={results.missing} testid="missing-report-table" highlightCol="missing" />
                  </div>
                  <div className="bg-card">
                    <p className="px-5 pt-4 pb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Out-of-range / invalid entries</p>
                    <DataTable rows={results.invalid} testid="invalid-report-table" highlightCol="n_invalid" />
                  </div>
                </div>
              </Card>
            </Section>

            {/* ----------------- Raw vs Cleaned ----------------- */}
            <Section id="comparison">
              <Card testid="dataset-comparison-card">
                <CardHead icon={RefreshCw} title="Raw vs. Cleaned Dataset"
                  sub="Cleaning runs on a copy — the original raw dataset is always preserved."
                  right={
                    <div className="flex gap-2">
                      <a data-testid="download-raw-button" href={`${API}/dataset/download?which=raw`}
                        className="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-xs hover:bg-accent transition-colors">
                        <Download className="h-3.5 w-3.5" /> Raw CSV
                      </a>
                      <a data-testid="download-clean-button" href={`${API}/dataset/download?which=clean`}
                        className="inline-flex items-center gap-1.5 rounded-md border border-border px-3 py-1.5 text-xs hover:bg-accent transition-colors">
                        <Download className="h-3.5 w-3.5" /> Cleaned CSV
                      </a>
                    </div>
                  } />
                <div className="flex flex-wrap items-center gap-6 px-5 py-4 border-b border-border">
                  <div><span data-testid="raw-row-count-value" className="font-mono text-xl font-semibold">{summary.raw_rows}</span><span className="ml-2 text-xs text-muted-foreground">raw rows</span></div>
                  <span className="text-muted-foreground">→</span>
                  <div><span data-testid="cleaned-row-count-value" className="font-mono text-xl font-semibold text-emerald-600 dark:text-emerald-400">{summary.cleaned_rows}</span><span className="ml-2 text-xs text-muted-foreground">cleaned rows</span></div>
                  <span className="rounded-md bg-rose-50 dark:bg-rose-950/30 px-2.5 py-1 text-xs font-mono text-rose-600 dark:text-rose-400">−{summary.duplicate_rows_removed} duplicates removed</span>
                </div>
                <div className="grid lg:grid-cols-2 gap-px bg-border">
                  <div className="bg-card">
                    <p className="px-5 pt-4 pb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Raw preview (messy)</p>
                    <DataTable rows={results.raw_preview?.slice(0, 8)} testid="raw-preview-table" />
                  </div>
                  <div className="bg-card">
                    <p className="px-5 pt-4 pb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Cleaned preview (typed)</p>
                    <DataTable rows={results.cleaned_preview?.slice(0, 8)} testid="cleaned-preview-table" />
                  </div>
                </div>
              </Card>
            </Section>

            {/* ----------------- Descriptive + Frequency ----------------- */}
            <Section id="descriptives">
              <div className="grid lg:grid-cols-5 gap-6">
                <Card testid="desc-stats-card" className="lg:col-span-3">
                  <CardHead icon={Sigma} title="Descriptive Statistics" sub="Computed in R on the cleaned data." />
                  <DataTable rows={results.descriptive} testid="desc-stats-table" highlightCol="variable" />
                </Card>
                <Card testid="frequency-tables-card" className="lg:col-span-2">
                  <CardHead icon={Beaker} title="Frequency Tables" sub="janitor::tabyl()" />
                  <div className="space-y-5 p-5">
                    {["gender", "sleep_quality", "mood"].map((k) => (
                      <div key={k}>
                        <p className="mb-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">{k.replace("_", " ")}</p>
                        <DataTable rows={results.frequency?.[k]} testid={`${k}-dist-table`} />
                      </div>
                    ))}
                  </div>
                </Card>
              </div>
            </Section>

            {/* ----------------- Correlations ----------------- */}
            <Section id="correlations">
              <div className="grid lg:grid-cols-5 gap-6">
                <Card testid="correlation-matrix-card" className="lg:col-span-3">
                  <CardHead icon={Sigma} title="Correlation Matrix"
                    sub={`${corrMethod.charAt(0).toUpperCase() + corrMethod.slice(1)} · pairwise-complete · recomputed in R.`}
                    right={
                      <div className="inline-flex rounded-md border border-border p-0.5 text-xs font-medium">
                        {["pearson", "spearman", "kendall"].map((m) => (
                          <button key={m} data-testid={`corr-method-${m}`} onClick={() => selectCorr(m)}
                            className={`rounded px-2.5 py-1 capitalize transition-colors ${corrMethod === m ? "bg-primary text-primary-foreground" : "hover:bg-accent"}`}>
                            {m}
                          </button>
                        ))}
                      </div>
                    } />
                  <div className="overflow-x-auto p-5 relative">
                    {corrLoading && (
                      <div className="absolute inset-0 z-10 grid place-items-center bg-card/70 backdrop-blur-sm">
                        <Loader2 className="h-5 w-5 animate-spin text-primary" />
                      </div>
                    )}
                    {cm && (
                      <table data-testid="correlation-matrix-grid" className="w-full text-xs">
                        <thead>
                          <tr>
                            <th className="p-2"></th>
                            {cm.columns.map((c) => (
                              <th key={c} className="p-2 font-mono font-medium text-muted-foreground -rotate-0 whitespace-nowrap">{c}</th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {cm.variables.map((v, i) => (
                            <tr key={v}>
                              <td className="p-2 font-mono font-medium text-muted-foreground whitespace-nowrap">{v}</td>
                              {cm.matrix[i].map((val, j) => (
                                <td key={j} className="p-2 text-center font-mono"
                                  style={{ backgroundColor: corrColor(val) }}>
                                  {parseFloat(val).toFixed(2)}
                                </td>
                              ))}
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    )}
                  </div>
                </Card>
                <Card testid="key-correlations-card" className="lg:col-span-2">
                  <CardHead icon={Sigma} title="Key Correlations with Wellbeing" sub="cor.test() with p-values." />
                  <div className="space-y-3 p-5">
                    {kc?.map((r, i) => {
                      const est = parseFloat(r.estimate), p = parseFloat(r.p_value);
                      return (
                        <div key={i} data-testid={`key-corr-${i}`} className="rounded-md border border-border p-3">
                          <div className="flex items-center justify-between">
                            <span className="font-mono text-xs">{r.x} ↔ {r.y}</span>
                            <span className={`font-mono text-sm font-semibold ${est >= 0 ? "text-primary" : "text-rose-600 dark:text-rose-400"}`}>r = {est.toFixed(3)}</span>
                          </div>
                          <div className="mt-1.5 flex items-center justify-between text-xs text-muted-foreground">
                            <span>n = {r.n}</span>
                            <span data-testid={`p-value-badge-${i}`} className="rounded bg-secondary px-2 py-0.5 font-mono">
                              {p < 0.001 ? "p < 0.001" : `p = ${p.toExponential(2)}`}
                            </span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </Card>
              </div>
            </Section>

            {/* ----------------- Subset Analysis ----------------- */}
            <Section id="subset">
              <Card testid="subset-analysis-card">
                <CardHead icon={Filter} title="On-demand Subset Analysis"
                  sub="Filter the cleaned data and re-run descriptive stats + correlations live in R."
                  right={
                    <div className="flex flex-wrap items-center gap-2">
                      <select data-testid="subset-gender-select" value={subGender}
                        onChange={(e) => setSubGender(e.target.value)}
                        className="rounded-md border border-border bg-card px-2.5 py-1.5 text-xs font-medium">
                        {["all", "Male", "Female", "Other"].map((g) => <option key={g} value={g}>{g === "all" ? "All genders" : g}</option>)}
                      </select>
                      <select data-testid="subset-quality-select" value={subQuality}
                        onChange={(e) => setSubQuality(e.target.value)}
                        className="rounded-md border border-border bg-card px-2.5 py-1.5 text-xs font-medium">
                        {["all", "Poor", "Fair", "Good", "Excellent"].map((q) => <option key={q} value={q}>{q === "all" ? "All quality" : q}</option>)}
                      </select>
                      <button data-testid="run-subset-button" onClick={runSubset} disabled={subLoading}
                        className="inline-flex items-center gap-2 rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60 transition-opacity">
                        {subLoading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Play className="h-3.5 w-3.5" />}
                        Run in R
                      </button>
                    </div>
                  } />
                {!subData && (
                  <p className="p-5 text-sm text-muted-foreground">
                    Choose filters above and click “Run in R” to analyse a subset. Each run executes a real Rscript on the filtered data.
                  </p>
                )}
                {subData && (
                  <div className="p-5 space-y-4">
                    <div className="flex flex-wrap items-center gap-3 text-sm">
                      <span data-testid="subset-n-value" className="rounded-md bg-secondary px-3 py-1.5 font-mono">
                        n = {subData.n}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        gender: <b>{subData.gender}</b> · sleep quality: <b>{subData.sleep_quality}</b>
                      </span>
                    </div>
                    {subData.n > 2 ? (
                      <div className="grid lg:grid-cols-2 gap-4">
                        <div>
                          <p className="mb-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Descriptive statistics</p>
                          <DataTable rows={subData.descriptive} testid="subset-desc-table" highlightCol="variable" />
                        </div>
                        <div>
                          <p className="mb-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Correlations with wellbeing</p>
                          <div className="space-y-2">
                            {subData.key_correlations?.map((r, i) => (
                              <div key={i} data-testid={`subset-corr-${i}`} className="flex items-center justify-between rounded-md border border-border px-3 py-2 text-xs">
                                <span className="font-mono">{r.x}</span>
                                <span className={`font-mono font-semibold ${r.estimate >= 0 ? "text-primary" : "text-rose-600 dark:text-rose-400"}`}>
                                  {r.estimate == null ? "—" : `r = ${Number(r.estimate).toFixed(3)}`}
                                </span>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    ) : (
                      <p className="text-sm text-amber-600 dark:text-amber-400">Subset too small for a reliable analysis.</p>
                    )}
                  </div>
                )}
              </Card>
            </Section>

            {/* ----------------- ANOVA Group Comparison ----------------- */}
            <Section id="anova">
              <Card testid="anova-card">
                <CardHead icon={Sigma} title="Group Comparison — One-way ANOVA"
                  sub="Tests whether mean wellbeing differs across the levels of a factor. aov() in R."
                  right={
                    <div className="flex flex-wrap items-center gap-2">
                      <div className="inline-flex rounded-md border border-border p-0.5 text-xs font-medium">
                        {["sleep_quality", "gender", "mood"].map((m) => (
                          <button key={m} data-testid={`anova-factor-${m}`} onClick={() => runAnova(m)}
                            className={`rounded px-2.5 py-1 transition-colors ${anovaFactor === m ? "bg-primary text-primary-foreground" : "hover:bg-accent"}`}>
                            {m.replace("_", " ")}
                          </button>
                        ))}
                      </div>
                      <button data-testid="run-anova-button" onClick={() => runAnova()} disabled={anovaLoading}
                        className="inline-flex items-center gap-2 rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60 transition-opacity">
                        {anovaLoading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Play className="h-3.5 w-3.5" />}
                        Run ANOVA in R
                      </button>
                    </div>
                  } />
                {!anovaData && (
                  <p className="p-5 text-sm text-muted-foreground">
                    Pick a factor and click “Run ANOVA in R”. The F test is computed on the cleaned data by a real Rscript.
                  </p>
                )}
                {anovaData && (
                  <>
                  <div className="grid lg:grid-cols-2 gap-px bg-border">
                    <div className="bg-card">
                      <p className="px-5 pt-4 pb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                        Wellbeing by {anovaData.factor.replace("_", " ")} (n = {anovaData.n})
                      </p>
                      <DataTable rows={anovaData.groups} testid="anova-groups-table" highlightCol="mean" />
                    </div>
                    <div className="bg-card p-5">
                      <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">ANOVA result</p>
                      <div className="grid grid-cols-2 gap-3">
                        <Stat testid="anova-f-stat" label="F statistic" value={anovaData.anova.f} />
                        <Stat testid="anova-eta" label="η² (effect size)" tone="violet" value={anovaData.anova.eta_sq} />
                      </div>
                      <div className="mt-3 flex items-center justify-between rounded-md border border-border px-3 py-2 text-sm">
                        <span className="text-muted-foreground">df = {anovaData.anova.df_between}, {anovaData.anova.df_within}</span>
                        <span data-testid="anova-p-value" className="font-mono">
                          {anovaData.anova.p < 0.001 ? "p < 0.001" : `p = ${Number(anovaData.anova.p).toPrecision(3)}`}
                        </span>
                      </div>
                      <div data-testid="anova-interpretation"
                        className={`mt-3 rounded-md px-3 py-2 text-xs font-medium ${anovaData.anova.p < 0.05 ? "bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-400" : "bg-secondary text-muted-foreground"}`}>
                        {anovaData.anova.p < 0.05
                          ? `Statistically significant difference in mean wellbeing across ${anovaData.factor.replace("_", " ")} groups (α = 0.05).`
                          : `No statistically significant difference across ${anovaData.factor.replace("_", " ")} groups (α = 0.05).`}
                      </div>
                    </div>
                  </div>
                  {anovaData.tukey?.length > 0 && (
                    <div className="border-t border-border p-5">
                      <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                        Tukey HSD post-hoc · pairwise differences (95% CI)
                      </p>
                      <div className="overflow-x-auto">
                        <table data-testid="tukey-table" className="w-full text-sm">
                          <thead>
                            <tr className="bg-secondary/70 text-left">
                              {["pair", "diff", "lwr", "upr", "p_adj", "significant"].map((c) => (
                                <th key={c} className="px-4 py-2.5 font-semibold text-foreground/80 whitespace-nowrap border-b border-border">{c}</th>
                              ))}
                            </tr>
                          </thead>
                          <tbody>
                            {anovaData.tukey.map((t, i) => {
                              const sig = t.p_adj < 0.05;
                              return (
                                <tr key={i} data-testid={`tukey-row-${i}`} className="odd:bg-background even:bg-secondary/30">
                                  <td className="px-4 py-2 font-mono text-xs border-b border-border/60">{t.pair}</td>
                                  <td className="px-4 py-2 font-mono text-xs border-b border-border/60">{t.diff}</td>
                                  <td className="px-4 py-2 font-mono text-xs border-b border-border/60 text-muted-foreground">{t.lwr}</td>
                                  <td className="px-4 py-2 font-mono text-xs border-b border-border/60 text-muted-foreground">{t.upr}</td>
                                  <td className="px-4 py-2 font-mono text-xs border-b border-border/60">{t.p_adj < 0.0001 ? "<0.0001" : t.p_adj}</td>
                                  <td className="px-4 py-2 border-b border-border/60">
                                    <span className={`rounded px-2 py-0.5 text-xs font-medium ${sig ? "bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-400" : "bg-secondary text-muted-foreground"}`}>
                                      {sig ? "yes" : "no"}
                                    </span>
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  )}
                  </>
                )}
              </Card>
            </Section>

            {/* ----------------- Multiple Linear Regression ----------------- */}
            <Section id="regression">
              <Card testid="regression-card">
                <CardHead icon={Sigma} title="Multiple Linear Regression"
                  sub="Models wellbeing from all numeric predictors at once. lm() in R."
                  right={
                    <button data-testid="run-regression-button" onClick={runRegression} disabled={regLoading}
                      className="inline-flex items-center gap-2 rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground hover:opacity-90 disabled:opacity-60 transition-opacity">
                      {regLoading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Play className="h-3.5 w-3.5" />}
                      Fit model in R
                    </button>
                  } />
                {!regData && (
                  <p className="p-5 text-sm text-muted-foreground">
                    Click “Fit model in R” to estimate a multiple linear regression of wellbeing on sleep, stress, exercise, caffeine, screen time and age.
                  </p>
                )}
                {regData && (
                  <div className="p-5 space-y-4">
                    <p className="font-mono text-xs text-muted-foreground break-all">{regData.formula}</p>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                      <Stat testid="reg-r2" label="R²" value={regData.r_squared} />
                      <Stat testid="reg-adj-r2" label="Adjusted R²" value={regData.adj_r_squared} />
                      <Stat testid="reg-f" label="F statistic" tone="violet" value={regData.f_statistic} />
                      <Stat testid="reg-n" label="Observations" tone="emerald" value={regData.n} />
                    </div>
                    <div className="overflow-x-auto">
                      <table data-testid="regression-coef-table" className="w-full text-sm">
                        <thead>
                          <tr className="bg-secondary/70 text-left">
                            {["term", "estimate", "std_error", "t_value", "p_value", "sig."].map((c) => (
                              <th key={c} className="px-4 py-2.5 font-semibold text-foreground/80 whitespace-nowrap border-b border-border">{c}</th>
                            ))}
                          </tr>
                        </thead>
                        <tbody>
                          {regData.coefficients.map((c, i) => {
                            const sig = c.p_value < 0.05;
                            return (
                              <tr key={i} data-testid={`reg-coef-${i}`} className="odd:bg-background even:bg-secondary/30">
                                <td className="px-4 py-2 font-mono text-xs border-b border-border/60 font-medium text-primary">{c.term}</td>
                                <td className={`px-4 py-2 font-mono text-xs border-b border-border/60 font-semibold ${c.estimate >= 0 ? "text-foreground/80" : "text-rose-600 dark:text-rose-400"}`}>{c.estimate}</td>
                                <td className="px-4 py-2 font-mono text-xs border-b border-border/60 text-muted-foreground">{c.std_error}</td>
                                <td className="px-4 py-2 font-mono text-xs border-b border-border/60">{c.t_value}</td>
                                <td className="px-4 py-2 font-mono text-xs border-b border-border/60">{c.p_value < 0.0001 ? "<0.0001" : c.p_value}</td>
                                <td className="px-4 py-2 border-b border-border/60">
                                  <span className={`rounded px-2 py-0.5 text-xs font-medium ${sig ? "bg-emerald-50 dark:bg-emerald-950/30 text-emerald-700 dark:text-emerald-400" : "bg-secondary text-muted-foreground"}`}>
                                    {sig ? "***" : "ns"}
                                  </span>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      The model explains ~{Math.round(regData.r_squared * 100)}% of the variance in (synthetic) wellbeing — recovering the relationships built into the data generator.
                    </p>
                  </div>
                )}
              </Card>
            </Section>

            {/* ----------------- Figures ----------------- */}
            <Section id="figures">
              <Card testid="figures-gallery-card">
                <CardHead icon={FlaskConical} title="Publication Figures (ggplot2)"
                  sub="High-resolution PNGs rendered directly by R."
                  right={
                    <a data-testid="export-bundle-button" href={`${API}/analysis/export`}
                      className="inline-flex items-center gap-1.5 rounded-md bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground hover:opacity-90 transition-opacity">
                      <Download className="h-3.5 w-3.5" /> Download all (zip)
                    </a>
                  } />
                <div data-testid="figures-gallery-grid" className="grid sm:grid-cols-2 gap-px bg-border">
                  {FIGS.map((f) => (
                    <div key={f.key} data-testid={f.testid} className="bg-card p-4">
                      <div className="mb-2 flex items-center justify-between">
                        <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">{f.title}</p>
                        <a data-testid={`figure-download-${f.key}`} href={`${API}/analysis/figures/${f.key}?download=1&v=${figKey}`}
                          className="inline-flex items-center gap-1 text-xs text-primary hover:underline">
                          <Download className="h-3.5 w-3.5" /> PNG
                        </a>
                      </div>
                      <a href={fig(f.key)} target="_blank" rel="noreferrer">
                        <img src={fig(f.key)} alt={f.title}
                          className="w-full rounded border border-border bg-white transition-transform hover:scale-[1.01]" />
                      </a>
                    </div>
                  ))}
                </div>
              </Card>
            </Section>

            {/* ----------------- Tests & Report ----------------- */}
            <Section id="tests">
              <div className="grid lg:grid-cols-2 gap-6">
                <Card testid="testthat-results-panel">
                  <CardHead icon={TerminalSquare} title="Automated Tests (testthat)"
                    sub="Runs tests/testthat on tiny known-answer datasets."
                    right={
                      <button data-testid="run-tests-button" onClick={runTests} disabled={testing}
                        className="inline-flex items-center gap-2 rounded-md border border-border px-3 py-1.5 text-xs font-semibold hover:bg-accent disabled:opacity-60 transition-colors">
                        {testing ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Play className="h-3.5 w-3.5" />}
                        Run tests
                      </button>
                    } />
                  <div className="p-5">
                    {testOut && (
                      <div className={`mb-3 inline-flex items-center gap-2 rounded-md px-3 py-1.5 text-xs font-semibold ${testOut.passed ? "bg-emerald-50 dark:bg-emerald-950/30 text-emerald-600 dark:text-emerald-400" : "bg-rose-50 dark:bg-rose-950/30 text-rose-600"}`}>
                        {testOut.passed ? <CheckCircle2 className="h-4 w-4" /> : <XCircle className="h-4 w-4" />}
                        {testOut.passed ? "All tests passed" : "Tests failed"}
                      </div>
                    )}
                    <pre data-testid="r-console-output-terminal"
                      className="max-h-72 overflow-auto rounded-md bg-[#0B0F17] p-4 font-mono text-xs leading-relaxed text-emerald-300">
{testOut ? testOut.output?.trim() : "// Click “Run tests” to execute the R testthat suite via Rscript."}
                    </pre>
                  </div>
                </Card>
                <Card testid="report-card">
                  <CardHead icon={FileText} title="Reproducible Report (R Markdown)"
                    sub="Methodology · results · limitations · sessionInfo()." />
                  <div className="p-5 space-y-4">
                    <p className="text-sm text-foreground/80">
                      The full reproducible report is rendered from <span className="font-mono">report/report.Rmd</span> with
                      methodology, results, figures and an explicit limitations section.
                    </p>
                    <button data-testid="rmarkdown-report-link" onClick={() => setShowReport((s) => !s)}
                      className="inline-flex items-center gap-2 rounded-md bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:opacity-90 transition-opacity">
                      <FileText className="h-4 w-4" /> {showReport ? "Hide report" : "View report inline"}
                    </button>
                    <a data-testid="report-newtab-link" href={`${API}/report`} target="_blank" rel="noreferrer"
                      className="ml-2 inline-flex items-center gap-2 rounded-md border border-border px-4 py-2 text-sm font-semibold hover:bg-accent transition-colors">
                      Open in new tab
                    </a>
                    {showReport && (
                      <iframe data-testid="report-iframe" title="R Markdown report" src={`${API}/report`}
                        className="mt-2 h-[520px] w-full rounded-md border border-border bg-white" />
                    )}
                    <div className="rounded-md border border-amber-400/50 bg-amber-50 dark:bg-amber-950/30 p-3 text-xs text-amber-700 dark:text-amber-400">
                      All dataset records are 100% synthetic, generated for academic demonstration only. They do not describe real people and carry no empirical claims.
                    </div>
                  </div>
                </Card>
              </div>
            </Section>
          </>
        )}
      </main>

      <footer className="border-t border-border py-6 text-center text-xs text-muted-foreground">
        Reproducible Research · Data Quality &amp; Analysis — a genuine R workflow (tidyverse · janitor · ggplot2 · R Markdown).
        All data synthetic.
      </footer>
    </div>
  );
}

export default App;
