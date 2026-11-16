---
제목: 라이브러리를 '파일' 앱과 같은 순서로 정렬하고, 실행할 때 첫 실행 화면이 깜빡이지 않게 수정(F4)
작업 날짜: 2026-10-25
프로젝트: MP3 in ma pocket
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI
소요 시간(h):
커밋: d54ece6
---

## 🎯 요청 / 배경

F4는 곡을 제목 알파벳순으로 보여주고, 곡이 없을 때만 빈 화면 안내를 보여줘야 한다. 단순 문자열 정렬로는 "Lecture 10"이 "Lecture 2"보다 앞에 오고 Mac에서 온 한글 파일명도 따로 정렬됐다. 또 곡이 있어도 실행 직후 빈 화면이 잠깐 보였다.

## 🔧 한 일

- `lib/library/title_order.dart` 새로 작성
  - `compareTitles(a, b)`: 대소문자를 무시하고, 숫자 부분은 크기로 비교한다(`_compareChunks`, `_isDigits`, `_compareNumbers`).
  - Mac에서 온 자모 분리(NFD) 한글을 조합해서 직접 입력한 한글과 같이 정렬한다.
- `lib/app/library_controller.dart`
  - `loaded` getter 추가: 폴더를 한 번이라도 읽었는지 나타낸다.
  - 목록을 `compareTitles`로 정렬한다.
  - `refresh()`: 첫 읽기에서 오류가 나도 `loaded`를 켜서 첫 실행 화면으로 넘어간다. 파일 시스템 오류가 아닌 예상 밖 오류는 `FlutterError.reportError`로 로그를 남긴다.
- `lib/design/design_preview.dart`: `loaded` 전에는 빈 바탕만 보여준다.
- `lib/design/screens/library_screen.dart`: 정렬 기준 주석 수정
- `design/README.md`: 정렬 규칙과 새 파일 반영
- 테스트
  - `test/title_order_test.dart` 새로 작성: 숫자 크기순, 대소문자 무시, NFD 한글
  - `test/library_refresh_test.dart`: 첫 실행 화면 깜빡임 없음, 첫 실행에서 폴더를 읽지 못하거나 예상 밖 오류가 날 때 첫 실행 화면 표시, 마지막 곡 삭제, '파일' 앱 순서

## 🤖 AI 활용

- 시킨 것:
  - "F4 진행해줘"
  - `/everything-claude-code:code-review` 실행 → "M1, L3 지금 고쳐줘"
  - "커밋하고 넘어가자"
- 그대로 쓴 부분 / 고친 부분:
  - 구현, 테스트, 커밋은 AI가 했다.
  - 리뷰 항목 중 M1, L3만 고치게 했다.
  - 세션 기록에는 사용자가 코드를 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

없음

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 로컬 테스트: `flutter analyze`와 `flutter test` 실행. 이전부터 있던 About 넘침 테스트 2개 실패와 analyze info 1건 말고는 문제가 없었다.
- 푸시하지 않았다.
- "커밋하고 넘어가자" 뒤에 AI가 따로 묻지 않고 바로 다음 항목(F6 실제 재생)을 시작했다. 다음 커밋 `52133fd`가 그 작업이다.
