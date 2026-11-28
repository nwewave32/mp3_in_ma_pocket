---
제목: 곡명 폰트를 Space Grotesk로, 한글은 Pretendard로
작업 날짜: 2026-11-28
프로젝트: pocket.mp3
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI
소요 시간(h):
커밋: d5106ce
---

## 🎯 요청 / 배경

Library 화면의 곡명 폰트를 Space Grotesk로 바꾸고 싶었다. Space Grotesk에는 한글이 없어서, 한글 파일명용으로 Pretendard를 fallback으로 지정했다.

## 🔧 한 일

- 폰트 파일
  - `assets/fonts/SpaceGrotesk-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf` (사용자가 넣음)
  - `assets/fonts/Pretendard-Regular.otf`, `-SemiBold.otf` (Pretendard 1.3.9 공식 릴리스에서 AI가 받음, 각 약 1.6MB)
- 라이선스: `assets/licenses/OFL-SpaceGrotesk.txt`(사용자가 넣음), `OFL-Pretendard.txt`, `lib/design/licenses.dart`에 두 항목 등록
- `pubspec.yaml`: SpaceGrotesk(Regular, Medium 500, SemiBold 600), Pretendard(Regular, SemiBold 600) 패밀리
- `lib/design/typography.dart`: `SoftFonts.trackTitle`, `trackTitleFallback`, `SoftText.trackTitle()`, `trackTitleStrong()`(w600)
- `lib/design/widgets/track_row.dart`: 곡명은 `trackTitle`, 재생 중인 줄은 `trackTitleStrong`. 길이는 JetBrains Mono 그대로
- `test/fonts_test.dart` 새로 작성: 스타일, pubspec의 폰트 파일이 모두 있는지, 라이선스가 모두 등록·번들됐는지

## 🤖 AI 활용

- 시킨 것:
  - "library screen에서 곡명 폰트를 space groktesk 폰트로 바꿔줘 … 라이선스 등록도 … 해줘 반영됏는지 확인까지 할게"
  - "라이선스 파일 넣었어, 테스트 돌려줘"
  - "한글제목을 위해서 Pretendard를 fontFamilyFallback으로 지정해줘" → 파일은 "Claude가 받아오기"
  - "Medium은 빼주고 flutter run release 했는데 다시 리스타트 해야해?"
  - "작업별로 나눠서 커밋해줘"
- 그대로 쓴 부분 / 고친 부분:
  - pubspec의 SpaceGrotesk 설정과 라이선스 등록 문구는 사용자가 준 것을 그대로 썼다. Space Grotesk 폰트 파일과 라이선스 파일도 사용자가 넣었다.
  - 스타일, 위젯 변경, Pretendard 다운로드, 테스트, 커밋은 AI가 했다.
  - 사용자 요청으로 Pretendard Medium을 뺐다.

## 🧩 이슈 · 해결

- 사용자가 넣은 라이선스 파일 이름이 `OFL.txt`였다. 등록한 경로와 달라서 AI가 확인한 뒤 `OFL-SpaceGrotesk.txt`로 바꿨다.
- `build/unit_test_assets`에 예전 에셋이 남아 테스트가 새 폰트를 못 찾았다. 그 폴더를 지워서 해결했다.
- `flutter run --release`에는 hot reload·restart가 없어서, 폰트를 바꾼 뒤에는 다시 빌드해야 한다고 안내했다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 이 커밋 단독으로 `flutter analyze`(error·warning 0)와 `flutter test`를 돌렸다. 이전부터 있던 About 넘침 테스트 2개만 실패했다.
- SpaceGrotesk Medium(500)은 등록만 돼 있고 쓰는 곳이 없다(리뷰 LOW, 아직 그대로).
- 실기기에서 한글 곡명 표시는 사용자가 확인하기로 했다.
