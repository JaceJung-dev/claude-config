# Claude Code 인프라

> · English: [README_en.md](README_en.md)

**가벼운 글로벌 + 프로젝트별 opt-in** 모델로 구성한 개인 Claude Code 설정입니다.
git 저장소가 단일 기준(source of truth)이며, 글로벌 설정은 심볼릭 링크로 `~/.claude`에
배포되고, 각 프로젝트는 필요한 skill/plugin만 선택해서 켭니다.

## 디렉토리 구조

```
006_Claude-config/
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
│   ├── skill-lock.json          # 서드파티 스킬 매니페스트 (쓰는 스킬 추적, 최신 설치)
│   └── plugin-lock.json         # 플러그인 매니페스트 (설치 대상; enable은 settings.json)
│
├── templates/
│   └── project/.claude/         # init-project.sh가 복사하는 시작 설정
│       └── settings.json
│
├── bin/
│   ├── bootstrap.sh             # 새 머신 원커맨드: deploy-global + install
│   ├── deploy-global.sh         # global/* → ~/.claude/ 심볼릭 링크
│   ├── init-project.sh          # 프로젝트 .claude/ 세팅 + 선택 skill 링크
│   ├── install.sh               # install-skills + install-plugins (래퍼)
│   ├── install-skills.sh        # 매니페스트 기준 서드파티 스킬 최신 설치
│   ├── install-plugins.sh       # 매니페스트 기준 플러그인 설치 (enable은 안 건드림)
│   ├── sync.sh                  # sync-skills + sync-plugins (래퍼)
│   ├── sync-skills.sh           # npx 변경 후 스킬 매니페스트 동기화
│   └── sync-plugins.sh          # claude plugin 변경 후 플러그인 매니페스트 동기화
│
└── docs/
    ├── skills-and-plugins.md    # 설치된 스킬·플러그인 카탈로그 (추적됨)
    └── superpowers/             # 설계 spec & 구현 plan (git 무시)
```

## 스킬

스킬은 **출처에 따라 두 가지로 나뉩니다.**

### markdonw 파일로 직접 작성된 스킬

`library/skills/`에 실제 파일로 관리합니다
글로벌에 로딩되지 **않으며**, `init-project.sh`로 프로젝트마다 켭니다. Claude Code는 세션 시작 시
프로젝트의 `.claude/skills/`를 자동 인식합니다.

| 스킬              | 용도                                              |
| ----------------- | ------------------------------------------------- |
| `skill-developer` | Anthropic 베스트 프랙티스 기반 스킬 작성 메타스킬 |

### 서드파티 스킬 (npx + 매니페스트)

Vercel `skills` CLI(`npx skills`)로 설치한 skill 들은 레포에서 **매니페스트(`library/skill-lock.json`)** 로 관리합니다.
이 파일은 *어떤 스킬을 쓰는지*를 추적할 뿐 버전을 고정하지 않습니다 — 설치는 항상 최신을 받습니다.
(`skillFolderHash`는 핀 고정용이 아니라 `npx skills check`로 원본 변경을 감지하는 용도입니다.)

> 설치된 스킬·플러그인 전체 목록은 **[docs/skills-and-plugins.md](docs/skills-and-plugins.md)** 참고.

추가 · 업데이트 · 삭제 모두 npx로 한 뒤 `sync-skills.sh`로 매니페스트를 레포에 반영하고
커밋합니다. `install-skills.sh`는 매니페스트에서 명령을 **자동 생성**하므로 직접 고칠 일이 없습니다.

```bash
npx skills add <repo> -g -s <skill> -y && bin/sync-skills.sh    # 추가     → 커밋
npx skills update -g && bin/sync-skills.sh                      # 업데이트 → 커밋
npx skills remove -g -s <skill> -y && bin/sync-skills.sh        # 삭제     → 커밋

bin/install-skills.sh             # 새 머신: 매니페스트 기준 최신 설치 (부트스트랩)
bin/install-skills.sh --dry-run   # 실행 없이 생성될 명령만 미리보기
npx skills list -g                # 설치된 글로벌 스킬 목록
```

## 플러그인 (claude plugin + 매니페스트)

플러그인도 스킬과 같은 매니페스트 방식입니다. 본체는 레포에 두지 않고, 설치된 플러그인을
**`library/plugin-lock.json`**(마켓플레이스 + 플러그인 목록)으로 추적합니다. 단 한 가지가 분리돼 있어요:

- **설치 대상**은 `plugin-lock.json`이 결정 (`install-plugins.sh`가 본체를 설치)
- **enable 여부**는 `global/settings.json`의 `enabledPlugins`가 결정 (install은 절대 안 건드림)

`claude plugin install`이 설치하면서 enable까지 자동으로 써버리기 때문에, `install-plugins.sh`는
설치 전 `settings.json`을 백업하고 설치 후 복원해 **enable 결정권을 settings.json에만** 남깁니다.
덕분에 superpowers처럼 "설치는 하되 글로벌로는 안 켜는(프로젝트 opt-in)" 상태가 그대로 유지됩니다.

> 설치된 플러그인·마켓플레이스 목록은 [docs/skills-and-plugins.md](docs/skills-and-plugins.md) 참고.

```bash
claude plugin install <p>@<mkt> && bin/sync-plugins.sh   # 추가/변경 → 매니페스트 반영 → 커밋
bin/install-plugins.sh             # 새 머신: 매니페스트 기준 설치
bin/install-plugins.sh --dry-run   # 실행 없이 명령만 미리보기
```

> ⚠️ `claude plugin install`엔 `--yes`가 없어, 새 마켓플레이스는 첫 신뢰 시 프롬프트가 뜹니다
> (대화형 전용 — headless/CI에선 실패).

## 훅 (글로벌)

| 훅 종류                                      | 스크립트           | 트리거                   | 용도                         |
| -------------------------------------------- | ------------------ | ------------------------ | ---------------------------- |
| `PostToolUse`                                | `quality-check.sh` | `Write` 또는 `Edit` 도구 | 변경된 파일에 lint/타입 검사 |
| `Notification` / `Stop` / `UserPromptSubmit` | `notify-*.sh`      | 권한 / 종료 / 프롬프트   | 터미널 알림                  |

**프로젝트 로컬 도구만 사용** — `quality-check.sh`는 `.venv/bin/`과
`node_modules/.bin/`만 봅니다(전역 설치 도구 안 씀). Python은 `ruff`+`mypy`, TS/JS는
`eslint`+`tsc`를 돌리고, 도구가 없으면 조용히 건너뜁니다.

## 사용법

### 0. 새 머신 부트스트랩 (원커맨드)

clone 직후 한 방에 전체 셋업:

```bash
bin/bootstrap.sh            # deploy-global + install-skills + install-plugins
bin/bootstrap.sh --dry-run  # 전부 미리보기
```

개별 단계는 아래 1~2 참고. 묶음 래퍼로 `bin/install.sh`(스킬+플러그인 설치),
`bin/sync.sh`(역방향 동기화)도 있습니다.

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
ln -s ~/Jace_Dev/006_Claude-config/library/skills/<이름> ~/.claude/skills/<이름>
```

## 설계 결정

| 결정                              | 근거                                                                     |
| --------------------------------- | ------------------------------------------------------------------------ |
| 가벼운 글로벌 + 프로젝트별 opt-in | always-on 글로벌이 원치 않을 때도 skill/plugin을 실행시킴                |
| 저장소 = 기준 (심볼릭)            | 버전관리되는 단일 원본; 저장소 수정이 `~/.claude`로 전파됨               |
| 서드파티는 매니페스트로 추적      | npx가 상류이므로 본체 vendoring 대신 락파일+부트스트랩만 커밋(작은 diff) |
| 플러그인 install ≠ enable 분리    | install은 본체만(설치 시 settings 백업/복원), enable은 settings.json이 결정 |
| 프로젝트 로컬 도구만 사용         | 전역 설치는 환경을 오염시킴; `.venv/bin/`으로 격리                       |
| 도구 없으면 조용히 skip           | 훅은 절대 Claude를 막지 않고 graceful하게 동작                           |

## 참고

- [Claude Code Skills 문서](https://code.claude.com/docs/en/skills)
- [스킬 작성 베스트 프랙티스](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
