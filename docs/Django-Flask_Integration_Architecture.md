# Django-Flask 연결 구조 문서

## 1. 전체 아키텍처 개요

```
[Flutter Client]
      |
      | HTTP Request (JWT Token)
      v
[Nginx :80] (GCP)
      |
      | Reverse Proxy
      v
[Django API :8000]
      |
      | HTTP Proxy (API Key)
      v
[Flask ML :9000]
      |
      | ML Pipeline
      v
[ML Model (XGBoost RandomForest)]
```

### 주요 구성 요소

1. **Django REST Framework**: API Gateway 역할
   - 사용자 인증 (JWT)
   - 권한 검증
   - 데이터베이스 CRUD
   - Flask ML 서버 프록시
   - 예측 결과 자동 저장

2. **Flask ML Server**: ML 추론 서버
   - 경량 ML 전용 서버
   - 모델 로딩 및 예측 처리
   - API Key 기반 인증
   - Rate Limiting

3. **Nginx**: 리버스 프록시
   - GCP 외부 접근 포인트 (포트 80)
   - Django로 요청 전달

---

## 2. Django 설정 (config/settings.py)

### ML 서버 연동 설정

```python
# ML 서버 연동
ML_BASE_URL = os.getenv("ML_BASE_URL", "http://127.0.0.1:9000")
ML_API_KEY  = os.getenv("ML_API_KEY", "")
```

**환경 변수 (.env)**:
```env
ML_BASE_URL=http://127.0.0.1:9000
ML_API_KEY=your-secure-api-key-here
```

### Django 앱 구성

```python
INSTALLED_APPS = [
    # ...
    "rest_framework",
    "corsheaders",
    "mlproxy",        # ML 프록시 앱
    "predictions",    # 예측 결과 관리
    # ...
]
```

### JWT 인증 설정

```python
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=3),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=14),
}
```

---

## 3. Django URL 라우팅

### 메인 URL 설정 (config/urls.py)

```python
urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("accounts.urls")),
    path("api/patients/", include("patients.urls")),
    path("api/ml/", include("mlproxy.urls")),      # ML 프록시
    path("api/", include("doctors.urls")),
    path("api/", include("predictions.urls")),     # 예측 결과
    path("api/", include("prescription.urls")),
]
```

### ML 프록시 URL (mlproxy/urls.py)

```python
from django.urls import path
from .views import SchemaView, PredictView, ReloadModelView

urlpatterns = [
    path("schema/", SchemaView.as_view()),      # GET /api/ml/schema/
    path("predict/", PredictView.as_view()),    # POST /api/ml/predict/
    path("reload/", ReloadModelView.as_view()), # POST /api/ml/reload/
]
```

**엔드포인트 매핑**:
- `GET /api/ml/schema/` → `GET http://127.0.0.1:9000/schema`
- `POST /api/ml/predict/` → `POST http://127.0.0.1:9000/predict`
- `POST /api/ml/reload/` → `POST http://127.0.0.1:9000/reload`

---

## 4. Django ML Proxy 구현 (mlproxy/views.py)

### 4.1 SchemaView - ML 모델 스키마 조회

```python
class SchemaView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # Flask는 Authorization: Bearer <API_KEY> 형식 요구
        headers = {"Authorization": f"Bearer {settings.ML_API_KEY}"}
        try:
            r = requests.get(f"{settings.ML_BASE_URL}/schema", headers=headers, timeout=5)
            return Response(r.json(), status=r.status_code)
        except requests.RequestException as e:
            return Response({"detail": str(e)}, status=502)
```

**요청 흐름**:
1. Flutter → Django (JWT 인증)
2. Django → Flask (API Key 인증)
3. Flask → Django (스키마 JSON)
4. Django → Flutter (스키마 JSON)

**응답 예시**:
```json
{
  "algorithm": "RandomForest",
  "threshold": 0.29,
  "schema": {
    "base_features": ["age", "duration_of_symptoms", ...],
    "derived_features": ["LDH_ratio", "protein_ratio", "exposure_age_ratio"],
    "selected_features": ["exposure_age_ratio", "age", "platelet_count_(PLT)", ...]
  }
}
```

### 4.2 PredictView - ML 예측 + 자동 저장

```python
class PredictView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """
        요청 JSON 예:
        {
          "patient_id": 12,
          "model_name": "meso_xgb_v1",    # (옵션) 없으면 기본값 사용
          "data": [ { ... 11개 base_features ... } ]
        }
        """
        headers = {"Authorization": f"Bearer {settings.ML_API_KEY}"}

        # 1) Flask-ML에 프록시
        r = requests.post(
            f"{settings.ML_BASE_URL}/predict",
            headers=headers,
            json=request.data,
            timeout=15
        )

        # 2) 성공 시 자동 저장
        try:
            payload = r.json()
        except Exception:
            return Response({"detail": "invalid response from ml server"}, status=502)

        if r.status_code == 200:
            # 저장 트리거: patient_id 존재 + 결과 형식 정상
            patient_id = request.data.get("patient_id")
            model_name = request.data.get("model_name") or "meso_xgb"

            if patient_id and isinstance(payload, dict):
                features = payload.get("features")
                proba = payload.get("pred_proba", [])
                label = payload.get("pred_label", [])
                rows = request.data.get("data", [])

                # 단건 저장(첫 행 기준)
                if rows and features and isinstance(proba, list) and isinstance(label, list) and len(proba) >= 1 and len(label) >= 1:
                    try:
                        patient = Patient.objects.get(id=patient_id)
                        req_doctor = getattr(request.user, "doctor", None)  # 요청자가 의사면 기록
                        PredictionResult.objects.create(
                            patient=patient,
                            requested_by_doctor=req_doctor,
                            created_by=request.user,
                            model_name=model_name,
                            input_data=rows[0],
                            output_label=int(label[0]),
                            output_proba=float(proba[0]),
                        )
                    except Exception as e:
                        # 저장 실패는 예측 응답 자체에는 영향 주지 않음
                        pass

        return Response(payload, status=r.status_code)
```

**핵심 로직**:
1. **Flask ML 프록시**: Django가 Flask로 요청 전달
2. **자동 저장**: `patient_id`가 있고 예측 성공 시 `PredictionResult` 테이블에 자동 저장
3. **요청자 기록**: 의사가 요청한 경우 `requested_by_doctor` 필드에 기록
4. **저장 실패 무시**: 예측 결과는 반환하되, DB 저장 실패는 무시

**요청 예시**:
```json
{
  "patient_id": 12,
  "model_name": "meso_xgb_v1",
  "data": [
    {
      "age": 65,
      "duration_of_symptoms": 30,
      "platelet_count_(PLT)": 250000,
      "cell_count_(WBC)": 8000,
      "blood_lactic_dehydrogenise_(LDH)": 200,
      "pleural_lactic_dehydrogenise": 600,
      "pleural_protein": 4.5,
      "total_protein": 7.2,
      "albumin": 3.8,
      "C-reactive_protein_(CRP)": 15,
      "duration_of_asbestos_exposure": 20
    }
  ]
}
```

**응답 예시**:
```json
{
  "base_features": ["age", "duration_of_symptoms", ...],
  "threshold": 0.29,
  "pred_proba": [0.75],
  "pred_label": [1]
}
```

### 4.3 ReloadModelView - 모델 재로딩

```python
class ReloadModelView(views.APIView):
    permission_classes = [IsAdmin]  # 관리자 전용

    def post(self, request):
        headers = {"Authorization": f"Bearer {settings.ML_API_KEY}"}
        try:
            r = requests.post(f"{settings.ML_BASE_URL}/reload", headers=headers, timeout=5)
            return Response(r.json(), status=r.status_code)
        except requests.RequestException as e:
            return Response({"detail": str(e)}, status=502)
```

**용도**: 새로운 ML 모델 배포 시 서버 재시작 없이 모델 리로딩

---

## 5. Flask ML 서버 구현 (flask_ml/app.py)

### 5.1 환경 설정

```python
load_dotenv()

API_KEY     = os.getenv("API_KEY", "").strip()
MODEL_DIR   = os.getenv("MODEL_DIR", "./model_result").strip()
MODEL_FILE  = os.getenv("MODEL_FILE", "xgb_slim_features.joblib").strip()
INFO_FILE   = os.getenv("INFO_FILE",  "xgb_slim_features_info.json").strip()
ALLOWED_ORIGINS = [o.strip() for o in os.getenv("ALLOWED_ORIGINS", "*").split(",")]
DEV_ALLOW_INSECURE = os.getenv("DEV_ALLOW_INSECURE", "0") == "1"
```

**환경 변수 (.env)**:
```env
API_KEY=your-secure-api-key-here
MODEL_DIR=./model_result
MODEL_FILE=xgb_slim_features.joblib
INFO_FILE=xgb_slim_features_info.json
ALLOWED_ORIGINS=*
DEV_ALLOW_INSECURE=1
DEV_HOST=127.0.0.1
DEV_PORT=9000
```

### 5.2 Flask 앱 초기화

```python
app = Flask(__name__)

# CORS
cors_resources = {r"/*": {"origins": ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else "*"}}
CORS(app, resources=cors_resources, supports_credentials=True)

# Rate Limit
limiter = Limiter(get_remote_address, app=app, default_limits=["100/minute"])
```

### 5.3 모델 로딩

```python
MODEL = None     # joblib.load() 한 scikit-learn Pipeline (fe + scaler + rf)
META  = None     # json 메타 (threshold, schema 등)

def load_artifacts():
    """모델/메타 로딩"""
    global MODEL, META
    MODEL = joblib.load(MODEL_PATH)
    with open(INFO_PATH, "r", encoding="utf-8") as f:
        META = json.load(f)
    log.info("Artifacts loaded: model=%s, info=%s", MODEL_PATH, INFO_PATH)

# 서버 시작 시 자동 로딩
try:
    load_artifacts()
except Exception as e:
    log.warning("Failed to load artifacts at import time: %s", e)
```

**로딩되는 모델**:
```python
# MODEL: Pipeline([
#     ("fe", FeatureEngineer),         # 파생 변수 생성
#     ("scaler", StandardScaler),      # 정규화
#     ("rf", RandomForestClassifier)   # XGBoost RandomForest
# ])
```

### 5.4 인증 헬퍼

```python
def _extract_token(req) -> str | None:
    """Bearer 우선, 없으면 X-API-KEY도 허용"""
    auth = req.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth.split(" ", 1)[1].strip()
    x_api = req.headers.get("X-API-KEY", "").strip()
    return x_api or None

def _require_token(req) -> bool:
    """HTTPS 강제(+개발 예외) + 상수시간 비교"""
    # HTTPS 체크
    if not DEV_ALLOW_INSECURE and not _is_request_secure(req):
        log.info("AUTH FAIL: insecure request")
        return False

    token = _extract_token(req)
    if not token:
        log.info("AUTH FAIL: missing/invalid Authorization header")
        return False

    ok = bool(API_KEY) and hmac.compare_digest(token, API_KEY)
    if not ok:
        log.info("AUTH FAIL: token mismatch or empty API_KEY")
    return ok
```

### 5.5 엔드포인트 구현

#### GET /health - 헬스 체크 (인증 불필요)

```python
@app.get("/health")
def health():
    ok = MODEL is not None and META is not None
    payload = {
        "status": "ok" if ok else "uninitialized",
        "started_at": STARTED_AT,
        "https_required": not DEV_ALLOW_INSECURE,
        "allowed_origins": ALLOWED_ORIGINS,
        "model_path": MODEL_PATH,
        "info_path": INFO_PATH,
    }
    if ok:
        schema = META.get("schema", {})
        base_feats = schema.get("base_features", [])
        selected_feats = schema.get("selected_features", [])
        payload.update({
            "algorithm": META.get("algorithm"),
            "threshold": META.get("threshold"),
            "base_features_count": len(base_feats),
            "selected_features_count": len(selected_feats),
        })
    return (payload, 200 if ok else 503)
```

#### GET /schema - 모델 스키마 조회 (인증 필요)

```python
@app.get("/schema")
@limiter.limit("60/minute")
def schema():
    if not _require_token(request):
        return {"detail": "Forbidden"}, 403
    if META is None:
        return {"detail": "Model metadata not loaded"}, 503

    schema = META.get("schema", {})
    return jsonify({
        "algorithm": META.get("algorithm"),
        "threshold": META.get("threshold"),
        "schema": schema,  # {base_features, derived_features, selected_features}
    })
```

#### POST /predict - ML 예측 (인증 필요)

```python
@app.post("/predict")
@limiter.limit("30/minute")
def predict():
    if not _require_token(request):
        return {"detail": "Forbidden"}, 403
    if MODEL is None or META is None:
        return {"detail": "Model not loaded"}, 503

    try:
        payload = request.get_json(force=True, silent=False) or {}
    except Exception:
        return {"detail": "invalid JSON"}, 400

    rows = payload.get("data", [])
    if not isinstance(rows, list) or not rows:
        return {"detail": "data list required"}, 400

    # 새 메타 구조 기준: base_features만 클라이언트가 보내면 됨
    schema = META.get("schema", {})
    base_features = schema.get("base_features", [])
    if not base_features:
        return {"detail": "base_features not found in metadata.schema"}, 500

    # DataFrame 변환 (추가 컬럼이 있어도 base_features만 사용)
    df_in = pd.DataFrame(rows)

    # 누락된 base_features는 NaN으로 채움
    for col in base_features:
        if col not in df_in.columns:
            df_in[col] = np.nan

    # 순서 맞추기
    X_df = df_in[base_features]

    # threshold: 메타에 저장된 값 사용 (없으면 0.5 fallback)
    thr = META.get("threshold", 0.5)

    # MODEL: Pipeline([("fe", FeatureEngineer), ("scaler", StandardScaler), ("rf", RandomForest)])
    # → 여기서 FeatureEngineer가 파생변수(LDH_ratio 등)를 자동 생성
    try:
        proba = MODEL.predict_proba(X_df)[:, 1]
        pred  = (proba >= thr).astype(int)
    except Exception as e:
        log.exception("Prediction failed: %s", e)
        return {"detail": f"prediction failed: {e.__class__.__name__}"}, 500

    return jsonify({
        "base_features": base_features,
        "threshold": float(thr),
        "pred_proba": [float(x) for x in proba],
        "pred_label": [int(x) for x in pred],
    })
```

**핵심 로직**:
1. **입력**: 11개 base_features만 받음
2. **파생 변수 생성**: Pipeline의 FeatureEngineer가 자동 처리
3. **예측**: 모델이 선택한 8개 selected_features로 예측
4. **Threshold**: 메타데이터의 threshold (0.29) 적용

#### POST /reload - 모델 재로딩 (인증 필요)

```python
@app.post("/reload")
@limiter.limit("10/minute")
def reload_model():
    if not _require_token(request):
        return {"detail": "Forbidden"}, 403
    try:
        load_artifacts()
        return {"detail": "reloaded"}, 200
    except Exception as e:
        log.exception("Reload failed: %s", e)
        return {"detail": f"reload failed: {e.__class__.__name__}"}, 500
```

---

## 6. ML 파이프라인 구조

### 6.1 FeatureEngineer (feature_engineer.py)

```python
class FeatureEngineer(BaseEstimator, TransformerMixin):
    """
    - 입력: base_features (원본 변수만)
    - 내부에서 파생변수 생성:
        * LDH_ratio  = pleural_lactic_dehydrogenise / blood_lactic_dehydrogenise_(LDH)
        * protein_ratio = pleural_protein / total_protein
        * exposure_age_ratio = duration_of_asbestos_exposure / age
    - selected_features에 지정된 (기본+파생) 피처만 최종 출력
    """
    def __init__(self, base_features: List[str], selected_features: List[str]):
        self.base_features = base_features
        self.selected_features = selected_features

    def transform(self, X):
        X = self._to_df(X)
        X_fe = self._add_derived(X)
        X_out = X_fe[self.output_features_].copy()
        return X_out.values  # StandardScaler가 numpy 기대

    def _add_derived(self, df: pd.DataFrame) -> pd.DataFrame:
        df = df.copy()

        # LDH_ratio
        if {"pleural_lactic_dehydrogenise", "blood_lactic_dehydrogenise_(LDH)"}.issubset(df.columns):
            df["LDH_ratio"] = (
                df["pleural_lactic_dehydrogenise"] /
                (df["blood_lactic_dehydrogenise_(LDH)"] + 1e-6)
            )

        # protein_ratio
        if {"pleural_protein", "total_protein"}.issubset(df.columns):
            df["protein_ratio"] = (
                df["pleural_protein"] /
                (df["total_protein"] + 1e-6)
            )

        # exposure_age_ratio
        if {"duration_of_asbestos_exposure", "age"}.issubset(df.columns):
            df["exposure_age_ratio"] = (
                df["duration_of_asbestos_exposure"] /
                (df["age"] + 1e-6)
            )

        return df
```

### 6.2 모델 메타데이터 (xgb_slim_features_info.json)

```json
{
  "algorithm": "RandomForest",
  "threshold": 0.29,
  "schema": {
    "base_features": [
      "age",
      "duration_of_symptoms",
      "platelet_count_(PLT)",
      "cell_count_(WBC)",
      "blood_lactic_dehydrogenise_(LDH)",
      "pleural_lactic_dehydrogenise",
      "pleural_protein",
      "total_protein",
      "albumin",
      "C-reactive_protein_(CRP)",
      "duration_of_asbestos_exposure"
    ],
    "derived_features": [
      "LDH_ratio",
      "protein_ratio",
      "exposure_age_ratio"
    ],
    "selected_features": [
      "exposure_age_ratio",
      "age",
      "platelet_count_(PLT)",
      "duration_of_symptoms",
      "LDH_ratio",
      "pleural_protein",
      "albumin",
      "C-reactive_protein_(CRP)"
    ]
  }
}
```

### 6.3 ML 파이프라인 흐름

```
[클라이언트] 11개 base_features 입력
      ↓
[Flask /predict]
      ↓
[FeatureEngineer] 3개 derived_features 생성
  - LDH_ratio
  - protein_ratio
  - exposure_age_ratio
      ↓
[FeatureEngineer] 8개 selected_features 선택
  - exposure_age_ratio
  - age
  - platelet_count_(PLT)
  - duration_of_symptoms
  - LDH_ratio
  - pleural_protein
  - albumin
  - C-reactive_protein_(CRP)
      ↓
[StandardScaler] 정규화
      ↓
[RandomForestClassifier] 예측
      ↓
[Threshold 0.29 적용]
      ↓
[결과 반환] pred_proba, pred_label
```

---

## 7. 인증 흐름

### 7.1 Flutter → Django (JWT)

```
[Flutter Client]
  Headers:
    Authorization: Bearer <JWT_ACCESS_TOKEN>
      ↓
[Django Middleware]
  JWTAuthentication.authenticate()
      ↓
[Django View]
  request.user (인증된 사용자)
```

### 7.2 Django → Flask (API Key)

```
[Django mlproxy.views]
  headers = {"Authorization": f"Bearer {settings.ML_API_KEY}"}
  requests.post(f"{ML_BASE_URL}/predict", headers=headers, json=data)
      ↓
[Flask app.py]
  _require_token(request)
    - Authorization: Bearer <API_KEY> 검증
    - hmac.compare_digest(token, API_KEY)
      ↓
[Flask /predict]
  모델 예측 수행
```

---

## 8. 보안 고려사항

### 8.1 Django 보안

1. **JWT 인증**: 모든 API 요청은 JWT 토큰 필요
2. **권한 검증**:
   - `IsAuthenticated`: 로그인 필수
   - `IsAdmin`: 관리자 전용 (모델 리로딩)
3. **CORS 설정**:
   - 개발: `CORS_ALLOW_ALL_ORIGINS = True`
   - 운영: 특정 도메인만 허용
4. **HTTPS 강제**: 운영 환경에서 HTTPS 필수

### 8.2 Flask 보안

1. **API Key 인증**:
   - Django만 Flask에 접근 가능
   - `Authorization: Bearer <API_KEY>` 헤더 필요
   - 상수 시간 비교 (`hmac.compare_digest`)
2. **Rate Limiting**:
   - `/schema`: 60 req/min
   - `/predict`: 30 req/min
   - `/reload`: 10 req/min
3. **HTTPS 강제**:
   - 운영: `DEV_ALLOW_INSECURE=0` (HTTPS 필수)
   - 개발: `DEV_ALLOW_INSECURE=1` (HTTP 허용)
4. **내부 네트워크**: Flask는 127.0.0.1:9000에서만 리스닝 (외부 접근 차단)

### 8.3 네트워크 보안

```
[인터넷]
    ↓ (HTTPS :443 또는 HTTP :80)
[Nginx - GCP Public IP]
    ↓ (내부 HTTP :8000)
[Django - 127.0.0.1:8000]
    ↓ (내부 HTTP :9000)
[Flask - 127.0.0.1:9000]
```

- Flask는 외부 직접 접근 불가 (Django를 통해서만 접근)
- Nginx가 TLS 종료 (HTTPS → HTTP)

---

## 9. 배포 환경 (GCP)

### 9.1 서버 구성

```bash
# Nginx (포트 80)
sudo systemctl status nginx

# Django (포트 8000)
gunicorn config.wsgi:application --bind 127.0.0.1:8000 --workers 4

# Flask (포트 9000)
gunicorn app:app --bind 127.0.0.1:9000 --workers 2
```

### 9.2 Nginx 설정 예시

```nginx
server {
    listen 80;
    server_name 34.61.113.204;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 10. 트러블슈팅

### 10.1 Django → Flask 연결 실패

**증상**: `{"detail": "Connection refused"}`

**해결**:
1. Flask 서버 실행 확인: `curl http://127.0.0.1:9000/health`
2. 환경 변수 확인: `ML_BASE_URL`, `ML_API_KEY`
3. 방화벽 확인 (로컬 포트 9000)

### 10.2 Flask 인증 실패

**증상**: `{"detail": "Forbidden"}`

**해결**:
1. API_KEY 일치 확인 (Django `.env`와 Flask `.env` 동일한지)
2. Authorization 헤더 형식 확인: `Bearer <API_KEY>`
3. HTTPS 요구사항 확인: 개발 시 `DEV_ALLOW_INSECURE=1`

### 10.3 모델 로딩 실패

**증상**: `{"detail": "Model not loaded"}`

**해결**:
1. 모델 파일 존재 확인:
   ```bash
   ls flask_ml/model_result/xgb_slim_features.joblib
   ls flask_ml/model_result/xgb_slim_features_info.json
   ```
2. Flask 로그 확인: `Failed to load artifacts`
3. 모델 재로딩: `POST /api/ml/reload/` (관리자 권한)

### 10.4 예측 실패

**증상**: `{"detail": "prediction failed: KeyError"}`

**해결**:
1. 입력 데이터 형식 확인 (11개 base_features 모두 포함)
2. 필드명 정확도 확인 (예: `platelet_count_(PLT)`)
3. 데이터 타입 확인 (int/float)

---

## 11. Flutter 연동 예시

### 11.1 ML Service (ml_service.dart)

```dart
class MlService {
  final ApiConfig _config = ApiConfig();

  Future<MlPredictResult> predictSingle({
    required int patientId,
    required int age,
    required int durationOfSymptoms,
    required double plateletCount,
    required double cellCount,
    required double bloodLacticDehydrogenise,
    required double pleuralLacticDehydrogenise,
    required double pleuralProtein,
    required double totalProtein,
    required double albumin,
    required double cReactiveProtein,
    required int durationOfAsbestosExposure,
    String? modelName,
  }) async {
    final data = {
      'age': age,
      'duration_of_symptoms': durationOfSymptoms,
      'platelet_count_(PLT)': plateletCount,
      'cell_count_(WBC)': cellCount,
      'blood_lactic_dehydrogenise_(LDH)': bloodLacticDehydrogenise,
      'pleural_lactic_dehydrogenise': pleuralLacticDehydrogenise,
      'pleural_protein': pleuralProtein,
      'total_protein': totalProtein,
      'albumin': albumin,
      'C-reactive_protein_(CRP)': cReactiveProtein,
      'duration_of_asbestos_exposure': durationOfAsbestosExposure,
    };

    return predict(
      patientId: patientId,
      data: [data],
      modelName: modelName,
    );
  }

  Future<MlPredictResult> predict({
    required int patientId,
    required List<Map<String, dynamic>> data,
    String? modelName,
  }) async {
    try {
      final token = await _config.getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mlPredictEndpoint}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patient_id': patientId,
          'model_name': modelName ?? 'meso_xgb_v1',
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        return MlPredictResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('ML 예측 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('ML 예측 오류: $e');
    }
  }
}
```

### 11.2 API 호출 흐름

```
[Flutter] predictSingle() 호출
    ↓
[Flutter] 11개 필드 → JSON 변환
    ↓
[Flutter] POST http://34.61.113.204/api/ml/predict/
          Headers: Authorization: Bearer <JWT_TOKEN>
    ↓
[Nginx] 80 → Django 8000
    ↓
[Django] JWT 인증 확인
    ↓
[Django] POST http://127.0.0.1:9000/predict
         Headers: Authorization: Bearer <API_KEY>
    ↓
[Flask] API Key 인증 확인
    ↓
[Flask] FeatureEngineer → 파생 변수 생성
    ↓
[Flask] ML 모델 예측
    ↓
[Flask] 결과 반환 → Django
    ↓
[Django] PredictionResult DB 저장 (자동)
    ↓
[Django] 결과 반환 → Flutter
    ↓
[Flutter] MlPredictResult 파싱 및 UI 표시
```

---

## 12. 요약

### 핵심 특징

1. **이중 인증 구조**:
   - Flutter → Django: JWT
   - Django → Flask: API Key

2. **프록시 패턴**:
   - Django가 Flask ML 서버를 프록시
   - 클라이언트는 Flask 존재를 모름

3. **자동 저장**:
   - Django가 ML 예측 결과를 자동으로 DB 저장
   - 별도 저장 API 호출 불필요

4. **ML 파이프라인**:
   - 클라이언트는 11개 base_features만 전송
   - Flask가 파생 변수 생성 및 예측 자동 처리

5. **보안**:
   - Flask는 내부 네트워크만 접근 가능
   - Rate Limiting 적용
   - HTTPS 강제 (운영 환경)

### 장점

- **관심사 분리**: Django(비즈니스 로직) vs Flask(ML 추론)
- **확장성**: Flask 서버를 여러 대로 확장 가능
- **유지보수성**: ML 모델 업데이트 시 Django 코드 변경 불필요
- **보안**: 이중 인증, 내부 네트워크 격리
- **성능**: 경량 Flask 서버로 빠른 ML 추론

### 단점

- **복잡성**: 두 개의 서버 관리
- **네트워크 오버헤드**: Django → Flask 내부 HTTP 요청
- **장애 지점 증가**: Django 또는 Flask 중 하나라도 다운 시 서비스 불가
