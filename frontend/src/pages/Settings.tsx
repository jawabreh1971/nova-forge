import React, { useEffect, useState } from "react";

type Settings = {
  provider?: string;
  openai_api_key?: string;
  openai_base_url?: string;
  openai_model?: string;
};

export default function SettingsPage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string>("");
  const [ok, setOk] = useState<string>("");

  const [adminToken, setAdminToken] = useState<string>("");
  const [apiKey, setApiKey] = useState<string>("");
  const [baseUrl, setBaseUrl] = useState<string>("https://api.openai.com/v1");
  const [model, setModel] = useState<string>("gpt-4o-mini");

  useEffect(() => {
    (async () => {
      try {
        setErr("");
        const r = await fetch("/api/settings");
        const j = await r.json();
        if (!r.ok) throw new Error(j?.detail || "Failed to load settings");
        setApiKey(j?.openai_api_key || "");
        setBaseUrl(j?.openai_base_url || "https://api.openai.com/v1");
        setModel(j?.openai_model || "gpt-4o-mini");
      } catch (e: any) {
        setErr(String(e?.message || e));
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const save = async () => {
    setSaving(true);
    setOk("");
    setErr("");
    try {
      const payload: any = {
        provider: "openai",
        openai_api_key: apiKey,
        openai_base_url: baseUrl,
        openai_model: model,
      };
      if (adminToken.trim()) payload.admin_token = adminToken.trim();

      const r = await fetch("/api/settings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      const j = await r.json();
      if (!r.ok) throw new Error(j?.detail || "Failed to save settings");
      setOk("Saved.");
      // keep masked key if backend masks it
      setApiKey(j?.openai_api_key || apiKey);
    } catch (e: any) {
      setErr(String(e?.message || e));
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div style={{ padding: 16 }}>Loading settings…</div>;

  return (
    <div style={{ padding: 16, maxWidth: 760 }}>
      <h2 style={{ margin: "0 0 8px 0" }}>Settings</h2>
      <p style={{ marginTop: 0, opacity: 0.75 }}>
        Put your keys here once. Chat will use them immediately.
      </p>

      {err ? <div style={{ background: "#3b0a0a", padding: 10, borderRadius: 8, marginBottom: 10 }}>{err}</div> : null}
      {ok ? <div style={{ background: "#0a3b1a", padding: 10, borderRadius: 8, marginBottom: 10 }}>{ok}</div> : null}

      <div style={{ display: "grid", gap: 10 }}>
        <label>
          <div style={{ fontSize: 12, opacity: 0.8 }}>Admin Token (optional)</div>
          <input value={adminToken} onChange={(e) => setAdminToken(e.target.value)} placeholder="If ATLAS_ADMIN_TOKEN is set on server" style={{ width: "100%", padding: 10 }} />
        </label>

        <label>
          <div style={{ fontSize: 12, opacity: 0.8 }}>OpenAI API Key</div>
          <input value={apiKey} onChange={(e) => setApiKey(e.target.value)} placeholder="sk-..." style={{ width: "100%", padding: 10 }} />
        </label>

        <label>
          <div style={{ fontSize: 12, opacity: 0.8 }}>Base URL</div>
          <input value={baseUrl} onChange={(e) => setBaseUrl(e.target.value)} placeholder="https://api.openai.com/v1" style={{ width: "100%", padding: 10 }} />
        </label>

        <label>
          <div style={{ fontSize: 12, opacity: 0.8 }}>Model</div>
          <input value={model} onChange={(e) => setModel(e.target.value)} placeholder="gpt-4o-mini" style={{ width: "100%", padding: 10 }} />
        </label>

        <button onClick={save} disabled={saving} style={{ padding: 12, cursor: "pointer" }}>
          {saving ? "Saving…" : "Save"}
        </button>
      </div>
    </div>
  );
}
