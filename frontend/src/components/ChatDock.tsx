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
