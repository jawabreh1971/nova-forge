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
