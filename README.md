# Claude Code 설정

[English](README_en.md)

개인 Claude Code 설정(전역 규칙·훅·스킬·플러그인)을 한 저장소에서 버전 관리합니다.
`bootstrap.sh` 한 번이면 새 머신에 내 환경을 그대로 복원합니다.

설정 본체는 이 레포에 두고 `~/.claude`로는 **심볼릭 링크**만 겁니다. 레포를 고치면 바로
반영되고, 서드파티 스킬·플러그인은 본체 대신 **lock 파일**로 목록만 추적해 새 머신에서
그대로 재설치합니다.

| 무엇을        | 어떻게 관리                        | 새 머신에서          |
| ------------- | ---------------------------------- | -------------------- |
| 전역 설정·훅  | 본체를 레포에 두고 **심볼릭 링크** | `deploy-global.sh`   |
| 내 스킬       | `library/skills/`에 실제 파일      | `install-skills.sh`  |
| 서드파티 스킬 | `skill-lock.json` **목록**         | `install-skills.sh`  |
| 플러그인      | `plugin-lock.json` **목록**        | `install-plugins.sh` |

## Quick Start

```bash
git clone git@github.com:JaceJung-dev/claude-config.git
cd claude-config

bin/bootstrap.sh            # 전역 배포 + 스킬·플러그인 설치 (원커맨드)
bin/bootstrap.sh --dry-run  # 먼저 전부 미리보기
```

`bootstrap.sh`는 아래 세 가지를 한 번에 실행합니다 — `deploy-global` + `install-skills` + `install-plugins`.
각 단계를 따로 돌리는 법은 [사용법](#사용법)을 참고하세요.

## 사용법

부트스트랩이 묶어 실행하는 단계들을 따로 돌리고 싶을 때 씁니다.

### 1. 글로벌 설정 배포

```bash
bin/deploy-global.sh            # global/* 를 ~/.claude로 심볼릭 (멱등)
bin/deploy-global.sh --dry-run  # 변경 없이 미리보기
```

> [!TIP]
> 기존 실제 파일은 심볼릭으로 바뀌기 전에 `*.bak`으로 백업됩니다.

### 2. 레포에 동기화

스킬·플러그인을 바꿨으면 레포의 목록 파일을 맞추고 커밋합니다:

```bash
bin/sync.sh           # skill-lock.json + plugin-lock.json 한꺼번에
bin/sync-skills.sh    # 스킬 목록만
bin/sync-plugins.sh   # 플러그인 목록만
```

## 디렉토리 구조

<details>
<summary>트리 펼쳐 보기</summary>

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
│   ├── skills/                  # markdown 원형 스킬 (글로벌 링크)
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
    ├── components.md            # 구성요소 목록 (스킬·플러그인·훅)
    └── superpowers/             # 설계·구현 문서 (로컬 전용, 레포에 없음)
```

</details>

## 스킬

> 설치된 스킬·플러그인 전체 목록은 **[docs/components.md](docs/components.md)** 참고.

### markdown 원형 스킬

`library/skills/`에 실제 파일로 관리하고, `install-skills.sh`가 `~/.claude/skills/`로 심볼릭해
**어디서나 쓸 수 있게** 합니다(서드파티 스킬이 들어가는 위치와 동일).
특정 프로젝트에만 두고 싶으면 `init-project.sh --skills`로 그 프로젝트에만 링크할 수도 있습니다.

### 서드파티 스킬 (npx)

Vercel `skills` CLI(`npx skills`)로 설치한 스킬들은 `library/skill-lock.json`에 목록으로 적어 관리합니다.

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

## 플러그인

> 설치된 플러그인 목록은 [docs/components.md](docs/components.md) 참고.

플러그인 본체는 레포에 두지 않고 `library/plugin-lock.json`에 목록(마켓플레이스 + 플러그인)으로 적어 관리합니다.

- **설치**: `install-plugins.sh`가 `plugin-lock.json` 목록 기준으로 자동 설치 — **enable은 안 건드림**(`settings.json`이 결정)
- **업데이트**: `claude plugin install`로 추가·변경 후 `sync-plugins.sh`로 `plugin-lock.json` 갱신

```bash
claude plugin install <p>@<mkt> && bin/sync-plugins.sh   # 추가/변경 → 커밋하기
bin/install-plugins.sh             # 새 머신: 목록 기준 설치 (부트스트랩)
bin/install-plugins.sh --dry-run   # 실행 없이 명령만 미리보기
```

> [!WARNING]
> `claude plugin install`엔 `--yes`가 없어 새 마켓플레이스는 첫 사용 시 신뢰 프롬프트가 뜹니다(headless/CI 실패).
