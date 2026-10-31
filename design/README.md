# MP3 in ma pocket — Design (Soft Keys)

선택한 방향: **Key screens — Soft Keys** (02S · 03S · 04S/05S · 08S, 라이트/다크).

## 폴더 구성

```
design/
  README.md          ← 이 문서 (원칙, 화면, 컴포넌트 규칙)
  tokens.json        ← 색·폰트·간격·라운드·그림자·모션 토큰 (Figma 변수 입력용)
assets/
  fonts/             ← DotGothic16, Galmuri11, JetBrains Mono (모두 OFL-1.1)
  licenses/          ← 폰트 라이선스 원문 (앱의 Open Source Licenses에 자동 등록)
lib/
  main.dart          ← 지금은 디자인 프리뷰 앱을 실행
  app/
    library_controller.dart ← 곡 목록 상태: 가져오기(F1)·복귀 시 새로 읽기(F2)·삭제(F5)
  library/
    mp3_library.dart  ← 앱 폴더(Documents)의 mp3 읽기·복사(F3 번호 붙이기)·삭제
    mp3_sniff.dart    ← 가져올 때 실제 mp3인지 확인(ID3 태그, 또는 MPEG 프레임 두 개 연속)
    title_order.dart  ← F4 정렬: 대소문자 무시, 숫자는 크기순, 맥에서 온 한글(NFD)도 같이 정렬
  playback/
    audio_engine.dart       ← AudioEngine 인터페이스 + JustAudioEngine(just_audio, 오디오 세션 music)
    playback_controller.dart← 재생 상태: 목록 순서 재생(F6)·이전 3초 규칙(F7)·목록 변경 시 끊김 없이 큐 수정
    playback_settings.dart  ← 셔플·반복 저장(F12, shared_preferences)
  design/
    tokens.dart      ← SoftColors(ThemeExtension, light/dark), SoftSpace, SoftRadius, SoftMotion, SoftShadows
    typography.dart  ← SoftFonts, SoftText
    theme.dart       ← buildSoftTheme(Brightness)
    licenses.dart    ← 폰트 라이선스 등록
    design_preview.dart ← 앱 루트: 실제 목록 + 실제 재생을 화면에 연결
    widgets/
      soft_surface.dart   ← InsetShadowPainter, SoftSurface, SoftWell, SoftPanel, LcdPanel, SoftLed
      soft_key.dart       ← SoftKeyFace, SoftKey, SoftSocketKey, SoftPillButton
      soft_header.dart    ← SoftHeader, SoftInfoGlyph
      track_row.dart      ← TrackRow, TrackDeleteBackground, TrackListPanel
      player_controls.dart← SoftTransport, SoftSeekBar, SoftShuffleSwitch, SoftRepeatSelector, SoftMiniPlayer
    screens/
      empty_library_screen.dart  (02S)
      library_screen.dart        (03S)
      now_playing_screen.dart    (04S / 05S)
      about_screen.dart          (08S)
test/
  design_screens_test.dart  ← 라이트/다크 렌더링, 첫 실행 → 가져오기 흐름
  library_refresh_test.dart ← F2 복귀 시 새로 읽기, 읽기 겹침, F4 첫 화면 전환
  mp3_library_test.dart     ← 가져오기·번호 붙이기·삭제
  mp3_sniff_test.dart       ← 이름만 바꾼 PDF·AAC 거부, 앞에 헤더가 붙은 mp3 허용
  title_order_test.dart     ← F4 정렬 순서
  playback_controller_test.dart ← F6·F7, 재생 중 목록 변경
  audio_engine_test.dart    ← 다음/이전 곡 계산(셔플, 반복 끄기/전체/한 곡)
  fake_audio_engine.dart    ← 테스트용 가짜 AudioEngine
  playback_settings_test.dart ← F12 재실행 후 복원, 불러오는 중 바꾼 값 우선
  flutter_test_config.dart  ← 모든 테스트가 빈 메모리 설정으로 시작
  test_helpers.dart         ← 테스트 공용 도우미
```

## 실행

```bash
flutter pub get
flutter run            # 디자인 프리뷰 (빈 화면 → Import → Library → Now Playing / About)
flutter test           # 화면 렌더링 테스트
```

다크 모드는 시뮬레이터/기기 설정을 따릅니다(`ThemeMode.system`).

## 디자인 원칙

1. **목록은 조용하게, 재생은 특별하게** — Library는 평평한 리스트, Now Playing만 '기기'.
2. **오렌지는 살아있는 것에만** — 재생/일시정지, Import, 진행 바, LED on. 오렌지 위 글자는 흰색이 아닌 잉크(#16181A).
3. **도트 폰트는 LCD 안에서만** — 목록 가독성을 지키는 경계선.
4. **누르면 반응한다** — 키는 1px 내려앉고 그림자가 안으로, 가벼운 햅틱(90ms).
5. **사용자가 붙인 이름 존중** — 파일명 그대로, `.mp3`만 숨김, 파일 앱과 같은 순서(알파벳순, 숫자는 크기순).
6. **투명함 = 프라이버시** — "Your files never leave this phone."
7. **광고 자리를 비워둠** — v2 배너(50pt)는 미니 플레이어 위. Now Playing·빈 화면엔 없음.

## 화면

| ID | 화면 | 핵심 |
|---|---|---|
| 02S | First run | 앱 이름 헤더 + ⓘ. 빈 기기(NO TRACKS) + 비활성 재생 키. 유일한 입구는 Import MP3s (+ 버튼 없음) |
| 03S | Library | ⓘ + `LIBRARY · N` 헤더 + 오렌지 +. 평평한 리스트(52pt 행), 재생 중 행은 눌린 듯 + 오렌지 LED. 왼쪽으로 조금 밀면 Delete 버튼이 열린 채 멈추고, 버튼을 누르거나 끝까지 밀면 액션 시트로 확인 후 삭제(`flutter_slidable`). VoiceOver는 행 동작의 Delete. 하단 플로팅 미니 플레이어 |
| 04S/05S | Now Playing | 아래로 끌어 닫기. LCD(트랙 번호, 제목, 셔플/반복 상태) → 탐색 바 → 이전/재생/다음 캡슐 → 셔플 스위치 + 반복 3단(OFF/ALL/ONE) |
| 08S | About | LCD SYS INFO, 프라이버시 문구, Privacy Policy(외부 브라우저), Open Source Licenses(`showLicensePage`), Version |

## 컴포넌트 규칙

- **SoftWell(홈) + SoftKeyFace(볼록 키)** 조합이 기본 단위. 여러 키가 한 홈을 공유하면 `SoftWell` + `SoftKey`, 키 하나에 홈 하나면 `SoftSocketKey`.
- **터치 영역 44pt 이상** — 작은 ⓘ 키(홈 38 / 키 28)도 `SoftSocketKey`가 44pt 히트 영역을 확보.
- **상태는 색만으로 표시하지 않음** — 셔플/반복은 위치 + LED + 텍스트.
- **안쪽 그림자** — Flutter `BoxShadow`엔 inset이 없어서 `InsetShadowPainter`로 그림. 그림자 값 조정은 `SoftShadows`에서만.
- **한글 파일명** — LCD 폰트 DotGothic16에는 한글이 없어서 `Galmuri11`이 폴백으로 지정됨. LCD 바깥 텍스트는 시스템 폰트.

## 실제 앱에 연결할 때

화면 위젯은 값과 콜백만 받습니다. 목록은 `LibraryController`, 재생은 `PlaybackController`(just_audio)에 연결돼 있고, 셔플·반복은 `PlaybackSettings`(shared_preferences)에 저장됩니다. 남은 연결:

- 잠금화면·제어센터(F9): `just_audio_background`
- 앱 버전: `package_info_plus`
- 개인정보 처리방침 열기: `url_launcher` (URL은 PRD 미결 사항)
- 화면 문구: 다국어 대비 ARB(`flutter_localizations` + `intl`)로 분리

## 아직 정하지 않은 것

- 개인정보 처리방침 URL
- 앱 아이콘 (방향: 클리어/소프트 바디 + LCD "MP3" + 오렌지 키)
- 실기기에서 그림자·햅틱 세기 미세조정
