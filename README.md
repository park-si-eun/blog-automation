# blog-automation

> **이 프로젝트는 브랜드 교체형 블로그 자동화 템플릿입니다.**
> 브랜드 프로필 파일 하나만 작성하면 네이버 블로그 SEO 최적화 글 생성·기획·감사·일괄작성을 Claude Code 슬래시 커맨드로 즉시 실행할 수 있습니다.

---

## 빠른 시작

### 1. 설치

```bash
git clone https://github.com/park-si-eun/blog-automation.git
cd blog-automation
```

### 2. 환경 변수 설정 (네이버 API 연동 시)

```bash
cp .env.example .env
# .env 파일을 열어 API 키 입력 (아래 "네이버 API 연동" 섹션 참고)
```

### 3. 브랜드 프로필 준비

기본 제공 브랜드(`sos-coffee-brunch`)를 그대로 사용하거나,
새 브랜드를 추가하려면 아래 "새 브랜드 추가 방법" 섹션을 참고하세요.

### 4. Claude Code에서 바로 실행

```
/blog sos-coffee-brunch | 석촌역맛집
```

---

## 사용 예시

```
# 매장 방문 유도 글 단건 생성
/blog sos-coffee-brunch | 석촌역맛집

# 단체주문 유도 글 단건 생성
/blog sos-coffee-brunch | 샌드위치단체주문

# 블로그 콘텐츠 기획안 생성
/blog-plan sos-coffee-brunch | 잠실브런치카페

# 기존 글 품질 감사
/blog-audit sos-coffee-brunch | output/sos-coffee-brunch/blog/20260306_석촌역맛집.md

# 매장 방문 유도 키워드 전체 일괄 생성
/blog-batch sos-coffee-brunch | input/keywords/sos-coffee-brunch-store.txt

# 단체주문 유도 키워드 전체 일괄 생성
/blog-batch sos-coffee-brunch | input/keywords/sos-coffee-brunch-catering.txt
```

---

## 글 유형 자동 판별

입력 키워드를 브랜드 프로필의 **유형별 키워드 목록**과 대조해 자동으로 글 유형을 분류합니다.

| 유형 | 설명 | 키워드 예시 |
|------|------|------------|
| `store` | 매장 방문 유도 | 석촌역맛집, 테라스있는카페, 잠실브런치카페 |
| `catering` | 단체주문·케이터링 유도 | 샌드위치단체주문, 웨딩촬영간식, 세미나간식추천 |

판별이 불가능한 경우 Claude가 유형 선택을 직접 물어봅니다.
새 유형은 브랜드 프로필의 `유형별 키워드 목록` 섹션에 추가하면 됩니다.

---

## 커맨드 목록

| 커맨드 | 설명 | 사용법 |
|--------|------|--------|
| `/blog` | SEO 최적화 블로그 글 생성 | `/blog <brand-slug> \| <키워드>` |
| `/blog-plan` | 블로그 콘텐츠 기획안 생성 | `/blog-plan <brand-slug> \| <키워드>` |
| `/blog-audit` | 기존 글 품질 감사 (100점) | `/blog-audit <brand-slug> \| <파일경로>` |
| `/blog-batch` | 키워드 파일 기반 일괄 생성 | `/blog-batch <brand-slug> \| <키워드파일>` |

> 모든 커맨드의 `$ARGUMENTS`는 파이프(`|`) 기준으로 파싱됩니다.
> 브랜드 파일 매칭 실패 시 `brands/_template.md` 안내 후 중단됩니다.

---

## 새 브랜드 추가 방법

```bash
# Step 1: 템플릿 복사
cp brands/_template.md brands/[my-brand].md

# Step 2: 브랜드 정보 채우기
# 브랜드명, 위치, 메뉴, 톤앤매너, 금지표현, 유형별 키워드 목록 등 입력

# Step 3: 바로 사용
# /blog [my-brand] | 키워드
```

**파일명 규칙**
- 영문 소문자 + 하이픈(`-`) 조합만 사용
- 한글 금지
- `지역-업종` 조합 권장
- 예: `hongdae-pizza`, `gangnam-salon`, `itaewon-burger`

---

## 에이전트 팀 구성 (7명 릴레이)

`/blog` 커맨드 실행 시 아래 7개 역할이 순서대로 처리를 이어받습니다.

| 순서 | 역할 | 담당 작업 |
|------|------|-----------|
| 1 | **Researcher** | 키워드 검색 의도 분석, 롱테일 키워드 도출 |
| 2 | **Strategist** | 제목 3안 설계, 글 구조 기획 |
| 3 | **Writer** | 브랜드 톤앤매너 기반 초안 작성 |
| 4 | **SEO Optimizer** | 키워드 배치 최적화, 메타 설명·해시태그 생성 |
| 5 | **Brand Editor** | 금지 표현 제거, 브랜드 보이스 정합성 검토 |
| 6 | **CTA Specialist** | CTA 삽입 위치 및 문구 최적화 |
| 7 | **QA Checker** | 자가 체크리스트 실행, 미달 항목 수정 후 최종 확정 |

---

## 프로젝트 구조

```
blog-automation/
├── .claude/
│   └── commands/
│       ├── blog.md            # /blog 커맨드
│       ├── blog-plan.md       # /blog-plan 커맨드
│       ├── blog-audit.md      # /blog-audit 커맨드
│       └── blog-batch.md      # /blog-batch 커맨드
│
├── brands/
│   ├── _template.md           # 브랜드 프로필 템플릿
│   └── sos-coffee-brunch.md   # 예시 브랜드 프로필
│
├── input/
│   └── keywords/
│       ├── sos-coffee-brunch-store.txt      # 매장 방문 유도 키워드
│       └── sos-coffee-brunch-catering.txt   # 단체주문 유도 키워드
│
├── output/
│   └── [brand-slug]/
│       ├── blog/              # 생성된 블로그 글
│       │   └── YYYYMMDD_키워드슬러그.md
│       ├── plans/             # 콘텐츠 기획안
│       │   └── YYYYMMDD_키워드슬러그_plan.md
│       └── audits/            # 품질 감사 결과
│           └── YYYYMMDD_키워드슬러그_audit.md
│
├── .env                       # API 키 (gitignore 처리)
├── .env.example               # 환경 변수 예시
└── README.md
```

---

## 네이버 API 연동

네이버 검색 API를 연동하면 키워드 실제 검색량·트렌드 데이터를 활용할 수 있습니다.

### 1. API 키 발급

1. [네이버 개발자 센터](https://developers.naver.com) 접속
2. **Application 등록** → 검색 API 선택
3. `Client ID`와 `Client Secret` 발급

### 2. .env 파일 설정

```env
NAVER_CLIENT_ID=your_client_id_here
NAVER_CLIENT_SECRET=your_client_secret_here
```

### 3. .env.example

```env
NAVER_CLIENT_ID=
NAVER_CLIENT_SECRET=
```

---

## 주의사항

- **`.env` 파일은 반드시 `.gitignore`에 포함되어야 합니다.**
  API 키가 GitHub에 노출되면 즉시 재발급하세요.
- `brands/` 폴더의 프로필에 **실제 존재하지 않는 정보를 작성하지 마세요.**
  커맨드들은 브랜드 프로필에 없는 정보를 지어내지 않도록 설계되어 있습니다.
- `output/` 폴더는 `.gitignore`에 추가를 권장합니다 (대용량 글 파일 누적 방지).
