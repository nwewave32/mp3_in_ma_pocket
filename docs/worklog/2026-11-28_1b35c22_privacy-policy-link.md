---
제목: About 화면에서 개인정보 처리방침 열기
작업 날짜: 2026-11-28
프로젝트: pocket.mp3
작업 유형: 기능 개발
상태: 완료
사용 AI: Claude Code (Claude Opus 5.5)
관련 PR / 이슈:
핵심 키워드: UI
소요 시간(h):
커밋: 1b35c22
---

## 🎯 요청 / 배경

About › Privacy Policy 항목을 눌러도 아무 일이 없었다. 사용자의 법률 문서 사이트(`https://ireuisu-legal.vercel.app/앱이름/privacy/`)를 열도록 연결했다.

## 🔧 한 일

- `pubspec.yaml`, `pubspec.lock`: `url_launcher: ^6.3.3` 추가
- `lib/app/legal.dart` 새로 작성: `legalSlug`(이 커밋에서는 앱 이름이 미정이라 null), `privacyPolicyUrl()`
- `lib/design/design_preview.dart`
  - `DesignPreviewApp`에 `openUrl`, `privacyPolicy` 매개변수 추가 (테스트에서 바꿔 끼울 수 있게)
  - `_openInBrowser`: `launchUrl(url, mode: LaunchMode.externalApplication)`
  - `_Home._openPrivacyPolicy`: 열지 못하면(false 반환 또는 예외) "Couldn't open the privacy policy." 스낵바를 띄운다.
- `test/privacy_policy_test.dart` 새로 작성: URL 형식, 누르면 열림, 브라우저가 거부할 때와 예외를 던질 때

## 🤖 AI 활용

- 시킨 것:
  - "3. https://ireuisu-legal.vercel.app/앱이름/privacy/ 이게 개인정보 처리방침 버튼 연결 링크야 앱 이름 확정하고 넣으면 돼"
  - 앱 이름 질문에 "이건 더 얘기하고 결정하자"
  - "테스트의 예외 무시 수정해줘"
  - "작업별로 나눠서 커밋해줘"
- 그대로 쓴 부분 / 고친 부분:
  - 구현, 테스트, 커밋은 AI가 했다.
  - 앱 이름은 사용자가 나중에 정하기로 해서, 경로는 비워 두었다(커밋 0c77b6f에서 `pocket-mp3`로 채움).
  - 첫 리뷰에서 테스트가 예외를 넓게 무시하는 문제가 나왔고, 사용자 요청으로 고쳤다. 이 커밋에서는 About 화면의 알려진 넘침 오류만 허용한다.
  - 세션 기록에는 사용자가 코드를 직접 고친 흔적이 없다.

## 🧩 이슈 · 해결

- 실패 경우를 반복문 하나에서 테스트했더니 About 화면이 열린 채 앱을 다시 그려서 꼬였다. 경우마다 테스트를 나눠서 해결했다.

## ✅ 검증

- [x]  로컬 테스트
- [ ]  PR 올림 / 리뷰 요청
- [ ]  클라이언트 확인

## 💬 메모

- 이 커밋 단독으로 `flutter analyze`(error·warning 0)와 `flutter test`를 돌렸다. 이전부터 있던 About 넘침 테스트 2개만 실패했다.
- 실기기에서 브라우저가 열리는지는 아직 확인하지 않았다.
