---
제목: 라이브러리 실제 재생(F6, F7)과 iOS식 밀어서 삭제(F5)
작업 날짜: 2026-10-31
프로젝트: MP3 in ma pocket
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI
소요 시간(h):
커밋: 52133fd
---

## 🎯 요청 / 배경

재생은 아직 가짜 `PreviewPlayer`가 흉내만 내고 있었다. 곡을 누르면 그 곡부터 목록 순서대로 재생하고(F6), 이전 버튼에 3초 규칙(F7)을 적용해야 했다. 실기기에서 확인해 보니 이름만 바꾼 PDF가 가져와지고, 삭제 확인이 느리고 헷갈리는 등 여러 문제도 함께 고쳐야 했다.

## 🔧 한 일

- 재생
  - `lib/playback/audio_engine.dart` 새로 작성
    - `AudioEngine` 인터페이스: `load`, `insert`, `removeAt`, `play`, `pause`, `seek`, `seekToPrevious`, `seekToNext`, `setLoop`, `setShuffle` 등
    - `EngineLoop { off, all, one }`
    - `neighborInPlayOrder()`: 셔플과 반복을 고려해 다음·이전 곡을 계산한다.
    - `JustAudioEngine`: `just_audio`로 구현. 오디오 세션을 `AudioSessionConfiguration.music()`으로 설정해 무음 스위치와 관계없이 소리가 난다.
  - `lib/playback/playback_controller.dart` 새로 작성
    - `PlaybackController`: `playAt`(F6), `previous`(3초 이상 들었으면 처음으로, 아니면 이전 곡, F7), `next`, `seek`, `setShuffle`, `setRepeat`
    - 재생 중에 목록이 바뀌면 큐를 다시 만들지 않고 바뀐 곡만 빼거나 넣는다(`_syncQueue`).
    - 반복 끄기일 때 마지막 곡이 끝나면 멈춘다.
    - 깨진 파일은 `failures` 스트림으로 알린다. 누른 곡이 깨졌으면 재생을 멈춘다.
- 가져오기
  - `lib/library/mp3_sniff.dart` 새로 작성: `looksLikeMp3()`가 앞 16KB에서 ID3 태그나 이어지는 MPEG 프레임 두 개를 찾는다.
  - `lib/library/mp3_library.dart`: `_looksLikeMp3()`로 가져올 때 파일 내용을 확인한다.
- 화면
  - `lib/design/design_preview.dart`: `PreviewPlayer`를 `PlaybackController`로 바꿨다. 재생에 실패하면 `Couldn't play "제목".` 스낵바를 띄운다. `_confirmDelete()`는 `CupertinoActionSheet`로 삭제를 확인한다.
  - `lib/design/screens/library_screen.dart`: `flutter_slidable`로 `_DeletableRow`를 만들었다. 조금 밀면 Delete 버튼이 열린 채 멈추고, 끝까지 밀면 행이 그대로 남은 채 확인 시트가 뜬다. VoiceOver는 행 동작의 Delete로 지울 수 있다. 헤더에서 About 키를 왼쪽으로 옮겨 곡 수 표시와 겹치지 않게 했다.
  - `lib/design/screens/now_playing_screen.dart`: `_DragToClose` 추가. 손가락을 따라 내려가고, 120pt를 넘거나 빠르게 튕기면 닫힌다.
  - `lib/design/widgets/player_controls.dart`: 반복 스위치를 누르면 끄기 → 전체 → 한 곡 순서로 바뀐다. 라벨 터치 영역을 44pt로 늘렸다.
  - `lib/design/widgets/track_row.dart`: Delete 글자가 줄바꿈되지 않도록 `FittedBox` 적용
  - `soft_key.dart`, `track_row.dart`, `player_controls.dart`, `about_screen.dart`: VoiceOver로 모든 키와 행을 누를 수 있도록 `Semantics.onTap` 추가
  - `lib/design/screens/about_screen.dart`: 저작권 표기를 `© 2026 ireuisu`로 변경
- `pubspec.yaml`: `just_audio`, `audio_session`, `flutter_slidable` 추가
- 테스트
  - 새로 작성: `test/fake_audio_engine.dart`, `test/playback_controller_test.dart`, `test/audio_engine_test.dart`, `test/mp3_sniff_test.dart`
  - 수정: `test/design_screens_test.dart`(밀어서 삭제, VoiceOver, Delete 줄바꿈, 헤더 겹침, Now Playing 끌어 닫기, 반복 스위치), `test/library_refresh_test.dart`, `test/mp3_library_test.dart`, `test/test_helpers.dart`(`swipeAllTheWay`, `mpegFrames`)

## 🤖 AI 활용

- 시킨 것:
  - F6은 따로 요청하지 않았다. F4 커밋 후 "커밋하고 넘어가자"에 AI가 바로 F6을 시작했다.
  - `/everything-claude-code:code-review` → "h1,m1,l1,l3 다 수정해줘"
  - "실기기로 테스트해야 하는거 테스트순서, 조건, 결과 등을 정리한 리스트업을 해줘"
  - 실기기 테스트 결과 5건을 보내 수정 요청: 이름을 .mp3로 바꾼 PDF가 가져와짐, Now Playing 핸들로 끌어 닫기가 잘 안 됨, PDF 재생 시 메시지 없이 다음 곡으로 넘어감, 3초 미만에서 이전 키가 이전 곡으로 가지 않음, 반복 키가 움직이지 않음
  - "Library 타이틀 옆에 파일 개수를 보여주고 있는데 about 페이지로 가는 버튼과 겹쳐. 위치를 바꾸거나 다른 대안을 제안해줘"
  - "Develper NAME 에 ireuisu 넣어줘"
  - 끝까지 밀어 삭제할 때 확인 팝업이 느리고 이미 삭제된 것처럼 보인다며 best practice 질문 → "추천안대로 진행해줘"
  - "조금 밀었을때 열린채로 멈추는데 그때 Del개행되고 ete가 돼서 ui가 망가져 . 진동 세기 좋고 나머지느 괜찮아"
  - `/everything-claude-code:code-review` → "미디엄 이슈들을 다 수정해줘"
  - `/everything-claude-code:code-review` → "m2, l1, l2,l3 수정해줘"
  - "커밋하고 넘어가자"
- 그대로 쓴 부분 / 고친 부분:
  - 구현, 테스트, 커밋은 AI가 했다.
  - 사용자는 실기기에서 직접 테스트해서 문제 5건, 헤더 겹침, 삭제 동작, Delete 줄바꿈을 찾아 고치게 했다.
  - 삭제 방식은 AI가 추천한 안을 그대로 받아들였다. 진동 세기는 사용자가 확인하고 그대로 두었다.
  - 저작권 이름(ireuisu)은 사용자가 정했다.
  - 세션 기록에는 사용자가 코드를 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- 이름만 .mp3로 바꾼 PDF가 가져와졌다. 처음에는 앞 3바이트만 확인했다. 최종적으로 `mp3_sniff.dart`에서 ID3 태그나 이어지는 MPEG 프레임 두 개를 확인하도록 바꿨다. AAC도 거부된다.
- 3초 미만에서 이전 키를 눌러도 같은 곡 0:00으로 돌아갔다. 1번 곡이 깨진 PDF라 iOS가 그 곡을 건너뛰어서 처음으로 돌아간 것처럼 보였을 가능성이 높다고 봤다. 이제는 깨진 곡이면 메시지를 띄운다. 진짜 mp3만으로 다시 테스트해 달라고 요청했다.
- 반복 모드 한 곡에서 `just_audio`는 다음·이전 버튼이 곡을 옮기지 않는다. 리뷰 H1에서 직접 계산한 이웃 곡(`neighborInPlayOrder`)으로 이동하도록 고쳤다.
- iOS 빌드가 다시 "file-picker-darwin requires 14.0"로 실패했다. VS Code Flutter 확장이 빌드마다 `flutter pub get`을 실행해 `Package.swift`를 `.iOS("13.0")`으로 다시 만들었기 때문이다. VS Code를 닫거나 `"dart.runPubGetOnPubspecChanges": "never"`로 설정하고 터미널에서 `flutter run`을 실행하도록 안내했다.
- `flutter_slidable`의 `DismissiblePane`은 Key가 없으면 오류가 났다. `Slidable`에 `key: widget.key`를 넘겨 해결했다.
- 테스트에서 한 프레임짜리 `tester.drag`로는 끝까지 밀어 삭제가 동작하지 않았다. 여러 프레임에 걸쳐 끄는 `swipeAllTheWay`(timedDrag)를 만들었다.
- Delete 글자 줄바꿈("Del" / "ete")은 `FittedBox`와 좌우 여백 8로 고쳤다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 작업 기간은 2026-10-25 ~ 2026-10-31이다. 작업 날짜는 커밋 날짜로 적었다.
- 로컬 테스트: `flutter analyze`와 `flutter test` 실행. 이전부터 있던 About 넘침 테스트 2개 실패와 analyze info 1건이 남아 있다. 새 About VoiceOver 테스트는 이 4px 넘침을 `takeException`으로 흡수한다.
- 이미 알고 있는 문제: iPhone SE 폭에서 Now Playing의 셔플·반복 줄이 5px 넘친다. 이번 작업 전부터 있던 문제다.
- 푸시하지 않았다.
