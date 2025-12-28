# Atlas — RUNBOOK (Production Operations)

## Health
- GET `/health` : ليفنس (الخدمة شغالة)
- GET `/ready`  : جاهزية (مثلاً اتصالات خارجية/DB إن وجدت)
- GET `/metrics`: مقاييس Prometheus

## Logging
- Logs JSON مع `request_id`
- أي خطأ يرجع:
  - `error_code`
  - `message`
  - `request_id`

## Common incidents
### 1) 502/503 from Render
- تحقق من PORT
- تحقق أن التطبيق يستمع على `0.0.0.0`
- تحقق من `/health` path

### 2) Deploy loops
- تحقق من Dockerfile و start command
- شغّل محليًا عبر `ops/termux/run_local_prod.sh`

### 3) No module / Import errors
- غالبًا mismatch في paths
- تأكد أن `PYTHONPATH` يشمل جذر backend أو استخدم `uvicorn backend.app.main:app`

