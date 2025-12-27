const KEY="atlas_uui_settings_v1";
export function defaults(){
  return {
    backendUrl: import.meta.env.VITE_BACKEND_URL || window.location.origin,
    apiKey:"",
    ttsKey:"",
    ocrKey:"",
    webhookUrl:"",
    whatsappHook:"",
    emailHook:"",
    githubToken:"",
    renderApiKey:"",
  };
}
export function load(){
  try{
    const raw = localStorage.getItem(KEY);
    if(!raw) return defaults();
    return { ...defaults(), ...JSON.parse(raw) };
  }catch{ return defaults(); }
}
export function save(v){ localStorage.setItem(KEY, JSON.stringify(v)); }
