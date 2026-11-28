---
제목: Soft Keys 디자인 프리뷰, PRD, iOS 프로젝트로 저장소 첫 커밋
작업 날짜: 2026-10-24
프로젝트: pocket.mp3
작업 유형: 설계
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI, 인프라
소요 시간(h):
커밋: 1ea6253
---

## 🎯 요청 / 배경

MVP 기능 구현을 시작하기 전에 PRD, 디자인 프리뷰 앱, iOS 프로젝트를 git 저장소로 묶고 GitHub에 올려 기준점을 만들었다.

## 🔧 한 일

- `MP3 in ma pocket — PRD.md` 추가: MVP 요구사항 F1~F12, 비기능 요구사항, 화면 구성, 기술 스택, 미결 사항
- `design/README.md`, `design/tokens.json` 추가: Soft Keys 디자인 원칙, 화면(02S·03S·04S/05S·08S), 컴포넌트 규칙, 색·폰트·간격 토큰
- 디자인 프리뷰 앱 추가 (실제 기능 없이 화면만 동작)
  - `lib/main.dart`: `DesignPreviewApp` 실행
  - `lib/design/design_preview.dart`: 가짜 재생 상태 `PreviewPlayer`
  - `lib/design/tokens.dart`(`SoftColors`, `SoftSpace`, `SoftRadius`, `SoftMotion`, `SoftShadows`), `typography.dart`, `theme.dart`, `licenses.dart`
  - `lib/design/screens/`: `empty_library_screen.dart`, `library_screen.dart`, `now_playing_screen.dart`, `about_screen.dart`, `soft_scaffold.dart`
  - `lib/design/widgets/`: `soft_surface.dart`, `soft_key.dart`, `soft_header.dart`, `track_row.dart`, `player_controls.dart`
- 폰트와 라이선스 추가: `assets/fonts/`(DotGothic16, Galmuri11, JetBrains Mono), `assets/licenses/`(OFL 원문 3개)
- iOS 프로젝트(`ios/`) 추가: `Info.plist`에 `UIBackgroundModes`(audio), `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`
- `test/design_screens_test.dart`: 화면 렌더링 테스트
- `.gitignore`에 항목 추가: `*.mp3`, `/samples/`, 서명 파일(`*.p8`, `*.p12`, `*.mobileprovision` 등), fastlane 결과물, `.env`, `.fvm/`, `.claude/settings.local.json`, `.flutter-plugins`
- `design/README.md`에서 claude.ai 아티팩트 링크 삭제
- GitHub 저장소 `nwewave32/mp3_in_ma_pocket` 생성 후 `main` 푸시

## 🤖 AI 활용

- 시킨 것:
  - "prd를 읽고 현재 구현된 화면, 기능, 동작 등에서 빠진게 있는지 확인해줘"
  - "gitignore 에 추가해야 하는게 있는지 검토해줘" → "응 추가해줘"
  - "보안 검사 한번더 해줘"
  - "아티팩트 링크 삭제해주고 깃허브에 리포지토리 생성해줘"
- 그대로 쓴 부분 / 고친 부분:
  - `.gitignore` 추가 항목은 AI 제안을 그대로 반영했다.
  - 커밋, GitHub 저장소 생성, 푸시는 AI가 실행했다.
  - PRD, 디자인 프리뷰 코드, iOS 프로젝트는 이 세션 전에 이미 있던 파일이다. 어떻게 만들었는지는 세션 기록에 없다.
  - 세션 기록에는 사용자가 AI 결과물을 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- PRD 점검 결과, PRD에는 "`lib/main.dart`에 F1, F2, F4~F7이 일부 구현돼 있다"고 적혀 있었지만, 실제 `main.dart`는 프리뷰 실행 코드뿐이었다. 재생, 가져오기, 삭제는 `PreviewPlayer`가 흉내만 냈다. 이후 F1부터 순서대로 구현하기로 했다.
- 보안 점검: 커밋 대상 74개 파일에서 비밀 정보는 나오지 않았다.

## ✅ 검증

- [ ]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 이 커밋 전에는 `flutter test`를 돌리지 않았다. 이후 세션에서 이 커밋에서도 "About renders without overflow" 테스트 2개(light/dark, 4px 넘침)가 실패한다는 것을 확인했다.
- `flutter analyze`에 `lib/design/typography.dart`의 불필요한 `dart:ui` import info가 1건 남아 있다.
- 6개 커밋 중 원격에 푸시된 것은 이 커밋뿐이다.
