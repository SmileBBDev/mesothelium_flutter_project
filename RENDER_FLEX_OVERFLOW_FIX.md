# RenderFlex Overflow 에러 해결 방법

## 문제 설명
```
RenderFlex overflowed by XX pixels on the bottom.
```

이 에러는 Column 위젯이 화면 높이를 초과할 때 발생합니다.

## 해결 방법

### 1. SingleChildScrollView 사용 (가장 일반적)

**수정 전:**
```dart
Scaffold(
  body: Column(
    children: [
      Widget1(),
      Widget2(),
      Widget3(),
      // ... 많은 위젯들
    ],
  ),
)
```

**수정 후:**
```dart
Scaffold(
  body: SingleChildScrollView(
    child: Column(
      children: [
        Widget1(),
        Widget2(),
        Widget3(),
        // ... 많은 위젯들
      ],
    ),
  ),
)
```

### 2. Expanded/Flexible 사용

**수정 전:**
```dart
Column(
  children: [
    HeaderWidget(),
    ContentWidget(),  // 너무 커서 overflow
    FooterWidget(),
  ],
)
```

**수정 후:**
```dart
Column(
  children: [
    HeaderWidget(),
    Expanded(
      child: SingleChildScrollView(
        child: ContentWidget(),
      ),
    ),
    FooterWidget(),
  ],
)
```

### 3. ListView 사용

**수정 전:**
```dart
Column(
  children: [
    for (var item in items)
      ItemWidget(item),
  ],
)
```

**수정 후:**
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(items[index]);
  },
)
```

## 현재 프로젝트에서 확인할 파일들

에러가 발생할 가능성이 있는 페이지들:

1. **ml_prediction_page.dart** (의사용 ML 예측 페이지)
   - 11개 입력 필드 + 버튼 → 화면 높이 초과 가능

2. **patient_management_list.dart** (환자 관리 목록)
   - 검색 필터 + 리스트 → 화면 높이 초과 가능

3. **medical_document_editor.dart** (진료 문서 작성)
   - 제목 + 에디터 + 버튼 → 화면 높이 초과 가능

## 수정 예시: ml_prediction_page.dart

```dart
// lib/features/doctor/ml_prediction_page.dart

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(...),
    body: SingleChildScrollView(  // ← 추가
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 환자 선택 섹션
          _buildPatientSelector(),

          const SizedBox(height: 24),

          // 입력 필드들
          _buildInputFields(),

          const SizedBox(height: 24),

          // 예측 버튼
          _buildPredictButton(),
        ],
      ),
    ),
  );
}
```

## 디버깅 방법

1. **에러 메시지에서 위젯 트리 확인**
   ```
   creator: Column ← Padding ← MediaQuery ← ...
   ```
   이 트리를 따라가서 어느 페이지인지 파악

2. **Flutter DevTools 사용**
   - Chrome에서 개발자 도구 열기
   - "Flutter Inspector" 탭에서 레이아웃 확인

3. **임시로 모든 Column을 SingleChildScrollView로 감싸기**
   ```dart
   // 임시 테스트용
   body: SingleChildScrollView(
     child: body원래내용,
   ),
   ```

## 주의사항

- **ListView 안에 Column 넣기**: ListView는 이미 스크롤 가능하므로 Column 불필요
- **Expanded in SingleChildScrollView**: SingleChildScrollView 내부에서 Expanded 사용 불가
- **중첩 스크롤**: 스크롤 위젯 안에 또 다른 스크롤 위젯 넣으면 충돌 발생 가능

## 완료 후 확인

```bash
flutter run
```

에러가 사라지고 스크롤이 정상 작동하는지 확인
