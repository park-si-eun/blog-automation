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
  *)
    echo "오늘은 주말입니다. 블로그 글 생성을 건너뜁니다."
    exit 0
    ;;
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
