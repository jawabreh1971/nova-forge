#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$(pwd)"

echo "[1/7] Ensure data dir"
mkdir -p "$ROOT/data"

echo "[2/7] Add backend runtime module (settings + openai client)"
cat > "$ROOT/atlas_runtime.py" <<'PY'
import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx

DATA_DIR = Path(os.getenv("ATLAS_DATA_DIR", Path(__file__).parent / "data"))
DATA_DIR.mkdir(parents=True, exist_ok=True)
SETTINGS_PATH = DATA_DIR / "settings.json"

DEFAULTS = {
    "provider": "openai",
    "openai_api_key": "",
    "openai_base_url": "https://api.openai.com/v1",
    "openai_model": "gpt-4o-mini",
}

def _safe_read_json(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}

def load_settings() -> Dict[str, Any]:
    env_overlay = {
        "provider": os.getenv("ATLAS_PROVIDER", ""),
        "openai_api_key": os.getenv("OPENAI_API_KEY", ""),
        "openai_base_url": os.getenv("OPENAI_BASE_URL", ""),
        "openai_model": os.getenv("OPENAI_MODEL", ""),
    }
    file_data = _safe_read_json(SETTINGS_PATH)
    merged = {**DEFAULTS, **file_data}
    for k, v in env_overlay.items():
        if v:
            merged[k] = v
    return merged

def save_settings(patch: Dict[str, Any]) -> Dict[str, Any]:
    current = load_settings()
    # Only allow known keys
    allowed = set(DEFAULTS.keys())
    for k, v in patch.items():
        if k in allowed:
            current[k] = v if v is not None else current.get(k)
    SETTINGS_PATH.write_text(json.dumps(current, ensure_ascii=False, indent=2), encoding="utf-8")
    return current

def masked_settings(settings: Dict[str, Any]) -> Dict[str, Any]:
    s = dict(settings)
    k = s.get("openai_api_key", "") or ""
    if k:
        s["openai_api_key"] = (k[:4] + "…" + k[-4:]) if len(k) >= 10 else "****"
    else:
        s["openai_api_key"] = ""
    return s

async def openai_chat(messages: List[Dict[str, str]], settings: Dict[str, Any]) -> str:
    api_key = (settings.get("openai_api_key") or "").strip()
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY missing. Set it in Settings first.")
    base_url = (settings.get("openai_base_url") or "https://api.openai.com/v1").rstrip("/")
    model = (settings.get("openai_model") or "gpt-4o-mini").strip()

    url = f"{base_url}/chat/completions"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    payload = {
        "model": model,
        "messages": messages,
        "temperature": 0.3,
    }

    timeout = httpx.Timeout(60.0, connect=20.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        r = await client.post(url, headers=headers, json=payload)
        if r.status_code >= 400:
            # keep error concise
            raise RuntimeError(f"LLM error {r.status_code}: {r.text[:500]}")
        data = r.json()
        return (data.get("choices", [{}])[0].get("message", {}) or {}).get("content", "") or ""
PY

echo "[3/7] Patch requirements (add httpx only if missing)"
if ! grep -qE '^httpx==' "$ROOT/requirements.txt" 2>/dev/null; then
  echo 'httpx==0.27.2' >> "$ROOT/requirements.txt"
fi

echo "[4/7] Patch backend (asgi.py): add /api/settings + real /api/chat"
python - <<'PY'
from pathlib import Path
p = Path("asgi.py")
s = p.read_text(encoding="utf-8")

# Ensure imports
need_imports = [
    "from typing import Any, Dict, List, Optional",
    "from fastapi import FastAPI, HTTPException",
]
for imp in need_imports:
    if imp not in s:
        # add near top
        lines = s.splitlines()
        insert_at = 0
        for i, line in enumerate(lines[:30]):
            if line.startswith("from fastapi") or line.startswith("import "):
                insert_at = i+1
        lines.insert(insert_at, imp)
        s = "\n".join(lines)

# Ensure atlas_runtime import
if "import atlas_runtime" not in s:
    lines = s.splitlines()
    insert_at = 0
    for i, line in enumerate(lines[:40]):
        if "FastAPI" in line or line.startswith("from fastapi"):
            insert_at = i+1
    lines.insert(insert_at, "import atlas_runtime")
    s = "\n".join(lines)

# Add endpoints block if not present
marker = "# === ATLAS API (Settings + Chat) ==="
if marker not in s:
    append = r'''

# === ATLAS API (Settings + Chat) ===

@app.get("/api/settings")
def api_get_settings() -> Dict[str, Any]:
    settings = atlas_runtime.load_settings()
    return atlas_runtime.masked_settings(settings)

@app.post("/api/settings")
def api_set_settings(payload: Dict[str, Any]) -> Dict[str, Any]:
    # Minimal protection: optional ADMIN_TOKEN
    admin_token = (os.getenv("ATLAS_ADMIN_TOKEN", "") or "").strip()
    if admin_token:
        supplied = (payload.get("admin_token") or "").strip()
        if supplied != admin_token:
            raise HTTPException(status_code=401, detail="Unauthorized")

    patch = dict(payload)
    patch.pop("admin_token", None)
    settings = atlas_runtime.save_settings(patch)
    return atlas_runtime.masked_settings(settings)

@app.post("/api/chat")
async def api_chat(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    payload:
      - messages: [{role: 'system'|'user'|'assistant', content: '...'}]
    """
    messages = payload.get("messages", [])
    if not isinstance(messages, list) or not messages:
        raise HTTPException(status_code=400, detail="messages[] required")

    settings = atlas_runtime.load_settings()
    try:
        text = await atlas_runtime.openai_chat(messages=messages, settings=settings)
        return {"ok": True, "reply": text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)[:500])
'''
    # Ensure os imported for token check
    if "import os" not in s:
        s = "import os\n" + s
    s = s + append

p.write_text(s, encoding="utf-8")
print("asgi.py patched")
PY

echo "[5/7] Add Vite UUI pages: Settings + ChatDock (stable + history)"
mkdir -p "$ROOT/frontend/src/components" "$ROOT/frontend/src/pages"

cat > "$ROOT/frontend/src/pages/Settings.tsx" <<'TSX'
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
TSX

cat > "$ROOT/frontend/src/components/ChatDock.tsx" <<'TSX'
import React, { useEffect, useMemo, useRef, useState } from "react";

type Msg = { role: "system" | "user" | "assistant"; content: string };

const LS_KEY = "atlas_chat_history_v1";

function loadHistory(): Msg[] {
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (!raw) return [];
    const arr = JSON.parse(raw);
    if (!Array.isArray(arr)) return [];
    return arr.filter((x) => x && typeof x.role === "string" && typeof x.content === "string");
  } catch {
    return [];
  }
}

function saveHistory(msgs: Msg[]) {
  try {
    localStorage.setItem(LS_KEY, JSON.stringify(msgs.slice(-50)));
  } catch {}
}

export default function ChatDock() {
  const [open, setOpen] = useState(true);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState("");

  const [messages, setMessages] = useState<Msg[]>(() => {
    const hist = loadHistory();
    if (hist.length) return hist;
    return [{ role: "system", content: "You are Atlas. Be concise, practical, and accurate." }];
  });

  const listRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    saveHistory(messages);
    // scroll down
    requestAnimationFrame(() => {
      if (listRef.current) listRef.current.scrollTop = listRef.current.scrollHeight;
    });
  }, [messages]);

  const send = async () => {
    const text = input.trim();
    if (!text || busy) return;

    setErr("");
    setBusy(true);

    const next: Msg[] = [...messages, { role: "user", content: text }];
    setMessages(next);
    setInput("");

    try {
      const r = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: next }),
      });
      const j = await r.json();
      if (!r.ok) throw new Error(j?.detail || "Chat failed");
      const reply = String(j?.reply || "").trim();
      setMessages((prev) => [...prev, { role: "assistant", content: reply || "(empty reply)" }]);
    } catch (e: any) {
      setErr(String(e?.message || e));
    } finally {
      setBusy(false);
    }
  };

  const clear = () => {
    const base: Msg[] = [{ role: "system", content: "You are Atlas. Be concise, practical, and accurate." }];
    setMessages(base);
    saveHistory(base);
  };

  return (
    <div style={{ position: "fixed", right: 14, bottom: 14, width: open ? 420 : 160, zIndex: 9999 }}>
      <div style={{ border: "1px solid rgba(255,255,255,0.15)", borderRadius: 12, overflow: "hidden", backdropFilter: "blur(8px)" }}>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: 10, background: "rgba(0,0,0,0.55)" }}>
          <div style={{ fontWeight: 700 }}>Atlas Chat</div>
          <div style={{ display: "flex", gap: 8 }}>
            <button onClick={clear} style={{ padding: "6px 10px", cursor: "pointer" }}>Clear</button>
            <button onClick={() => setOpen((v) => !v)} style={{ padding: "6px 10px", cursor: "pointer" }}>{open ? "Hide" : "Show"}</button>
          </div>
        </div>

        {open ? (
          <>
            <div ref={listRef} style={{ height: 360, overflow: "auto", padding: 10, background: "rgba(0,0,0,0.35)" }}>
              {messages.filter(m => m.role !== "system").map((m, idx) => (
                <div key={idx} style={{ marginBottom: 10, display: "flex", justifyContent: m.role === "user" ? "flex-end" : "flex-start" }}>
                  <div style={{
                    maxWidth: "86%",
                    padding: 10,
                    borderRadius: 10,
                    background: m.role === "user" ? "rgba(255,255,255,0.12)" : "rgba(0, 128, 255, 0.18)",
                    whiteSpace: "pre-wrap"
                  }}>
                    {m.content}
                  </div>
                </div>
              ))}
              {busy ? <div style={{ opacity: 0.75, padding: 6 }}>Thinking…</div> : null}
              {err ? <div style={{ background: "#3b0a0a", padding: 8, borderRadius: 8 }}>{err}</div> : null}
            </div>

            <div style={{ display: "flex", gap: 8, padding: 10, background: "rgba(0,0,0,0.55)" }}>
              <input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => { if (e.key === "Enter") send(); }}
                placeholder="Type…"
                style={{ flex: 1, padding: 10 }}
              />
              <button onClick={send} disabled={busy} style={{ padding: "10px 14px", cursor: "pointer" }}>
                Send
              </button>
            </div>
          </>
        ) : null}
      </div>
    </div>
  );
}
TSX

echo "[6/7] Wire App.tsx to include ChatDock + Settings page (minimal router-less)"
cat > "$ROOT/frontend/src/App.tsx" <<'TSX'
import React, { useState } from "react";
import ChatDock from "./components/ChatDock";
import SettingsPage from "./pages/Settings";

export default function App() {
  const [tab, setTab] = useState<"home" | "settings">("home");

  return (
    <div style={{ minHeight: "100vh", padding: 16 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
        <div>
          <div style={{ fontSize: 22, fontWeight: 800 }}>Atlas</div>
          <div style={{ opacity: 0.7, fontSize: 12 }}>UUI Frontend (Vite/React) + Backend (FastAPI)</div>
        </div>

        <div style={{ display: "flex", gap: 8 }}>
          <button onClick={() => setTab("home")} style={{ padding: "10px 12px", cursor: "pointer" }}>Home</button>
          <button onClick={() => setTab("settings")} style={{ padding: "10px 12px", cursor: "pointer" }}>Settings</button>
          <a href="/docs" style={{ padding: "10px 12px" }}>API Docs</a>
        </div>
      </div>

      <div style={{ marginTop: 16 }}>
        {tab === "home" ? (
          <div style={{ opacity: 0.85 }}>
            <p style={{ marginTop: 0 }}>
              1) Go to <b>Settings</b> and set the API key. 2) Use the chat dock at bottom-right.
            </p>
            <p>
              Health: <code>/healthz</code> — API: <code>/api/chat</code>, <code>/api/settings</code>
            </p>
          </div>
        ) : (
          <SettingsPage />
        )}
      </div>

      <ChatDock />
    </div>
  );
}
TSX

echo "[7/7] Build frontend (optional) + done"
echo "Patch applied. Now run:"
echo "  (1) python -m pip install -r requirements.txt"
echo "  (2) cd frontend && npm i && npm run build"
echo "  (3) run local: python -m uvicorn asgi:app --host 127.0.0.1 --port 8000"
