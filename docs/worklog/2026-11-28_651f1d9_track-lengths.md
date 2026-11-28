---
제목: 곡 목록에 곡 길이 표시
작업 날짜: 2026-11-28
프로젝트: pocket.mp3
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI, 성능
소요 시간(h):
커밋: 651f1d9
---

## 🎯 요청 / 배경

F4 곡 목록은 길이를 재생해 봐야 알 수 있어서 대부분 `--:--`로 보였다. 목록에서 바로 길이가 보이게 했다.

## 🔧 한 일

- `lib/library/mp3_length.dart` 새로 작성
  - `mp3Length(audio, audioBytes:)`: 첫 오디오 프레임에서 길이를 구한다. 디코딩은 하지 않는다. VBR은 Xing/Info 또는 VBRI 헤더의 프레임 수로, 그 외에는 첫 프레임 비트레이트와 오디오 크기로 계산한다.
  - `readMp3Length(file)`: ID3v2 태그(푸터 포함)와 끝의 ID3v1 태그를 빼고 최대 16KB(`mp3LengthScan`)만 읽는다.
- `lib/library/mp3_sniff.dart`: `_frameLength`를 공개 함수 `mpegFrameLength`로 바꾸고, `mpegBitrate`, `mpegSampleRate`를 추가했다.
- `lib/library/mp3_library.dart`: 파일 크기와 수정 시각을 키로 하는 길이 캐시(`_lengths`), `cachedLength()`, `lengthOf()`를 추가했다. 파일을 지우면 캐시도 지운다.
- `lib/app/library_controller.dart`: 목록은 먼저 보여 주고, `_measure()`가 길이를 50개씩(`_lengthBatch`) 채운다. 새로고침이 다시 시작되면 이전 측정 결과는 버린다(generation 비교).
- `lib/design/screens/library_screen.dart`, `lib/design/design_preview.dart`: 재생 중인 곡은 플레이어가 아는 길이(`currentDuration`)를 보여 준다. Now Playing, 잠금화면과 같다.
- 테스트
  - `test/mp3_length_test.dart` 새로 작성: CBR, Xing, VBRI, ID3 태그, 앞쪽 쓰레기 바이트, 프레임이 없을 때
  - `test/library_refresh_test.dart`: "F4: track lengths" 그룹 추가
  - `test/test_helpers.dart`: `xingMp3(frames)` 추가

## 🤖 AI 활용

- 시킨 것:
  - "2. 곡 목록 길이 표시하기"
  - `/everything-claude-code:code-review` 두 번
  - "작업별로 나눠서 커밋해줘"
- 그대로 쓴 부분 / 고친 부분:
  - 헤더 파서, 캐시, 테스트, 커밋은 AI가 했다.
  - 첫 리뷰의 HIGH(16KB 읽은 범위 끝에 프레임 헤더 하나만 있어도 프레임으로 인정함)를 고치고 테스트를 추가했다.
  - LOW로 남긴 것: `LibraryScreen` 생성자에서 `currentDuration` 필드 위치, 지워지지 않고 남는 캐시 항목(이름을 바꾼 파일 등).
  - 세션 기록에는 사용자가 코드를 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- 위젯 테스트에서 길이가 `--:--`로 나왔다. 길이 측정이 끝나기 전에 확인했기 때문이다. 실제 파일 읽기를 몇 번 기다리는 `readLengths` 헬퍼로 해결했다.
- 프레임 헤더 하나만 보고 판단하면 오디오 앞의 0xFF 바이트를 프레임으로 착각한다. 프레임 두 개가 이어질 때만 인정하고, 하나만 있는 경우는 파일 끝일 때만 인정했다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 이 커밋 단독으로 `flutter analyze`(error·warning 0)와 `flutter test`를 돌렸다. 이전부터 있던 About 넘침 테스트 2개만 실패했다.
- 실기기에서 많은 곡을 넣었을 때의 속도는 아직 확인하지 않았다.
