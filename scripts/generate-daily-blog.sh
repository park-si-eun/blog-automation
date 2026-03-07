#!/bin/bash
# 요일별 자동 블로그 글 생성 스크립트
# GitHub Actions 또는 로컬 cron에서 실행

BRAND="sos-coffee-brunch"

# 오늘 요일 판별 (1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일)
# TEST: 월요일 강제 실행 (테스트 후 아래 줄 삭제)
DAY=1

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

# Claude CLI로 실행 (실패해도 스크립트 계속 진행)
claude -p "$PROMPT" \
  --allowedTools "Read,Write,Glob,Bash,Grep" \
  --output-format text \
  --dangerously-skip-permissions \
  2>&1 | tee /tmp/claude_output.txt

CLAUDE_EXIT=${PIPESTATUS[0]}
echo "Claude 종료 코드: $CLAUDE_EXIT"

# Claude가 Write 도구로 파일을 만들었는지 확인
if [ -f "$OUTFILE" ] && [ -s "$OUTFILE" ]; then
  echo "✅ 파일 생성 확인: $OUTFILE"
  wc -c "$OUTFILE"
else
  # Write 도구로 저장 안 됐으면 stdout 출력물을 파일로 저장
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
