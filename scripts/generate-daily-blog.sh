#!/bin/bash
# 요일별 자동 블로그 글 생성 스크립트
# GitHub Actions 또는 로컬 cron에서 실행

set -e

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

echo "블로그 글 생성 시작..."

# Claude CLI로 실행 (비대화형 모드)
claude -p "$PROMPT" \
  --allowedTools "Read,Write,Glob,Bash,Grep" \
  --output-format text

echo "블로그 글 생성 완료."
