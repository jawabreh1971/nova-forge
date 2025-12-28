# Atlas Production ENV

هذه المتغيرات تجعل Atlas Production-ready بشكل محترم.

## Required (الحد الأدنى)
- `ATLAS_ENV=prod|staging|dev`
- `ATLAS_LOG_LEVEL=INFO|DEBUG|WARNING|ERROR`
- `ATLAS_SERVICE_NAME=atlas`
- `ATLAS_VERSION=1.0.0`

## Security
- `ATLAS_API_KEY`  (إن كنت تستخدم API Key auth في مشروعك)
- `ATLAS_RATE_LIMIT_RPS=5`  (اختياري)
- `ATLAS_RATE_LIMIT_BURST=10` (اختياري)

## Observability
- `ATLAS_ENABLE_METRICS=1`
- `ATLAS_METRICS_PATH=/metrics`

## Audit (اختياري)
- `ATLAS_ENABLE_AUDIT=1`
- `ATLAS_AUDIT_PATH=./data/audit.log`

## Notes
- في Render: ضعها في Environment Variables.
- محليًا: استخدم `.env` أو `export ...`

