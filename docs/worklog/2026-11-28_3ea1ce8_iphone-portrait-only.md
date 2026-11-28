---
제목: 아이폰 전용, 세로 화면 고정
작업 날짜: 2026-11-28
프로젝트: pocket.mp3
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI, 인프라
소요 시간(h):
커밋: 3ea1ce8
---

## 🎯 요청 / 배경

PRD는 아이폰 전용, 세로 화면만 지원인데 프로젝트는 가로 화면과 아이패드도 허용하고 있었다.

## 🔧 한 일

- `ios/Runner/Info.plist`: `UISupportedInterfaceOrientations`를 세로만 남기고, `UISupportedInterfaceOrientations~ipad` 키를 지웠다.
- `ios/Runner.xcodeproj/project.pbxproj`: `TARGETED_DEVICE_FAMILY`를 `"1,2"`에서 `1`(아이폰)로 바꿨다.

## 🤖 AI 활용

- 시킨 것:
  - "1. 세로화면 고정 2. 곡 목록 길이 표시하기 3. … 4. 테스트 없는 기능 테스트 추가해줘"
  - "작업별로 나눠서 커밋해줘"
- 그대로 쓴 부분 / 고친 부분:
  - 설정 변경과 커밋은 AI가 했다.
  - 세션 기록에는 사용자가 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- 아이패드를 대상에 둔 채 세로만 허용하면 App Store 검증에서 걸린다(아이패드 멀티태스킹은 모든 방향을 요구함). 그래서 대상 기기를 아이폰으로만 바꿨다. 아이패드에서는 아이폰 호환 모드로 돌아간다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 이 커밋 단독으로 `flutter analyze`(error·warning 0)와 `flutter test`를 돌렸다. 이전부터 있던 About 넘침 테스트 2개만 실패했다.
- 설정 확인 테스트는 커밋 c1235d3에 들어 있다.
- 실기기에서 세로 고정은 아직 확인하지 않았다.
