#!/bin/bash
# 요일별 자동 블로그 글 생성 스크립트
# GitHub Actions 또는 로컬 cron에서 실행

BRAND="sos-coffee-brunch"

# 오늘 요일 판별 (1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일)
DAY=$(date '+%u' -d '+9 hours' 2>/dev/null || date -u -v+9H '+%u')

case $DAY in
  1) TARGET="월요일" ;;
  2) TARGET="화요일" ;;
  3) TARGET="수요일" ;;
  4) TARGET="목요일" ;;
  5) TARGET="금요일" ;;
  6) TARGET="토요일" ;;
  7) TARGET="일요일" ;;
esac

echo "====================================="
echo "오늘 요일: $TARGET"
echo "브랜드: $BRAND"
echo "====================================="

# blog.md 커맨드 내용을 읽어 $ARGUMENTS 치환
ARGUMENTS="$BRAND | $TARGET"
TEMPLATE=$(cat .claude/commands/blog.md)
PROMPT="${TEMPLATE//\$ARGUMENTS/$ARGUMENTS}"

# 출력 디렉토리 및 파일 경로 준비
TODAY=$(date '+%Y%m%d' -d '+9 hours' 2>/dev/null || date -u -v+9H '+%Y%m%d')
OUTDIR="output/$BRAND/blog"
OUTFILE="$OUTDIR/${TODAY}_${TARGET}.md"
mkdir -p "$OUTDIR"

echo "블로그 글 생성 시작..."
echo "저장 예정 경로: $OUTFILE"

# Claude CLI로 실행 (Sonnet 4.6 고정 — 품질 보장)
claude -p "$PROMPT" \
  --model claude-sonnet-4-6 \
  --allowedTools "Read,Write,Glob,Bash,Grep" \
  --output-format text \
  --dangerously-skip-permissions \
  | tee /tmp/claude_output.txt

CLAUDE_EXIT=${PIPESTATUS[0]}
echo "Claude 종료 코드: $CLAUDE_EXIT"
if [ "$CLAUDE_EXIT" -ne 0 ]; then
  echo "⚠️ Claude 비정상 종료 (코드: $CLAUDE_EXIT) — 출력 파일 확인 시도..."
fi

# Claude가 Write 도구로 어떤 .md 파일을 만들었는지 확인
WRITTEN_FILE=$(find "$OUTDIR" -name "*.md" -newer /tmp/claude_output.txt 2>/dev/null | head -1)
if [ -z "$WRITTEN_FILE" ]; then
  # newer 비교 실패 시 fallback: 가장 최근 파일
  WRITTEN_FILE=$(find "$OUTDIR" -name "*.md" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | awk '{print $2}')
fi

if [ -n "$WRITTEN_FILE" ] && [ -s "$WRITTEN_FILE" ]; then
  echo "✅ Claude Write 도구로 생성된 파일: $WRITTEN_FILE"
  wc -c "$WRITTEN_FILE"
  OUTFILE="$WRITTEN_FILE"
else
  # Write 도구 미사용 — stdout을 파일로 저장
  echo "⚠️ Write 도구 미사용 — stdout 출력물로 파일 저장"
  cp /tmp/claude_output.txt "$OUTFILE"
  if [ -s "$OUTFILE" ]; then
    echo "✅ stdout으로 파일 저장 완료: $OUTFILE"
    wc -c "$OUTFILE"
  else
    echo "❌ 파일이 비어 있음. Claude 출력 없음."
    exit 1
  fi
fi

# 다음 단계에서 파일 경로를 참조할 수 있도록 저장
echo "$OUTFILE" > /tmp/blog_file_path.txt
echo "저장된 파일 경로: $OUTFILE"

# 한글 파일명 문제 방지용 ASCII 이름 복사본 생성
cp "$OUTFILE" /tmp/blog_post.md
echo "복사본 생성: /tmp/blog_post.md ($(wc -c < /tmp/blog_post.md) bytes)"

# ─── 글자수 검증 ─────────────────────────────────────────
# 화(2)·목(4) = 단체주문글 2,200자 / 나머지 = 매장홍보글 2,000자
if [ "$DAY" -eq 2 ] || [ "$DAY" -eq 4 ]; then
  MIN_CHARS=2200
  POST_TYPE="단체주문글"
else
  MIN_CHARS=2000
  POST_TYPE="매장홍보글"
fi

CHAR_COUNT=$(python3 - <<'PYEOF'
with open('/tmp/blog_post.md', 'r', encoding='utf-8') as f:
    lines = f.readlines()
filtered = []
for line in lines:
    l = line.strip()
    if l.startswith('[이미지') or l.startswith('https://') or l.startswith('👉') or l.startswith('---') or l.startswith('#') or l == '':
        continue
    filtered.append(l)
text = ' '.join(filtered)
print(len(text.replace(' ', '')))
PYEOF
)

echo "글자수 검증: ${CHAR_COUNT}자 (기준: ${MIN_CHARS}자 이상, ${POST_TYPE})"

if [ -n "$CHAR_COUNT" ] && [ "$CHAR_COUNT" -lt "$MIN_CHARS" ]; then
  echo "⚠️ 글자수 미달: ${CHAR_COUNT}자 → 자동 재작성 시작"

  EXISTING=$(cat /tmp/blog_post.md)
  REWRITE_PROMPT="아래 블로그 글의 공백 제외 글자수가 ${CHAR_COUNT}자로 기준(${MIN_CHARS}자)에 미달합니다.

브랜드 프로필(input/brands/${BRAND}.md)을 읽고, 기존 글의 구조와 방향을 유지하면서 새로운 장면·맥락·이용 상황을 추가해 ${MIN_CHARS}자 이상으로 보강하세요.

규칙:
- 브랜드 프로필에 없는 정보 지어내지 않기
- 같은 표현·내용 반복 금지
- 기존 글의 소제목 구조 유지
- 보강 완료 후 공백 제외 글자수를 직접 측정해 ${MIN_CHARS}자 이상 확인
- 완성된 글을 ${OUTFILE} 에 저장

기존 글:
${EXISTING}"

  claude -p "$REWRITE_PROMPT" \
    --model claude-sonnet-4-6 \
    --allowedTools "Read,Write,Glob,Bash,Grep" \
    --output-format text \
    --dangerously-skip-permissions \
    | tee /tmp/claude_rewrite.txt

  # 재작성된 파일로 복사본 갱신
  if [ -s "$OUTFILE" ]; then
    cp "$OUTFILE" /tmp/blog_post.md
  fi

  # 재검증
  CHAR_COUNT2=$(python3 - <<'PYEOF'
with open('/tmp/blog_post.md', 'r', encoding='utf-8') as f:
    lines = f.readlines()
filtered = []
for line in lines:
    l = line.strip()
    if l.startswith('[이미지') or l.startswith('https://') or l.startswith('👉') or l.startswith('---') or l.startswith('#') or l == '':
        continue
    filtered.append(l)
text = ' '.join(filtered)
print(len(text.replace(' ', '')))
PYEOF
  )

  echo "재작성 후 글자수: ${CHAR_COUNT2}자"

  if [ -n "$CHAR_COUNT2" ] && [ "$CHAR_COUNT2" -lt "$MIN_CHARS" ]; then
    echo "❌ 재작성 후에도 미달: ${CHAR_COUNT2}자 — 이메일에 경고 포함"
    python3 - <<PYEOF
warning = "❌ 재작성 후에도 글자수 미달: ${CHAR_COUNT2}자 (${POST_TYPE} 기준 ${MIN_CHARS}자 이상 필요)\n수동으로 보강 후 발행하세요.\n\n---\n\n"
with open('/tmp/blog_post.md', 'r', encoding='utf-8') as f:
    content = f.read()
with open('/tmp/blog_post.md', 'w', encoding='utf-8') as f:
    f.write(warning + content)
PYEOF
  else
    echo "✅ 재작성 후 글자수 통과: ${CHAR_COUNT2}자"
  fi
else
  echo "✅ 글자수 통과: ${CHAR_COUNT}자"
fi
