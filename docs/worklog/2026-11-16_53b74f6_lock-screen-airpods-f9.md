---
제목: 잠금화면·제어센터·에어팟에서 플레이어 조작(F9)
작업 날짜: 2026-11-16
프로젝트: MP3 in ma pocket
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI
소요 시간(h):
커밋: 53b74f6
---

## 🎯 요청 / 배경

PRD F9에 따라 잠금화면과 제어센터에 곡 제목이 나오고, 재생/일시정지, 이전/다음, 탐색, 에어팟 버튼이 동작해야 했다. 구현은 2026-10-31에 했고, 커밋은 2026-11-16에 했다.

## 🔧 한 일

- `lib/playback/system_controls.dart` 새로 작성
  - `SystemControls extends BaseAudioHandler`: `PlaybackController`의 변경을 듣고(`_sync`) `mediaItem`(제목, 길이)과 `playbackState`(버튼, 재생 여부, 위치, 큐 위치)를 iOS에 보낸다.
  - `play`, `pause`, `stop`, `skipToNext`, `skipToPrevious`, `seek`를 모두 `PlaybackController`로 보낸다. 그래서 잠금화면 버튼도 F7(3초 규칙)과 반복 한 곡 규칙을 따른다.
  - 반복이 꺼져 있고 마지막 곡이면 다음 버튼을 뺀다(`hasNext`).
  - 위치는 1초 넘게 어긋날 때만 다시 보낸다(`_drift`).
  - `SystemControls.start()`: `AudioService.init`으로 iOS에 등록한다.
- `lib/playback/playback_controller.dart`
  - `togglePlay()`를 `play()`, `pause()`로 나눴다.
  - `hasNext` 추가. `setShuffle()`, `setRepeat()`는 엔진에 반영된 뒤 한 번 더 알린다.
- `lib/design/design_preview.dart`: `connectLockScreen` 추가. 실제 플레이어일 때만 `SystemControls.start`로 연결하고, 실패하면 로그만 남기고 재생은 계속한다.
- `pubspec.yaml`: `audio_service` 추가
- 테스트
  - `test/system_controls_test.dart` 새로 작성: 잠금화면 표시, 원격 명령이 F7·반복 한 곡 규칙을 따르는지, 마지막 곡 다음 버튼
  - `test/library_refresh_test.dart`: 잠금화면이 앱의 플레이어를 받는지, 연결이 실패해도 재생되는지
- `design/README.md`: `system_controls.dart`, 테스트 반영. 남은 연결 목록에서 F9 삭제
- `MP3 in ma pocket — PRD.md`: 기술 스택 표의 백그라운드·잠금화면 패키지를 `audio_service`로 변경

## 🤖 AI 활용

- 시킨 것:
  - "F9 진행해줘"
  - 코드 리뷰 뒤 "M1 테스트 추가해줘 l1도 수정해줘"
  - 2026-11-05 "실기기 확인 목록을 보여줘"
  - 2026-11-16 "커밋 올리고싶은데 작업한지 오래돼서 기억이 안나 지금 무슨 상태야?" → "추천대로 나눠서 커밋해줘, docs도 넣어줘" → "푸시해줘"
- 그대로 쓴 부분 / 고친 부분:
  - 구현, 테스트, 커밋은 AI가 했다.
  - PRD는 `just_audio_background`를 쓰라고 했지만, AI가 코드를 확인해 보니 잠금화면 이전/다음이 F7·반복 한 곡 규칙과 달라 `audio_service`로 바꿨다. PRD 표도 AI가 고쳤다.
  - 리뷰 결과 CRITICAL, HIGH는 없었다. 사용자가 M1(앱 연결 테스트), L1(마지막 곡 다음 버튼 회색)을 고치게 했고, L3(`pause()` 문서 주석)도 함께 고쳤다. L2(일시정지 중 1초 미만 탐색 시 잠금화면 시간이 최대 1초 어긋남)는 고치지 않았다.
  - 세션 기록에는 사용자가 코드를 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- `just_audio_background`는 잠금화면 명령을 플레이어에 바로 넘겨서 앱 규칙을 거치지 않았다. `audio_service`로 바꾸고 명령을 `PlaybackController`로 보냈다.
- 앱 연결 테스트에서 실제 `AudioService.init`을 부르면, 테스트 환경에서 아트워크 캐시 폴더 만들기가 앱의 오류 처리를 거치지 않고 실패했다. 연결 함수를 바꿔 끼울 수 있게(`connectLockScreen`) 해서 테스트했다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 로컬 테스트: 95개 중 93개 통과. 실패 2개는 이전부터 있던 About 넘침 테스트다. `flutter build ios --debug --no-codesign` 성공.
- 실기기 확인 전에 커밋했다. 잠금화면, 제어센터, 에어팟은 시뮬레이터로 확인할 수 없어서 `flutter run --release`로 실기기에서 확인해야 한다.
- 2026-11-16에 F1·F3부터 이 커밋까지 GitHub에 푸시했다.
