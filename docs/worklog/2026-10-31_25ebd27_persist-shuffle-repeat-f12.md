---
제목: 앱을 다시 열어도 셔플·반복 설정 유지(F12)
작업 날짜: 2026-10-31
프로젝트: pocket.mp3
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드:
소요 시간(h):
커밋: 25ebd27
---

## 🎯 요청 / 배경

PRD F12에 따라, 셔플과 반복 설정이 앱을 껐다 켜도 그대로 남아 있어야 했다.

## 🔧 한 일

- `lib/playback/playback_settings.dart` 새로 작성
  - `PlaybackSettings`: `shared_preferences`(`SharedPreferencesAsync`)에 `playback.shuffle`, `playback.repeat` 키로 저장한다.
  - `load()`: `({bool? shuffle, SoftRepeat? repeat})`를 돌려준다. 알 수 없는 반복 값은 `null`로 처리한다.
  - `saveShuffle()`, `saveRepeat()`
- `lib/playback/playback_controller.dart`
  - 생성자에서 `settings`를 받아, 첫 곡을 불러오기 전에 `_restore()`로 저장된 값을 적용한다.
  - `_shuffleChosen`, `_repeatChosen`: 불러오는 중에 사용자가 바꾼 값이 있으면 저장된 값으로 덮어쓰지 않는다.
  - `setShuffle()`, `setRepeat()`: 바꿀 때마다 저장한다.
  - 읽을 수 없는 값은 셔플 끄기, 반복 전체로 되돌린다.
- `lib/design/design_preview.dart`: `PlaybackController`에 `PlaybackSettings()` 연결
- `pubspec.yaml`: `shared_preferences` 추가, 개발용으로 `shared_preferences_platform_interface` 추가
- 테스트
  - `test/flutter_test_config.dart` 새로 작성: 모든 테스트가 빈 메모리 설정으로 시작한다.
  - `test/playback_settings_test.dart` 새로 작성: 기본값, 다시 실행한 뒤 복원, 불러오는 중 바꾼 값 우선, 설정을 읽지 못할 때 로그를 남기고 기본값으로 재생, 알 수 없는 값은 기본값
  - `test/library_refresh_test.dart`: 다시 실행했을 때 설정이 복원되는지 확인
- `design/README.md`: 새 파일과 F12 반영

## 🤖 AI 활용

- 시킨 것:
  - "F12 진행해줘"
  - 기기 테스트 중 질문: "앱 전환 화면에서 앱을 위로 밀어 완전히 끄면 flutter run 이 끝나느데?"
  - "다시 flutter run 을 하니까 작은 플레이어가 없어(실행중인 파일이 없어)"
  - `/everything-claude-code:code-review` → "테스트 추가해줘"
  - "커밋하고 넘어가자"
- 그대로 쓴 부분 / 고친 부분:
  - 구현, 테스트, 커밋은 AI가 했다.
  - 리뷰 결과 CRITICAL, HIGH, MEDIUM은 없었다. 사용자는 설정을 읽지 못하는 경우의 테스트만 추가하게 했다.
  - LOW 항목 L1(불러오기 시간 제한), L2(문서 주석)는 고치지 않았다.
  - 세션 기록에는 사용자가 코드를 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- 앱을 완전히 끄면 `flutter run`도 끝났다. 디버그 연결이 끊긴 것이고, iOS 14 이상에서는 디버그 빌드를 홈 화면 아이콘으로 다시 켤 수 없다. `flutter run`을 다시 실행하거나 `flutter run --release`로 확인하라고 안내했다. 앞으로 기기 테스트는 릴리스 빌드를 추천했다.
- 다시 실행하면 미니 플레이어가 없었다. 정상 동작이다. F12는 셔플과 반복 설정만 저장하고 마지막에 듣던 곡은 저장하지 않는다. 이어듣기는 PRD에서 다음 버전 후보 1순위다.
- 테스트 파일에서 `SizedBox` import가 빠져 analyze 오류가 났다. `flutter/widgets.dart` import를 추가해 해결했다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 로컬 테스트: 전체 84개 중 82개 통과. 실패 2개는 이전부터 있던 About 넘침 테스트다. `flutter analyze`는 이전부터 있던 info 1건만 나왔다.
- 푸시하지 않았다.
- 핵심 키워드는 정해진 목록(API, DB, 인증, UI, 성능, 인프라) 중 맞는 것이 없어 비워 두었다. 설정은 기기 안 `shared_preferences`에 저장한다.
- 남은 LOW 항목: 설정 저장소가 응답하지 않으면 재생 작업도 함께 멈출 수 있다(`settings.load()` 시간 제한 없음).
- 다음 작업: F9(잠금화면)를 진행 중이다. 아직 커밋 전이다. F10과 F8 실기기 확인도 남아 있다.
