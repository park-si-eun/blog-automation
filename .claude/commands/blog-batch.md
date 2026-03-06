# /blog-batch — 키워드 목록 기반 블로그 글 일괄 생성

description: 키워드 목록 파일 기반 블로그 글 일괄 생성

## 사용법
```
/blog-batch <brand-slug> | <키워드파일경로>
```
예시: `/blog-batch sos-coffee-brunch | input/keywords/sos-coffee-brunch-store.txt`

---

## 실행 절차

### 0. ARGUMENTS 파싱
`$ARGUMENTS`를 파이프(`|`) 기준으로 분리한다.
- 파이프 앞: `BRAND_SLUG`
- 파이프 뒤: `KEYWORD_FILE` (키워드 목록 파일 경로)

두 값 중 하나라도 비어 있으면 아래 안내 후 중단:
```
사용법: /blog-batch <brand-slug> | <키워드파일경로>
예시:   /blog-batch sos-coffee-brunch | input/keywords/sos-coffee-brunch-store.txt

키워드 파일 형식:
  - 한 줄에 키워드 1개
  - # 으로 시작하는 줄은 주석 (무시)
  - 빈 줄 무시
```

---

### 1. 브랜드 프로필 로딩
다음 경로에서 브랜드 파일을 탐색한다 (순서대로):
1. `input/brands/BRAND_SLUG.md`
2. `input/brands/BRAND_SLUG/profile.md`
3. `input/brands/` 하위에서 파일명에 `BRAND_SLUG`가 포함된 `.md` 파일

**매칭 실패 시** 아래 메시지를 출력하고 중단:
```
브랜드 파일을 찾을 수 없습니다: BRAND_SLUG
input/brands/_template.md 를 복사해 브랜드 프로필을 먼저 작성해 주세요.
```

---

### 2. 키워드 파일 읽기
`KEYWORD_FILE`을 읽어 키워드 목록을 추출한다.

파싱 규칙:
- `#`으로 시작하는 줄 → 주석, 무시
- 빈 줄 → 무시
- 나머지 줄 → 앞뒤 공백 제거 후 키워드 목록에 추가

파일이 없을 경우:
```
파일을 찾을 수 없습니다: KEYWORD_FILE
경로를 확인해 주세요.
```

유효 키워드가 0개일 경우:
```
키워드 파일에 유효한 키워드가 없습니다: KEYWORD_FILE
```

파일 읽기 성공 시 배치 시작 전 요약 안내:
```
=== 배치 작업 시작 ===
브랜드: BRAND_SLUG
총 키워드: N개
키워드 목록:
  1. 키워드1
  2. 키워드2
  ...
```

---

### 3. 키워드별 블로그 글 생성

각 키워드에 대해 `/blog` 파이프라인을 순서대로 실행한다.

**글 유형 자동 판별**: 브랜드 프로필의 유형별 키워드 목록과 대조
- 판별 불가 시 해당 키워드에 대해 사용자에게 확인 후 진행

**진행 상황 표시** (각 키워드 시작 시):
```
[N/전체] "키워드" 작성 중...
```

**각 글 완료 시**:
```
[N/전체] ✅ "키워드" 완료
  - 파일: output/BRAND_SLUG/blog/YYYYMMDD_슬러그.md
  - 글자수: N자
  - 자가체크: N/5 통과
  - 점수: N점 (자가체크 기준)
```

**3건마다 /compact 실행**:
```
[진행률 N/전체] 컨텍스트 정리 중... (/compact)
```
→ /compact 실행 후 브랜드 프로필을 다시 로딩하고 다음 키워드부터 이어서 진행

**오류 발생 시** 해당 키워드를 실패 목록에 기록하고 다음 키워드로 계속 진행:
```
[N/전체] ❌ "키워드" 실패: 오류 내용
```

---

### 4. 완료 보고

모든 키워드 처리 완료 후 최종 보고서를 출력한다.

```
=== 배치 작업 완료 보고 ===
브랜드: BRAND_SLUG
처리 일시: YYYY-MM-DD

[요약]
총 키워드:  N개
성공:       N개
실패:       N개
평균 점수:  N점

[생성된 파일 목록]
 N점  output/BRAND_SLUG/blog/YYYYMMDD_슬러그1.md  "키워드1"
 N점  output/BRAND_SLUG/blog/YYYYMMDD_슬러그2.md  "키워드2"
...

[⚠️ 80점 미만 목록]
 N점  "키워드"  → output/BRAND_SLUG/blog/YYYYMMDD_슬러그.md
  주요 감점 사유: ...
(80점 미만 없을 경우 "없음"으로 표시)

[❌ 실패 목록]
 "키워드"  오류 사유: ...
(실패 없을 경우 "없음"으로 표시)
```

80점 미만 글이 있을 경우 추가 안내:
```
💡 80점 미만 글은 다음 명령으로 재감사할 수 있습니다:
/blog-audit BRAND_SLUG | <파일경로>
```
