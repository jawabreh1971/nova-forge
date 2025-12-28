# Atlas Production Checklist (Lock)

## Must-have
- [ ] Health `/health` returns 200
- [ ] Ready `/ready` returns 200
- [ ] Metrics `/metrics` returns 200 (or disabled explicitly)
- [ ] JSON logs (structured)
- [ ] request_id present in logs and responses
- [ ] unified error payload includes `error_code` + `request_id`
- [ ] basic rate-limit enabled in prod (optional but recommended)
- [ ] ENV validated (fail-fast if critical missing)
- [ ] Dockerfile builds consistently on Render

## Recommended
- [ ] Audit log enabled for sensitive actions
- [ ] Basic smoke test run before every deploy
- [ ] Runbook updated with known incidents

