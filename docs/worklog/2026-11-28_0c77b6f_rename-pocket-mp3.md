---
제목: 앱 이름을 pocket.mp3로 변경
작업 날짜: 2026-11-28
프로젝트: pocket.mp3
작업 유형: 배포
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI, 인프라
소요 시간(h):
커밋: 0c77b6f
---

## 🎯 요청 / 배경

App Store 출시 전에 앱 이름을 정해야 했다(PRD 미정 항목). 사용자가 pocket.mp3로 정했고, 개인정보 처리방침 경로도 이 이름으로 정해졌다.

## 🔧 한 일

- `ios/Runner/Info.plist`: `CFBundleDisplayName`, `CFBundleName`을 pocket.mp3로. 홈 화면 이름과 Files 앱 폴더 이름이 된다.
- `ios/Runner.xcodeproj/project.pbxproj`: 번들 ID `com.example.mp3InMaPocket` → `com.ireuisu.pocketmp3`(테스트 타깃은 `.RunnerTests`)
- `lib/app/legal.dart`: `legalSlug = 'pocket-mp3'`
- 화면: `about_screen.dart`, `empty_library_screen.dart`의 머리글 `POCKET.MP3`, 첫 실행 안내 "Files › On My iPhone › pocket.mp3"
- `lib/design/design_preview.dart`의 앱 title·applicationName, `lib/library/mp3_library.dart` 주석, `lib/design/tokens.dart`, `design/tokens.json`, `design/README.md` 주석
- 문서: PRD, 프로젝트 노트, 로드맵 파일 이름을 `pocket.mp3 — …`로 바꾸고, 앱 이름과 개인정보 처리방침 위치를 결정됨으로 표시. 노트 결정 표에 2026-11-28 줄 추가. 작업 기록은 옛 이름 그대로 둠
- 테스트
  - `test/platform_config_test.dart`: 표시 이름과 Files 안내가 같은지, 번들 ID
  - `test/privacy_policy_test.dart`: pocket.mp3 페이지 URL
  - `test/design_screens_test.dart`: 머리글 기대값 변경, 넘침 오류 허용 제거

## 🤖 AI 활용

- 시킨 것:
  - "이제 앱 이름을 결정하자. 지금 mp3 in ma pocket 이랑 또 뭐있어"
  - "앱 이름 pocket.mp3로 정했어 다 바꿔줘" → URL 경로 "pocket-mp3", 번들 ID "com.ireuisu.pocketmp3", 문서는 "파일 이름까지"
  - `/everything-claude-code:code-review`
  - "작업별로 나눠서 커밋해줘"
- 그대로 쓴 부분 / 고친 부분:
  - 이름 후보 제안, 변경, 테스트, 커밋은 AI가 했다. 이름·URL 경로·번들 ID는 사용자가 골랐다.
  - 리뷰의 LOW(`privacyPolicyUrl`의 이제 쓰지 않는 null 분기 등)는 고치지 않았다.
  - 세션 기록에는 사용자가 코드를 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- 이전부터 실패하던 About 넘침 테스트 2개는 긴 앱 이름이 LCD를 넘친 것이 원인이었다. 이름이 짧아져서 통과하고, 테스트의 넘침 허용 코드도 지웠다.
- 같은 날 작업을 커밋별로 나누면서, 한 파일에 여러 작업이 섞인 경우(`design_preview.dart`, `Info.plist`, `project.pbxproj`, 테스트 몇 개) 단계별 내용을 git plumbing(`hash-object`, `update-index --cacheinfo`)으로 따로 스테이징했다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 로컬 테스트 133개 모두 통과. `flutter analyze`는 이전부터 있던 info 1건(`typography.dart`의 불필요한 `dart:ui` import)만 나왔다. iOS 빌드도 됐다.
- 번들 ID가 바뀌어서 기기에는 새 앱으로 설치된다. 옛 앱의 곡과 설정은 넘어오지 않는다.
- `https://ireuisu-legal.vercel.app/pocket-mp3/privacy/`는 아직 404다. App Store 심사 전에 페이지를 만들어야 한다.
