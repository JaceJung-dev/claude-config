# Claude Code 인프라

> · English: [README_en.md](README_en.md)

**가벼운 글로벌 + 프로젝트별 opt-in** 모델로 구성한 개인 Claude Code 설정입니다.
git 저장소가 단일 기준(source of truth)이며, 글로벌 설정은 심볼릭 링크로 `~/.claude`에
배포되고, 각 프로젝트는 필요한 skill/plugin만 선택해서 켭니다.

## 디렉토리 구조

```
017_Claude-config/
├── global/                      # ~/.claude로 심볼릭 배포 (가볍게, always-on)
│   ├── CLAUDE.md                #   언어 / 워크플로 / 코드 규칙
│   ├── settings.json            #   권한, statusline, quality-check 훅,
│   │                            #     플러그인(plannotator, skill-creator)
│   ├── statusline-command.sh
│   ├── commands/
│   │   └── init-project.md      #   /init-project 슬래시 커맨드
│   └── hooks/
│       ├── quality-check.sh     #   편집 시 lint/타입 검사
│       └── notify-*.sh          #   입력 / 종료 / 기록시작 알림
│
├── library/
│   ├── skills/                  # 내가 만든 opt-in 스킬 (글로벌 자동 로딩 안 함)
│   │   └── skill-developer/             #   스킬 작성 메타스킬
│   └── skill-lock.json          # 서드파티 스킬 매니페스트 (npx 락파일 스냅샷)
│
├── templates/
│   └── project/.claude/         # init-project.sh가 복사하는 시작 설정
│       └── settings.json
│
├── bin/
│   ├── deploy-global.sh         # global/* → ~/.claude/ 심볼릭 링크
│   ├── init-project.sh          # 프로젝트 .claude/ 세팅 + 선택 skill 링크
│   ├── install-skills.sh        # 락파일 기준 서드파티 스킬 설치 (부트스트랩)
│   └── sync-skills.sh           # npx 업데이트 후 락파일을 레포로 동기화
│
└── docs/superpowers/            # 설계 spec & 구현 plan
```

## 스킬

스킬은 **출처에 따라 두 가지로 나뉩니다.**

### 내가 만든 스킬 (vendored, opt-in)

`library/skills/`에 실제 파일로 보관 — 이 레포가 기준(source of truth)입니다. 글로벌에
로딩되지 **않으며**, `init-project.sh`로 프로젝트마다 켭니다. Claude Code는 세션 시작 시
프로젝트의 `.claude/skills/`를 자동 인식합니다.

| 스킬              | 용도                                              |
| ----------------- | ------------------------------------------------- |
| `skill-developer` | Anthropic 베스트 프랙티스 기반 스킬 작성 메타스킬 |

### 서드파티 스킬 (npx + 락파일)

남이 만든 스킬은 레포에 본체를 복사하지 않습니다. Vercel `skills` CLI(`npx skills`)가
글로벌로 설치/관리하고, 레포는 **락파일(`library/skill-lock.json`) 한 곳**만 기준으로
추적합니다. (npm에서 `node_modules`는 안 올리고 `package-lock.json`만 올리는 것과 같음)

| 스킬                          | 출처                     | 용도                                  |
| ----------------------------- | ------------------------ | ------------------------------------- |
| `find-skills`                 | vercel-labs/skills       | 에이전트 스킬 탐색 및 설치            |
| `vercel-react-best-practices` | vercel-labs/agent-skills | React/Next.js 성능 최적화 패턴        |
| `web-design-guidelines`       | vercel-labs/agent-skills | 웹 인터페이스 가이드라인 기준 UI 리뷰 |
| `pptx`                        | anthropics/skills        | .pptx 생성 / 편집 / 추출              |

추가 · 업데이트 · 삭제 모두 npx로 한 뒤 `sync-skills.sh`로 락파일을 레포에 반영하고
커밋합니다. `install-skills.sh`는 락파일에서 명령을 **자동 생성**하므로 직접 고칠 일이 없습니다.

```bash
npx skills add <repo> -g -s <skill> -y && bin/sync-skills.sh    # 추가     → 커밋
npx skills update -g && bin/sync-skills.sh                      # 업데이트 → 커밋
npx skills remove -g -s <skill> -y && bin/sync-skills.sh        # 삭제     → 커밋

bin/install-skills.sh             # 새 머신: 락파일 기준 자동 설치 (부트스트랩)
bin/install-skills.sh --dry-run   # 실행 없이 생성될 명령만 미리보기
npx skills list -g                # 설치된 글로벌 스킬 목록
```

## 훅 (글로벌)

| 훅 종류                                      | 스크립트           | 트리거                   | 용도                         |
| -------------------------------------------- | ------------------ | ------------------------ | ---------------------------- |
| `PostToolUse`                                | `quality-check.sh` | `Write` 또는 `Edit` 도구 | 변경된 파일에 lint/타입 검사 |
| `Notification` / `Stop` / `UserPromptSubmit` | `notify-*.sh`      | 권한 / 종료 / 프롬프트   | 터미널 알림                  |

**프로젝트 로컬 도구만 사용** — `quality-check.sh`는 `.venv/bin/`과
`node_modules/.bin/`만 봅니다(전역 설치 도구 안 씀). Python은 `ruff`+`mypy`, TS/JS는
`eslint`+`tsc`를 돌리고, 도구가 없으면 조용히 건너뜁니다.

## 사용법

### 1. 글로벌 설정 배포

```bash
bin/deploy-global.sh            # global/* 를 ~/.claude로 심볼릭 (멱등)
bin/deploy-global.sh --dry-run  # 변경 없이 미리보기
```

기존 실제 파일은 심볼릭으로 바뀌기 전에 `*.bak`으로 백업됩니다.

### 2. 프로젝트 세팅 (opt-in)

```bash
# 프로젝트 안에서, 특정 skill과 plugin 활성화
bin/init-project.sh --skills web-design-guidelines,find-skills --plugin superpowers

# 또는 다른 경로 지정
bin/init-project.sh --skills skill-developer --path ~/Dev/my-project
```

`templates/project/.claude/settings.json`로부터 `<프로젝트>/.claude/settings.json`을
생성하고, 지정한 plugin을 활성화하며, 선택한 skill을 `library/skills/`(내 스킬) 또는
`~/.agents/skills/`(npx 서드파티)에서 찾아 심볼릭 링크합니다.

**Claude Code 안에서:** `bin/deploy-global.sh`를 한 번 배포했다면 `/init-project` 슬래시
커맨드로도 같은 일을 할 수 있습니다. 인자를 주면 바로 실행되고(`/init-project
skill-developer superpowers`), 안 주면 Claude가 가용 스킬/플러그인을 보여주고 선택을 받습니다.

## 커스터마이징

### 라이브러리에 새 스킬 추가

1. `library/skills/<이름>/SKILL.md`를 YAML frontmatter와 함께 작성.
2. 작성 가이드는 `skill-developer` 스킬 활용.
3. 프로젝트에서 `init-project.sh --skills <이름>`으로 활성화.

### 내 스킬을 글로벌로

`library/skills/`의 내 스킬을 글로벌로 쓰려면 심볼릭만 걸면 됩니다
(서드파티 스킬은 `npx skills`가 이미 글로벌로 설치합니다):

```bash
ln -s ~/Jace_Dev/017_Claude-config/library/skills/<이름> ~/.claude/skills/<이름>
```

## 설계 결정

| 결정                              | 근거                                                             |
| --------------------------------- | ---------------------------------------------------------------- |
| 가벼운 글로벌 + 프로젝트별 opt-in | always-on 글로벌이 원치 않을 때도 skill/plugin을 실행시킴        |
| 저장소 = 기준 (심볼릭)            | 버전관리되는 단일 원본; 저장소 수정이 `~/.claude`로 전파됨       |
| 서드파티는 매니페스트로 추적      | npx가 상류이므로 본체 vendoring 대신 락파일+부트스트랩만 커밋(작은 diff) |
| 프로젝트 로컬 도구만 사용         | 전역 설치는 환경을 오염시킴; `.venv/bin/`으로 격리               |
| 도구 없으면 조용히 skip           | 훅은 절대 Claude를 막지 않고 graceful하게 동작                   |

## 참고

- [Claude Code Skills 문서](https://code.claude.com/docs/en/skills)
- [스킬 작성 베스트 프랙티스](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
