# Claude Code 설정

> · English: [README_en.md](README_en.md)

개인 Claude Code 설정을 모아둔 저장소입니다.
설정과 스킬은 심볼릭 링크로 `~/.claude`에 걸고 설치·동기화는 `bin/`의 셸 스크립트로 합니다.

## 디렉토리 구조

```
006_Claude-config/
├── global/                      # ~/.claude로 심볼릭 배포 (always-on)
│   ├── CLAUDE.md                #   전역 규칙
│   ├── settings.json            #   권한·훅·플러그인 설정
│   ├── statusline-command.sh
│   ├── commands/                #   슬래시 커맨드
│   └── hooks/                   #   이벤트 훅 (검사·알림)
│
├── library/
│   ├── skills/                  # 내가 만든 스킬 (글로벌 링크)
│   ├── skill-lock.json          # 서드파티 스킬 목록
│   └── plugin-lock.json         # 플러그인 목록
│
├── templates/
│   └── project/.claude/         # init-project.sh가 복사하는 시작 설정
│
├── bin/
│   ├── bootstrap.sh             # 새 머신 원커맨드 (배포 + 설치)
│   ├── deploy-global.sh         # global/* → ~/.claude 심볼릭
│   ├── init-project.sh          # 프로젝트 세팅 + 스킬 링크
│   ├── install.sh               # 스킬 + 플러그인 설치 (래퍼)
│   ├── install-skills.sh        # 스킬 설치
│   ├── install-plugins.sh       # 플러그인 설치
│   ├── sync.sh                  # 목록 동기화 (래퍼)
│   ├── sync-skills.sh           # 스킬 목록 동기화
│   └── sync-plugins.sh          # 플러그인 목록 동기화
│
└── docs/
    ├── skills-and-plugins.md    # 설치된 스킬·플러그인 목록
    └── superpowers/             # 설계·구현 문서 (git 무시)
```

## 스킬

> 설치된 스킬·플러그인 전체 목록은 **[docs/skills-and-plugins.md](docs/skills-and-plugins.md)** 참고.

### markdown 파일로 직접 작성된 스킬

`library/skills/`에 실제 파일로 관리하고, `install-skills.sh`가 `~/.claude/skills/`로 심볼릭해
**어디서나 쓸 수 있게** 합니다(서드파티 스킬이 들어가는 위치와 동일).
특정 프로젝트에만 두고 싶으면 `init-project.sh --skills`로 그 프로젝트에만 링크할 수도 있습니다.

### 서드파티 스킬 (npx)

Vercel `skills` CLI(`npx skills`)로 설치한 스킬들은 `library/skill-lock.json`에 목록으로
적어 관리합니다.

- **설치**: `install-skills.sh`가 `skill-lock.json` 목록 기준으로 자동 설치
- **업데이트**: npx로 추가·업데이트·삭제 후 `sync-skills.sh`로 `skill-lock.json` 갱신

```bash
npx skills add <repo> -g -s <skill> -y && bin/sync-skills.sh    # 추가     → 커밋하기
npx skills update -g && bin/sync-skills.sh                      # 업데이트 → 커밋하기
npx skills remove -g -s <skill> -y && bin/sync-skills.sh        # 삭제     → 커밋하기

bin/install-skills.sh             # 새 머신: 목록 기준 최신 설치 (부트스트랩)
bin/install-skills.sh --dry-run   # 실행 없이 생성될 명령만 미리보기
npx skills list -g                # 설치된 글로벌 스킬 목록
```

## 플러그인 (claude plugin)

> 설치된 플러그인 목록은 [docs/skills-and-plugins.md](docs/skills-and-plugins.md) 참고.

플러그인 본체는 레포에 두지 않고 `library/plugin-lock.json`에 목록(마켓플레이스 + 플러그인)으로
적어 관리합니다.

- **설치**: `install-plugins.sh`가 `plugin-lock.json` 목록 기준으로 자동 설치 — **enable은 안 건드림**(`settings.json`이 결정)
- **업데이트**: `claude plugin install`로 추가·변경 후 `sync-plugins.sh`로 `plugin-lock.json` 갱신

```bash
claude plugin install <p>@<mkt> && bin/sync-plugins.sh   # 추가/변경 → 커밋하기
bin/install-plugins.sh             # 새 머신: 목록 기준 설치 (부트스트랩)
bin/install-plugins.sh --dry-run   # 실행 없이 명령만 미리보기
```

> ⚠️ `claude plugin install`엔 `--yes`가 없어 새 마켓플레이스는 첫 사용 시 신뢰 프롬프트가 뜹니다(headless/CI 실패).

## 훅 (글로벌)

| 훅 종류                                      | 스크립트           | 트리거                   | 용도                         |
| -------------------------------------------- | ------------------ | ------------------------ | ---------------------------- |
| `PostToolUse`                                | `quality-check.sh` | `Write` 또는 `Edit` 도구 | 변경된 파일에 lint/타입 검사 |
| `Notification` / `Stop` / `UserPromptSubmit` | `notify-*.sh`      | 권한 / 종료 / 프롬프트   | 터미널 알림                  |

**프로젝트 로컬 도구만 사용** — `quality-check.sh`는 `.venv/bin/`과 `node_modules/.bin/`만 봅니다(전역 설치 도구 안 씀).
Python은 `ruff`+`mypy`, TS/JS는 `eslint`+`tsc`를 돌리고, 도구가 없으면 건너뜁니다.

## 사용법

### 0. 새 머신 부트스트랩 (원커맨드)

clone 직후 한 방에 전체 셋업:

```bash
bin/bootstrap.sh            # deploy-global + install-skills + install-plugins
bin/bootstrap.sh --dry-run  # 전부 미리보기
```

### 1. 글로벌 설정 배포

```bash
bin/deploy-global.sh            # global/* 를 ~/.claude로 심볼릭 (멱등)
bin/deploy-global.sh --dry-run  # 변경 없이 미리보기
```

기존 실제 파일은 심볼릭으로 바뀌기 전에 `*.bak`으로 백업됩니다.

### 2. 프로젝트 세팅

```bash
# 프로젝트 안에서: 플러그인 켜기 (스킬은 이미 글로벌)
bin/init-project.sh --plugin superpowers

# 특정 스킬을 이 프로젝트에만 추가로 링크 / 다른 경로 지정
bin/init-project.sh --skills skill-developer --path ~/Dev/my-project
```

`templates/project/.claude/settings.json`로부터 `<프로젝트>/.claude/settings.json`을
생성하고 지정한 plugin을 활성화합니다. `--skills`를 주면 그 스킬을 프로젝트의 `.claude/skills/`에만
추가로 링크합니다(스킬은 이미 글로벌이라 보통은 불필요).

**Claude Code 안에서:** `bin/deploy-global.sh`를 한 번 배포했다면 `/init-project` 슬래시
커맨드로도 같은 일을 할 수 있습니다. 인자를 주면 바로 실행되고(`/init-project
skill-developer superpowers`), 안 주면 Claude가 가용 스킬/플러그인을 보여주고 선택을 받습니다.

### 3. 레포에 동기화

스킬·플러그인을 바꿨으면 레포의 목록 파일을 맞추고 커밋합니다:

```bash
bin/sync.sh           # skill-lock.json + plugin-lock.json 한꺼번에
bin/sync-skills.sh    # 스킬 목록만
bin/sync-plugins.sh   # 플러그인 목록만
```

## 커스터마이징

### 라이브러리에 새 스킬 추가

1. `library/skills/<이름>/SKILL.md`를 YAML frontmatter와 함께 작성.
2. 작성 가이드는 `skill-developer` 스킬 활용.
3. `install-skills.sh`로 `~/.claude/skills/`에 링크 → 글로벌로 켜짐.

### 내 스킬을 글로벌로

`library/skills/`에 새 스킬을 추가하면 `install-skills.sh`가 자동으로 `~/.claude/skills/`에
링크해 글로벌로 켭니다. 한 개만 즉시 걸고 싶으면 직접 심볼릭해도 됩니다(스크립트가 하는 일과 동일):

```bash
ln -sfn ~/Jace_Dev/006_Claude-config/library/skills/<이름> ~/.claude/skills/<이름>
```
