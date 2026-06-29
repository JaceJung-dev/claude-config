---
description: 프로젝트 .claude/ 부트스트랩 — 선택한 skill/plugin을 opt-in으로 활성화
argument-hint: "[skills(쉼표구분)] [plugins(쉼표구분)]"
---

# 프로젝트 init (opt-in 부트스트랩)

`bin/init-project.sh`를 호출해 현재 프로젝트의 `.claude/`를 세팅한다. 이 커맨드는 스크립트를
실행하는 얇은 래퍼이며, **스크립트가 동작의 single source of truth**다. 아래 순서로 진행하라.

> **⚠️ 중요 — Bash 호출 간 셸 변수는 유지되지 않는다.**
> 각 Bash 도구 호출은 독립된 새 셸로 실행되므로, 섹션 1에서 설정한 `$REPO`/`$SCRIPT`는
> 다른 Bash 호출에서는 항상 빈 값이 된다.
> **`$REPO`/`$SCRIPT`를 사용하는 모든 Bash 블록은 섹션 1의 경로 해석 스니펫을 블록 맨 앞에
> 다시 실행해 자기완결적(self-contained)으로 작성**해야 한다.

## 1. 레포·스크립트 경로 해석 (절대경로 하드코딩 금지)

이 커맨드 파일은 레포에서 `~/.claude/commands/`로 심볼릭되어 있다. 링크를 따라가 레포 루트와
스크립트를 찾는다(deploy가 절대경로 심볼릭을 걸므로 플래그 없는 `readlink`로 충분):

```bash
CMD="$HOME/.claude/commands/init-project.md"
LINK="$(readlink "$CMD" || true)"; [ -n "$LINK" ] || LINK="$CMD"
REPO="$(cd "$(dirname "$LINK")/../.." && pwd)"
SCRIPT="$REPO/bin/init-project.sh"
[ -x "$SCRIPT" ] || { echo "init-project.sh 못 찾음: $SCRIPT (링크 깨짐?)"; exit 1; }
```

## 2. 인자 분기 (하이브리드)

인자: `$1` = 스킬(쉼표구분), `$2` = 플러그인(쉼표구분). 다른 디렉토리를 대상으로 하려면 터미널에서 `bin/init-project.sh --path <dir>`를 직접 사용하라(이 커맨드는 `--path`를 지원하지 않는다).

- **`$ARGUMENTS`가 비어 있지 않으면** → 현재 디렉토리를 대상으로 바로 실행. 주어진 플래그만 사용:
  ```bash
  ARGS=()
  [ -n "$1" ] && ARGS+=(--skills "$1")
  [ -n "$2" ] && ARGS+=(--plugin "$2")
  "$SCRIPT" "${ARGS[@]}"
  ```
- **`$ARGUMENTS`가 비어 있으면** → 아래 3번 인터랙티브 조회로 진행.

## 3. 인터랙티브 조회 (인자 없을 때 — 동적, 하드코딩 없음)

가용 목록을 그 자리에서 조회해 사용자에게 보여준다:

```bash
echo "== 내가 만든 스킬 (library/skills) =="; ls "$REPO/library/skills" 2>/dev/null
echo "== npx 서드파티 스킬 (~/.agents/skills) =="; ls "$HOME/.agents/skills" 2>/dev/null
echo "== 알려진 플러그인 (init-project.sh 매핑) =="
grep -oE '^[[:space:]]+"[a-z-]+":' "$SCRIPT" | tr -d ' ":'
```

그 다음 사용자에게 "어떤 skill과 plugin을 켤까요?"라고 묻는다. 응답을 쉼표구분으로 모아
`"$SCRIPT" --skills "<고른 스킬>" --plugin "<고른 플러그인>"` 형태로 실행한다(선택 안 한 플래그는 생략).

## 4. 보고

스크립트 출력(`skill linked (lib/npx): ...`, `init done: ...`)을 사용자에게 요약한다.
`skill not found ...` 경고가 있으면 그대로 전달한다.
