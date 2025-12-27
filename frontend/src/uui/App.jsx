import React, { useMemo, useState } from "react";
import { load, save } from "./storage.js";
import { makeApi } from "./api.js";

const SCREENS=[
  {id:"dash", title:"Dashboard", hint:"Status + Quick Run"},
  {id:"keys", title:"UUI Bars", hint:"Keys/Hooks/OCR/TTS/Render/GitHub"},
  {id:"console", title:"Console", hint:"Logs"},
];

function now(){ return new Date().toISOString(); }

export default function App(){
  const [active,setActive]=useState("dash");
  const [settings,setSettings]=useState(load());
  const [logs,setLogs]=useState([`${now()} [BOOT] Atlas UUI loaded`]);
  const api=useMemo(()=>makeApi(settings.backendUrl.replace(/\/$/,""), settings.apiKey),[settings.backendUrl,settings.apiKey]);

  function log(line){ setLogs(p=>[...p,`${now()} ${line}`].slice(-600)); }
  function patch(p){ const next={...settings,...p}; setSettings(next); save(next); }

  return (
    <div className="layout">
      <aside className="sidebar card">
        <div className="brand">
          <div className="logo" />
          <div style={{minWidth:0}}>
            <div className="t1">ATLAS — Remote UUI</div>
            <div className="t2">Put keys → press buttons → output</div>
          </div>
        </div>

        <div className="nav">
          {SCREENS.map(s=>(
            <button key={s.id} className={"navbtn "+(active===s.id?"active":"")} onClick={()=>setActive(s.id)} title={s.hint}>
              <div style={{display:"flex",gap:10,alignItems:"center"}}>
                <span className="badge">{s.title}</span>
                <span className="small">{s.hint}</span>
              </div>
              <span className="small">↗</span>
            </button>
          ))}
        </div>

        <div style={{marginTop:"auto"}}>
          <div className="small">Backend URL</div>
          <input className="input" value={settings.backendUrl} onChange={e=>patch({backendUrl:e.target.value})}/>
          <div className="actions">
            <button className="btn" onClick={()=>{ patch(load()); log("[ACTION] settings reloaded"); }}>Reload</button>
            <button className="btn danger" onClick={()=>{ localStorage.clear(); const d=load(); setSettings(d); save(d); log("[ACTION] localStorage cleared"); }}>Reset</button>
          </div>
        </div>
      </aside>

      <main className="main">
        <div className="topbar card">
          <div>
            <div className="h1">Atlas Production Console</div>
            <div className="meta">Frontend served by backend after build</div>
          </div>
          <div style={{display:"flex",gap:8,flexWrap:"wrap"}}>
            <span className="badge">React/Vite</span>
            <span className="badge">UUI</span>
            <span className="badge">Backend: {settings.backendUrl}</span>
          </div>
        </div>

        <div className="card">
          <div className="tabs">
            {SCREENS.map(t=>(
              <button key={t.id} className={"tab "+(active===t.id?"active":"")} onClick={()=>setActive(t.id)}>{t.title}</button>
            ))}
          </div>

          <div className="panel">
            {active==="dash" && <Dash api={api} settings={settings} log={log} />}
            {active==="keys" && <Keys api={api} settings={settings} patch={patch} log={log} />}
            {active==="console" && <pre className="console">{logs.join("\n")}</pre>}
          </div>
        </div>
      </main>
    </div>
  );
}

function Dash({ api, settings, log }){
  const [state,setState]=useState({s:"idle"});
  async function health(){
    setState({s:"loading"}); log("[HEALTH] checking...");
    try{ const r=await api.health(); setState({s:"ok", r}); log(`[HEALTH] OK via ${r.path}`); }
    catch(e){ setState({s:"bad", e:String(e)}); log(`[HEALTH] FAIL ${String(e)}`); }
  }
  async function openapi(){
    setState({s:"loading"}); log("[OPENAPI] fetching...");
    try{ const d=await api.openapi(); setState({s:"ok", openapi:{title:d?.info?.title, version:d?.info?.version}}); log(`[OPENAPI] OK ${d?.info?.title} ${d?.info?.version}`); }
    catch(e){ setState({s:"bad", e:String(e)}); log(`[OPENAPI] FAIL ${String(e)}`); }
  }
  const badge = state.s==="ok" ? <span className="badge ok">ONLINE</span> : state.s==="bad" ? <span className="badge bad">OFFLINE</span> : <span className="badge">IDLE</span>;
  return (
    <div className="grid">
      <div className="card panel">
        <h2>Core Status</h2>
        <div className="actions">
          {badge}
          <span className="badge">API Key: {settings.apiKey?"set":"not set"}</span>
          <button className="btn primary" onClick={health}>Health</button>
          <button className="btn" onClick={openapi}>OpenAPI</button>
          <button className="btn" onClick={()=>window.open(settings.backendUrl.replace(/\/$/,"")+"/docs","_blank")}>/docs</button>
        </div>
        <div className="field" style={{marginTop:12}}>
          <div className="label">Result</div>
          {state.s==="loading" && <pre className="console">Loading...</pre>}
          {state.s==="bad" && <pre className="console">{state.e}</pre>}
          {state.s==="ok" && state.r?.data && <pre className="console">{JSON.stringify(state.r.data,null,2)}</pre>}
          {state.s==="ok" && state.openapi && <pre className="console">{JSON.stringify(state.openapi,null,2)}</pre>}
          {state.s==="idle" && <pre className="console">Press a button to start.</pre>}
        </div>
      </div>

      <div className="card panel">
        <h2>Immediate Actions</h2>
        <div className="grid2">
          <div className="field">
            <div className="label">Open Backend</div>
            <button className="btn" onClick={()=>window.open(settings.backendUrl,"_blank")}>Open</button>
          </div>
          <div className="field">
            <div className="label">Copy Settings JSON</div>
            <button className="btn" onClick={()=>navigator.clipboard.writeText(JSON.stringify(settings,null,2))}>Copy</button>
          </div>
        </div>
      </div>
    </div>
  );
}

function Keys({ api, settings, patch, log }){
  const mask = (v)=> !v ? "" : (v.length<=8 ? "********" : v.slice(0,4)+"…"+v.slice(-4));
  async function pull(){
    log("[SETTINGS] pull /api/settings ...");
    try{ const d=await api.getSettings(); patch(d); log("[SETTINGS] pulled OK"); }
    catch(e){ log(`[SETTINGS] pull FAIL ${String(e)}`); }
  }
  async function push(){
    log("[SETTINGS] push /api/settings ...");
    try{ const d=await api.saveSettings(settings); log("[SETTINGS] pushed OK "+JSON.stringify(d)); }
    catch(e){ log(`[SETTINGS] push FAIL ${String(e)}`); }
  }
  return (
    <div className="grid">
      <div className="card panel">
        <h2>UUI Bars</h2>
        <div className="grid2">
          <div className="field">
            <div className="label">General API Key</div>
            <input className="input" value={settings.apiKey} onChange={e=>patch({apiKey:e.target.value})} placeholder="Bearer (optional)"/>
            <div className="small">Masked: {mask(settings.apiKey)}</div>
          </div>
          <div className="field">
            <div className="label">TTS Key</div>
            <input className="input" value={settings.ttsKey} onChange={e=>patch({ttsKey:e.target.value})}/>
            <div className="small">Masked: {mask(settings.ttsKey)}</div>
          </div>
          <div className="field">
            <div className="label">OCR Key</div>
            <input className="input" value={settings.ocrKey} onChange={e=>patch({ocrKey:e.target.value})}/>
            <div className="small">Masked: {mask(settings.ocrKey)}</div>
          </div>
          <div className="field">
            <div className="label">Webhook URL</div>
            <input className="input" value={settings.webhookUrl} onChange={e=>patch({webhookUrl:e.target.value})}/>
          </div>
          <div className="field">
            <div className="label">GitHub Token</div>
            <input className="input" value={settings.githubToken} onChange={e=>patch({githubToken:e.target.value})}/>
            <div className="small">Masked: {mask(settings.githubToken)}</div>
          </div>
          <div className="field">
            <div className="label">Render API Key</div>
            <input className="input" value={settings.renderApiKey} onChange={e=>patch({renderApiKey:e.target.value})}/>
            <div className="small">Masked: {mask(settings.renderApiKey)}</div>
          </div>
        </div>
        <div className="actions">
          <button className="btn primary" onClick={()=>log("[LOCAL] settings saved localStorage")}>Save Local</button>
          <button className="btn" onClick={pull}>Pull Backend</button>
          <button className="btn" onClick={push}>Push Backend</button>
        </div>
      </div>

      <div className="card panel">
        <h2>Fast Start</h2>
        <pre className="console">{`1) Put keys
2) Dashboard -> Health
3) /docs
4) Push settings (optional)
Done.`}</pre>
      </div>
    </div>
  );
}
