# Atlas — Production Upgrade Pack v1 (Overlay, Not Rebuild)
تاريخ: 2025-12-28

هذه الحزمة **ليست منصة جديدة**. هي **Overlay** تُدمج داخل مشروع Atlas الموجود لديك (الموجود على GitHub/Render).
تضيف طبقة Production جاهزة: إعدادات صارمة، سجلات JSON، Correlation ID، Error Registry، Health/Readiness، Metrics، Rate Limit (خفيف)، Audit Log، ووثائق تشغيل.

## مبدأ الدمج
- انسخ محتوى الحزمة إلى جذر مستودع Atlas.
- شغّل سكربت الدمج في Termux.
- أضف **سطر واحد** في ملف إنشاء تطبيق FastAPI الحالي (عادة `backend/app/main.py` أو `backend/main.py`) لتفعيل الطبقة.
- ادفع إلى GitHub، ثم Render يعمل Deploy تلقائيًا.

> مهم: لأننا لا نملك كود Atlas الحالي داخل هذه الجلسة، الحزمة تتجنب كسر مشروعك وتعمل بأسلوب "Hook/Bootstrap".
> التفعيل النهائي يحتاج سطر واحد فقط داخل نقطة إنشاء الـ app.

---

## 1) الدمج على Termux
افترض أن مشروعك في:
`$HOME/nova-forge` (غيّر المسار لو مختلف)

### أوامر:
```bash
cd "$HOME/nova-forge"
unzip -o /path/to/atlas_prod_upgrade_pack_v1.zip -d .
bash ops/termux/apply_prod_pack.sh
```

السكربت سيقوم بـ:
- إضافة مجلد `atlas_prod/` (طبقة الإنتاج)
- إضافة ملفات `ops/` و `docs/`
- إضافة `.dockerignore` و `Dockerfile` إن لم تكن موجودة (أو يترك الحالي ويضع نسخة بديلة باسم `Dockerfile.atlas_prod`)
- إضافة `requirements-prod.txt` وتوصية دمجها في requirements الأساسي

---

## 2) التفعيل داخل FastAPI (سطر واحد)
ابحث عن مكان فيه:
`app = FastAPI(...)`

ثم أضف بعده مباشرة:

```python
from atlas_prod.bootstrap import apply_production_defaults
apply_production_defaults(app)
```

**إذا لديك Router رئيسي**: لا تغيره. طبقة الإنتاج تضيف Middlewares و Endpoints فقط.

---

## 3) تشغيل محلي سريع (Termux)
```bash
bash ops/termux/run_local_prod.sh
```

ثم افتح:
- `http://127.0.0.1:8080/health`
- `http://127.0.0.1:8080/ready`
- `http://127.0.0.1:8080/metrics`

---

## 4) Render
- ادفع التغييرات إلى GitHub.
- Render يعيد البناء.
- تأكد أن:
  - Health check path = `/health`
  - Port = `8080` (أو حسب بيئتك)

---

## 5) ماذا تضيف هذه الحزمة فعليًا؟
- Structured JSON Logging + request_id
- Error registry + Unified error responses
- Health/Ready endpoints
- Prometheus Metrics endpoint
- Basic rate limiting middleware (اختياري)
- Audit log file (اختياري)
- Config validation (Fail-fast)

---

## 6) المتغيرات البيئية (ENV)
راجع `docs/PROD_ENV.md` لإعداد ENV المطلوب.

---

## ملاحظة حاسمة
إذا كان مشروعك لا يملك Backend FastAPI فعليًا أو ملف app غير موجود، هذه الحزمة لن "تخلق" backend من الصفر.
هي طبقة Production تُركب فوق Backend موجود.

