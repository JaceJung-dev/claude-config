# Claude Code 인프라

> · English: [README_en.md](README_en.md)

**가벼운 글로벌 + 프로젝트별 opt-in** 모델로 구성한 개인 Claude Code 설정입니다.
git 저장소가 단일 기준(source of truth)이며, 글로벌 설정은 심볼릭 링크로 `~/.claude`에
배포되고, 각 프로젝트는 필요한 skill/plugin만 선택해서 켭니다.

## 철학

이전 설정은 모든 것을 글로벌에 always-on으로 올려두어, 원치 않을 때도 skill/plugin이
실행됐습니다. 새 모델은 역할을 분리합니다:

- **가벼운 글로벌** — `~/.claude`에는 언어/워크플로 규칙, 기본 settings, quality-check
  훅, statusline, 그리고 일부 standalone 스킬만 남깁니다.
- **저장소 = 기준** — 관리 대상 파일은 모두 이 저장소에 있고 `~/.claude`로 심볼릭
  링크됩니다. 수정은 여기서 하고, git으로 추적합니다.
- **프로젝트별 opt-in** — 무거운 글로벌 설정을 상속하는 대신, 부트스트랩 명령 하나로
  프로젝트마다 원하는 skill/plugin만 켭니다.

```
글로벌(~/.claude)  ──심볼릭──  저장소(017_Claude-config)
   가볍게 always-on            기준(source of truth)
        +                              +
   프로젝트 .claude/  ◀── init-project.sh ── library / templates
```

## 디렉토리 구조

```
017_Claude-config/
├── global/                      # ~/.claude로 심볼릭 배포 (가볍게, always-on)
│   ├── CLAUDE.md                #   언어 / 워크플로 / 코드 규칙
│   ├── settings.json            #   권한, statusline, quality-check 훅,
│   │                            #     플러그인(plannotator, skill-creator)
│   ├── statusline-command.sh
│   └── hooks/
│       ├── quality-check.sh     #   편집 시 lint/타입 검사
│       └── notify-*.sh          #   입력 / 종료 / 기록시작 알림
│
├── library/
│   └── skills/                  # opt-in 스킬 (글로벌 자동 로딩 안 함)
│       ├── skill-developer/             #   스킬 작성 메타스킬
│       ├── find-skills/                 #   스킬 탐색 & 설치
│       ├── vercel-react-best-practices/ #   React/Next 성능
│       └── web-design-guidelines/       #   UI / 접근성 리뷰
│
├── templates/
│   └── project/.claude/         # init-project.sh가 복사하는 시작 설정
│       └── settings.json
│
├── bin/
│   ├── deploy-global.sh         # global/* → ~/.claude/ 심볼릭 링크
│   └── init-project.sh          # 프로젝트 .claude/ 세팅 + 선택 skill 링크
│
└── docs/superpowers/            # 설계 spec & 구현 plan
```

## 스킬 (opt-in 라이브러리)

`library/skills/`에 보관되는 도메인별 가이드라인입니다. 글로벌에 로딩되지 **않으며**,
`init-project.sh`로 프로젝트마다 켭니다(아래 참고). Claude Code는 세션 시작 시 프로젝트의
`.claude/skills/`를 자동 인식합니다.

| 스킬                          | 용도                                                |
| ----------------------------- | --------------------------------------------------- |
| `skill-developer`             | Anthropic 베스트 프랙티스 기반 스킬 작성 메타스킬   |
| `find-skills`                 | 에이전트 스킬 탐색 및 설치                          |
| `vercel-react-best-practices` | React/Next.js 성능 최적화 패턴                      |
| `web-design-guidelines`       | 웹 인터페이스 가이드라인 기준 UI / 접근성 / UX 리뷰 |

## 훅 (글로벌)

| 훅 종류                                      | 스크립트           | 트리거                   | 용도                         |
| -------------------------------------------- | ------------------ | ------------------------ | ---------------------------- |
| `PostToolUse`                                | `quality-check.sh` | `Write` 또는 `Edit` 도구 | 변경된 파일에 lint/타입 검사 |
| `Notification` / `Stop` / `UserPromptSubmit` | `notify-*.sh`      | 권한 / 종료 / 프롬프트   | 터미널 알림                  |

**프로젝트 로컬 도구만 사용** — `quality-check.sh`는 `.venv/bin/`과
`node_modules/.bin/`만 봅니다(전역 설치 도구 안 씀). 도구가 없으면 조용히 건너뛰며,
절대 작업을 막지 않습니다.

```
PostToolUse (Write/Edit) → quality-check.sh
    ├── Python (.py)         → .venv/bin/ruff check + .venv/bin/mypy
    └── TS/JS (.ts/.tsx/...) → node_modules/.bin/eslint + tsc
```

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
생성하고, 지정한 plugin을 활성화하며, 선택한 skill을 `library/skills/`에서 심볼릭
링크합니다. 터미널에서 직접 실행하거나, Claude Code에게 실행을 요청해도 됩니다.

## 커스터마이징

### 라이브러리에 새 스킬 추가

1. `library/skills/<이름>/SKILL.md`를 YAML frontmatter와 함께 작성.
2. 작성 가이드는 `skill-developer` 스킬 활용.
3. 프로젝트에서 `init-project.sh --skills <이름>`으로 활성화.

### 스킬을 다시 글로벌로

저장소에 모든 스킬이 남아 있으니, 다시 글로벌로 쓰려면 심볼릭만 걸면 됩니다:

```bash
ln -s ~/Jace_Dev/017_Claude-config/library/skills/<이름> ~/.claude/skills/<이름>
```

## 설계 결정

| 결정                              | 근거                                                             |
| --------------------------------- | ---------------------------------------------------------------- |
| 가벼운 글로벌 + 프로젝트별 opt-in | always-on 글로벌이 원치 않을 때도 skill/plugin을 실행시킴        |
| 저장소 = 기준 (심볼릭)            | 버전관리되는 단일 원본; 저장소 수정이 `~/.claude`로 전파됨       |
| 프로젝트 로컬 도구만 사용         | 전역 설치는 환경을 오염시킴; `.venv/bin/`으로 격리               |
| 도구 없으면 조용히 skip           | 훅은 절대 Claude를 막지 않고 graceful하게 동작                   |
| 스킬의 차등 상세도                | Claude가 이미 아는 건 재문서화하지 않고, 학습 이후 변경점에 집중 |

## 참고

- [Claude Code Skills 문서](https://code.claude.com/docs/en/skills)
- [스킬 작성 베스트 프랙티스](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
