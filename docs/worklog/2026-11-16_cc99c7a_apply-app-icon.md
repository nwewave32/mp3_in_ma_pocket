---
제목: Mixtape Pocket 앱 아이콘 적용
작업 날짜: 2026-11-16
프로젝트: MP3 in ma pocket
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI
소요 시간(h):
커밋: cc99c7a
---

## 🎯 요청 / 배경

시안 커밋(`e6b14c3`) 뒤에도 앱에는 Flutter 기본 아이콘이 들어 있었다. 사용자가 Mixtape Pocket을 최종으로 정해서 앱에 적용했다.

## 🔧 한 일

- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
  - Flutter 기본 아이콘 PNG 16장 삭제
  - `design/app-icon/AppIcon.appiconset/`의 `AppIcon-1024.png`, `AppIcon-1024-dark.png`, `AppIcon-1024-tinted.png`와 `Contents.json`으로 교체
- `MP3 in ma pocket — 프로젝트 노트.md`: "앱 아이콘 확정" 체크

## 🤖 AI 활용

- 시킨 것:
  - "아이콘은 왜 적용 안해?"
  - "응 그거 최종이야, 적용해줘"
  - "커밋하고 푸시해줘"
  - "변경사항에 남은건 뭐야 버려도 돼?"
- 그대로 쓴 부분 / 고친 부분:
  - 적용, 확인, 커밋, 푸시는 AI가 했다.
  - PRD 미결 사항 "앱 아이콘과 기본 색상"은 기본 색상까지 포함하는 항목이라 AI가 체크하지 않고 두었다.

## 🧩 이슈 · 해결

- 처음에 적용하지 않은 이유: 문서에 아직 시안으로 적혀 있었고, `Claude outputs/`의 같은 이름 파일 때문에 어느 쪽이 최종인지 알 수 없었다. 사용자가 최종이라고 확인해 준 뒤 적용했다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 1024 이미지 3장 모두 정사각형이고 투명 영역이 없어 앱스토어 조건에 맞는다.
- `flutter build ios --release --no-codesign` 성공. 빌드된 앱에 세 아이콘이 모두 들어간 것을 확인했다.
- 기기에서는 `flutter run --release`로 다시 설치해야 바뀐다. 예전 아이콘이 남아 있으면 기기를 재시동한다.
- `Claude outputs/` 폴더는 커밋하지 않았다. 안의 파일은 모두 커밋된 SVG와 같아서 지워도 잃는 것이 없다고 확인했다.
