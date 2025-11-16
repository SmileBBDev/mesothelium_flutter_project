# 🔒 환경 변수 관리 가이드

## 문제 인식

**질문**: `env_config.dart`는 Git에 노출되는데, 정말 안전한가요?

**답변**: **맞습니다!** `env_config.dart` 파일 자체는 Git에 커밋됩니다. 하지만 **실제 민감한 값은 `defaultValue`에서 제거**했기 때문에 안전합니다.

---

## ✅ 현재 보안 구조

### 1️⃣ Git에 커밋되는 파일 (안전)

```dart
// lib/config/env_config.dart
class EnvConfig {
  static const String vWorldApiKey = String.fromEnvironment(
    'VWORLD_API_KEY',
    defaultValue: '',  // ✅ 빈 값 - 민감한 정보 없음!
  );
}
```

### 2️⃣ Git에 커밋되지 않는 파일 (민감 정보 포함)

```bash
# .env.local (gitignore로 차단됨)
VWORLD_API_KEY=실제_프로덕션_API_키_여기에
API_BASE_URL=https://production-api.example.com
```

---

## 🔐 안전한 사용 방법

### **방법 1: 빌드 시 직접 환경 변수 전달 (권장)**

```bash
# 개발 환경
flutter run --dart-define=VWORLD_API_KEY=개발용키값 \
            --dart-define=API_BASE_URL=http://localhost:8000

# 프로덕션 빌드
flutter build apk --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=VWORLD_API_KEY=프로덕션_실제키 \
  --dart-define=API_BASE_URL=https://api.production.com
```

**장점**:
- ✅ 키가 파일에 저장되지 않음
- ✅ CI/CD에서 Secret으로 관리 가능
- ✅ Git에 노출될 위험 0%

---

### **방법 2: CI/CD 파이프라인에서 Secret 사용**

#### GitHub Actions 예시

```yaml
# .github/workflows/build.yml
name: Build Production APK

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Build APK with secrets
        env:
          VWORLD_KEY: ${{ secrets.VWORLD_API_KEY }}  # GitHub Secrets에 저장
          PROD_API: ${{ secrets.PRODUCTION_API_URL }}
        run: |
          flutter build apk --release \
            --dart-define=VWORLD_API_KEY=$VWORLD_KEY \
            --dart-define=API_BASE_URL=$PROD_API \
            --dart-define=ENVIRONMENT=production
```

**GitHub Secrets 설정 방법**:
1. Repository → Settings → Secrets and variables → Actions
2. New repository secret 클릭
3. `VWORLD_API_KEY` 추가 (실제 키 입력)
4. `PRODUCTION_API_URL` 추가

---

### **방법 3: 로컬 개발 시 스크립트 사용**

```bash
# scripts/run_dev.sh
#!/bin/bash
source .env.local  # .gitignore로 차단됨

flutter run \
  --dart-define=VWORLD_API_KEY=$VWORLD_API_KEY \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=ENVIRONMENT=development
```

```bash
# .env.local (Git에 커밋 안 됨!)
VWORLD_API_KEY=실제키값
API_BASE_URL=http://localhost:8000
```

---

## 📋 보안 체크리스트

### ✅ 안전하게 구성됨

- [x] `.env`, `.env.*` 파일이 `.gitignore`에 등록됨
- [x] `env_config.dart`의 `defaultValue`가 빈 문자열 또는 공개 가능한 값
- [x] 실제 키는 빌드 시 `--dart-define`으로 주입
- [x] CI/CD에서 Secret 관리

### ❌ 위험한 상태 (수정 전)

- [ ] ~~`defaultValue`에 실제 프로덕션 키 하드코딩~~ → **수정 완료**
- [ ] ~~`.env` 파일이 Git에 커밋됨~~ → **`.gitignore`로 차단됨**

---

## 🧪 테스트 방법

### 1. API 키 없이 빌드 시 (개발 환경)

```bash
flutter run
```

**결과**: 지도가 로드되지 않거나 오류 발생 (예상된 동작)

### 2. API 키 포함 빌드 시

```bash
flutter run --dart-define=VWORLD_API_KEY=실제키값
```

**결과**: 지도 정상 로드 ✅

### 3. 키 설정 여부 확인 (앱 내부)

```dart
// 앱 시작 시 체크
if (!EnvConfig.isVWorldKeyConfigured) {
  print('⚠️ VWORLD_API_KEY가 설정되지 않았습니다!');
  print('빌드 시 --dart-define=VWORLD_API_KEY=키값 을 추가하세요');
}
```

---

## 🎯 결론

### Q: `env_config.dart`가 Git에 노출되는 게 문제 아닌가요?

**A**: 아닙니다! 다음 이유로 안전합니다:

1. **`env_config.dart`는 "설정 코드"일 뿐**
   → 실제 민감한 값은 포함되지 않음 (`defaultValue: ''`)

2. **실제 키는 빌드 시 주입됨**
   → `--dart-define` 플래그로 런타임에 전달

3. **CI/CD Secret으로 관리**
   → GitHub Actions, GitLab CI 등에서 암호화된 Secret 사용

4. **`.env` 파일은 gitignore 처리**
   → 로컬 개발용 키는 Git에 절대 커밋 안 됨

---

## 📚 추가 보안 권장사항

### 1. Android 키스토어 관리

```bash
# android/key.properties (gitignore 처리됨!)
storePassword=실제비밀번호
keyPassword=실제비밀번호
keyAlias=release-key
storeFile=/path/to/keystore.jks
```

### 2. iOS 프로비저닝 프로파일

- Xcode에서 자동 서명 사용 권장
- 수동 서명 시 `.mobileprovision` 파일은 Git에 커밋 금지

### 3. API 키 로테이션

- 정기적으로 API 키 갱신 (3~6개월마다)
- 구 키 폐기 전 새 키로 빌드 및 배포 완료 확인

---

## 🆘 문제 해결

### "지도가 로드되지 않아요"

```bash
# 키가 제대로 주입되었는지 확인
flutter run --dart-define=VWORLD_API_KEY=키값 --verbose
```

### "CI/CD에서 빌드 실패"

1. GitHub Secrets에 `VWORLD_API_KEY` 등록 확인
2. Workflow 파일에서 `${{ secrets.VWORLD_API_KEY }}` 사용 확인
3. 빌드 로그에서 환경 변수 주입 여부 확인

---

**작성일**: 2025-11-16
**버전**: 1.0
**관련 파일**:
- [lib/config/env_config.dart](lib/config/env_config.dart)
- [.env.example](.env.example)
- [.gitignore](.gitignore)
