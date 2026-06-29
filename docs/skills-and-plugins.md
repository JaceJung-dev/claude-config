# 스킬 & 플러그인 목록

이 환경에 설치/추적되는 스킬과 플러그인 목록입니다. 출처와 관리 방식에 따라 나뉩니다.

- **내가 만든 스킬** — `library/skills/`에 본체 보관, 이 레포가 기준. `install-skills.sh`가 `~/.claude/skills/`로 링크해 글로벌.
- **서드파티 스킬** — `npx skills`가 글로벌 설치, 레포는 `library/skill-lock.json` 목록만 추적.
- **플러그인** — 마켓플레이스에서 설치. 일부는 스킬을 함께 제공.

> 서드파티 스킬은 `library/skill-lock.json` 목록으로 관리합니다. 추가·삭제 시 이 표도 같이 갱신하세요.
> 설치/업데이트 명령은 [README](../README.md#서드파티-스킬-npx) 참고.

## 스킬

### 내가 만든 스킬 (vendored, 글로벌)

| 스킬              | 용도                                              |
| ----------------- | ------------------------------------------------- |
| `skill-developer` | Anthropic 베스트 프랙티스 기반 스킬 작성 메타스킬 |

### 서드파티 스킬 (npx)

| 스킬                            | 출처                     | 용도                                                       |
| ------------------------------- | ------------------------ | ---------------------------------------------------------- |
| `find-skills`                   | vercel-labs/skills       | 에이전트 스킬 탐색 및 설치                                  |
| `vercel-react-best-practices`   | vercel-labs/agent-skills | React/Next.js 성능 최적화 패턴                              |
| `web-design-guidelines`         | vercel-labs/agent-skills | 웹 인터페이스 가이드라인 기준 UI/접근성 리뷰                |
| `pptx`                          | anthropics/skills        | .pptx 생성 / 편집 / 추출                                    |
| `ask-matt`                      | mattpocock/skills        | 상황에 맞는 스킬·플로우를 골라주는 라우터                   |
| `setup-matt-pocock-skills`      | mattpocock/skills        | 엔지니어링 스킬용 이슈 트래커·라벨·문서 레이아웃 1회 셋업   |
| `grill-me`                      | mattpocock/skills        | 계획·설계를 날카롭게 다듬는 집요한 인터뷰                   |
| `grill-with-docs`               | mattpocock/skills        | grill-me + 진행하며 ADR·용어집 문서 생성                   |
| `codebase-design`              | mattpocock/skills        | 깊은 모듈 설계용 공용 어휘 (인터페이스/seam/테스트 용이성)  |
| `improve-codebase-architecture` | mattpocock/skills        | deepening 기회 스캔 → HTML 리포트 → 선택 항목 grill         |
| `diagnosing-bugs`               | mattpocock/skills        | 어려운 버그·성능 회귀 진단 루프                             |
| `tdd`                           | mattpocock/skills        | 테스트 우선(red-green-refactor) 개발                       |
| `prototype`                     | mattpocock/skills        | 설계 검증용 일회성 프로토타입(터미널 앱/UI 변형) 제작       |
| `to-prd`                        | mattpocock/skills        | 대화 내용을 PRD로 합성해 이슈 트래커에 발행                 |
| `to-issues`                     | mattpocock/skills        | 계획·스펙·PRD를 독립적인 이슈(수직 슬라이스)로 분할         |
| `triage`                        | mattpocock/skills        | 이슈·외부 PR을 트리아지 상태머신으로 분류·검증·브리핑       |
| `handoff`                       | mattpocock/skills        | 현재 대화를 다른 에이전트용 핸드오프 문서로 압축            |

## 플러그인

마켓플레이스에서 설치한 플러그인입니다. **활성화** 열은 `global/settings.json`의 `enabledPlugins`
기준입니다 — `프로젝트 opt-in`은 설치만 되어 있고 글로벌로 켜지 않아 `init-project.sh --plugin`으로
프로젝트마다 켜는 것입니다.

> 본체는 레포에 두지 않고 `library/plugin-lock.json`(목록)으로 추적합니다 — 새 머신에선
> `bin/install-plugins.sh`가 설치합니다. **설치 대상은 목록, enable 여부는 위 settings.json**으로
> 분리돼 있어 install이 enable을 바꾸지 않습니다(설치 시 settings 백업/복원). 변경 후엔 `bin/sync-plugins.sh`로 반영.

| 플러그인        | 마켓플레이스                       | 활성화        | 용도                                                    |
| --------------- | ---------------------------------- | ------------- | ------------------------------------------------------- |
| `skill-creator` | anthropics/claude-plugins-official | 글로벌        | 스킬 작성/스캐폴딩 도우미 (`skill-creator` 스킬 제공)   |
| `plannotator`   | backnotprop/plannotator            | 글로벌        | 계획·코드리뷰 annotation UI (`plannotator-*` 스킬 제공) |
| `superpowers`   | anthropics/claude-plugins-official | 프로젝트 opt-in | 다목적 워크플로 스킬 번들                                |
