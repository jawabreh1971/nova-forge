import axios from "axios";
export function makeApi(baseURL, apiKey){
  const a = axios.create({
    baseURL,
    timeout: 15000,
    headers: apiKey ? { Authorization: `Bearer ${apiKey}` } : {},
  });
  return {
    async health(){
      try{ const r = await a.get("/health"); return {ok:true, path:"/health", data:r.data}; }
      catch{ const r = await a.get("/healthz"); return {ok:true, path:"/healthz", data:r.data}; }
    },
    async openapi(){ const r = await a.get("/openapi.json"); return r.data; },
    async getSettings(){ const r = await a.get("/api/settings"); return r.data; },
    async saveSettings(payload){ const r = await a.post("/api/settings", payload); return r.data; },
  };
}
