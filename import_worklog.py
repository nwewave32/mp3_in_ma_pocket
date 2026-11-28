#!/usr/bin/env python3
"""
작업 기록 md 파일 → 노션 '작업 기록' 데이터베이스 업로드 스크립트

사용법:
    export NOTION_TOKEN=ntn_xxxxxxxx         # 내부 통합 토큰
    python3 import_worklog.py docs/worklog/   # 폴더 안의 새 md 파일만 업로드
    python3 import_worklog.py a.md b.md       # 파일 지정도 가능
    python3 import_worklog.py docs/worklog/ --dry-run   # 올리지 않고 확인만
    python3 import_worklog.py docs/worklog/ --force     # 내용이 안 바뀐 파일도 다시 덮어씀

이미 올린 파일을 수정하면 자동으로 감지해서 기존 노션 페이지를 덮어씁니다 (중복 생성 없음).

md 파일 형식 (프론트매터 + 본문):
    ---
    제목: 로그인 API 리프레시 토큰 추가
    작업 날짜: 2026-11-07
    프로젝트: 쇼핑몰 리뉴얼          # '개발 프로젝트' DB의 페이지 이름과 정확히 일치
    작업 유형: 기능 개발
    상태: 완료
    사용 AI: Claude Code, Cursor
    관련 PR / 이슈: https://github.com/...
    핵심 키워드: API, 인증
    소요 시간(h): 2.5
    커밋: a1b2c3d
    ---
    ## 🎯 요청 / 배경
    ...

업로드한 파일은 .notion_imported.json 에 기록되어 다음 실행 때 건너뜁니다.
"""

import argparse
import hashlib
import json as _json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

# 표준 라이브러리만 사용 — 별도 패키지 설치 불필요

# ──────────────────────────────────────────────
# 설정
# ──────────────────────────────────────────────
WORKLOG_DATA_SOURCE_ID = "c6dd6325-2d41-4fe3-a6d5-5dd725b839bf"   # 작업 기록
PROJECT_DATA_SOURCE_ID = "67036180-710b-4b12-8011-fe6a8834e27f"   # 개발 프로젝트
NOTION_VERSION = "2025-09-03"
STATE_FILE = ".notion_imported.json"

# 프론트매터 키 → (노션 속성 이름, 타입)
PROPERTY_MAP = {
    "제목":          ("제목", "title"),
    "작업 날짜":     ("작업 날짜", "date"),
    "프로젝트":      ("프로젝트", "relation"),
    "작업 유형":     ("작업 유형", "multi_select"),
    "상태":          ("상태", "status"),
    "사용 AI":       ("사용 AI", "multi_select"),
    "관련 PR / 이슈": ("관련 PR / 이슈", "url"),
    "핵심 키워드":   ("핵심 키워드", "multi_select"),
    "소요 시간(h)":  ("소요 시간(h)", "number"),
}

API = "https://api.notion.com/v1"


# ──────────────────────────────────────────────
# 노션 API
# ──────────────────────────────────────────────
class Notion:
    def __init__(self, token: str):
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Notion-Version": NOTION_VERSION,
            "Content-Type": "application/json",
        }
        self._project_cache: dict[str, dict | None] = {}

    def _req(self, method: str, path: str, json: dict | None = None, params: dict | None = None):
        url = f"{API}{path}"
        if params:
            url += "?" + urllib.parse.urlencode(params)
        data = _json.dumps(json).encode("utf-8") if json is not None else None
        req = urllib.request.Request(url, data=data, method=method, headers=self.headers)
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                body = r.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8", "replace")
            try:
                msg = _json.loads(body).get("message", body)
            except Exception:
                msg = body
            raise RuntimeError(f"Notion API {e.code}: {msg}")
        except urllib.error.URLError as e:
            raise RuntimeError(f"네트워크 오류: {e.reason}")
        return _json.loads(body) if body else {}

    def find_project(self, name: str) -> dict | None:
        """'개발 프로젝트' DB에서 이름이 일치하는 페이지를 찾는다."""
        if name in self._project_cache:
            return self._project_cache[name]
        res = self._req("POST", f"/data_sources/{PROJECT_DATA_SOURCE_ID}/query", json={
            "filter": {"property": "이름", "title": {"equals": name}},
            "page_size": 1,
        })
        results = res.get("results", [])
        page = results[0] if results else None
        self._project_cache[name] = page
        return page

    def create_project(self, name: str, start_date: str | None) -> dict:
        """'개발 프로젝트' DB에 새 프로젝트 페이지를 만든다."""
        props = {
            "이름": {"title": rt(name)},
            "상태": {"status": {"name": "진행 중"}},
        }
        if start_date:
            props["시작일"] = {"date": {"start": start_date}}
        page = self._req("POST", "/pages", json={
            "parent": {"type": "data_source_id", "data_source_id": PROJECT_DATA_SOURCE_ID},
            "properties": props,
        })
        self._project_cache[name] = page
        return page

    def touch_project(self, page: dict, work_date: str | None):
        """작업 기록이 추가된 프로젝트의 상태·시작일을 갱신한다.
        - 상태가 '아이디어'/'보류'면 '진행 중'으로
        - 시작일이 비어 있으면 작업 날짜로 채움
        """
        props = page.get("properties", {})
        patch: dict = {}
        status = (props.get("상태") or {}).get("status") or {}
        if status.get("name") in ("아이디어", "보류"):
            patch["상태"] = {"status": {"name": "진행 중"}}
        start = (props.get("시작일") or {}).get("date")
        if not start and work_date:
            patch["시작일"] = {"date": {"start": work_date}}
        if patch:
            updated = self._req("PATCH", f"/pages/{page['id']}", json={"properties": patch})
            self._project_cache[_title_of(updated)] = updated

    def _append(self, page_id: str, children: list[dict]):
        while children:
            chunk, children = children[:100], children[100:]
            self._req("PATCH", f"/blocks/{page_id}/children", json={"children": chunk})

    def create_page(self, properties: dict, children: list[dict]) -> tuple[str, str]:
        first, rest = children[:100], children[100:]
        page = self._req("POST", "/pages", json={
            "parent": {"type": "data_source_id", "data_source_id": WORKLOG_DATA_SOURCE_ID},
            "properties": properties,
            "children": first,
        })
        self._append(page["id"], rest)
        return page["id"], page["url"]

    def page_alive(self, page_id: str) -> bool:
        """페이지가 존재하고 삭제(휴지통)되지 않았는지 확인."""
        try:
            page = self._req("GET", f"/pages/{page_id}")
        except RuntimeError as e:
            if "404" in str(e):
                return False
            raise
        return not (page.get("archived") or page.get("in_trash"))

    def update_page(self, page_id: str, properties: dict, children: list[dict]) -> str:
        """기존 페이지의 속성을 갱신하고 본문을 전부 교체한다."""
        page = self._req("PATCH", f"/pages/{page_id}", json={"properties": properties})
        # 기존 본문 블록 삭제
        cursor = None
        while True:
            params = {"page_size": 100}
            if cursor:
                params["start_cursor"] = cursor
            res = self._req("GET", f"/blocks/{page_id}/children", params=params)
            for b in res.get("results", []):
                self._req("DELETE", f"/blocks/{b['id']}")
            if not res.get("has_more"):
                break
            cursor = res.get("next_cursor")
        self._append(page_id, children)
        return page["url"]


def _title_of(page: dict) -> str:
    t = (page.get("properties", {}).get("이름") or {}).get("title") or []
    return "".join(x.get("plain_text", "") for x in t)


# ──────────────────────────────────────────────
# 마크다운 파싱
# ──────────────────────────────────────────────
def parse_frontmatter(text: str) -> tuple[dict, str]:
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", text, re.S)
    if not m:
        return {}, text
    meta = {}
    for line in m.group(1).splitlines():
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        meta[k.strip()] = v.strip()
    return meta, m.group(2)


def rt(text: str) -> list[dict]:
    """plain text → rich_text (2000자 제한 분할, **굵게** 지원)."""
    out = []
    for part in re.split(r"(\*\*[^*]+\*\*)", text):
        if not part:
            continue
        bold = part.startswith("**") and part.endswith("**")
        content = part[2:-2] if bold else part
        for i in range(0, len(content), 2000):
            seg = {"type": "text", "text": {"content": content[i:i + 2000]}}
            if bold:
                seg["annotations"] = {"bold": True}
            out.append(seg)
    return out or [{"type": "text", "text": {"content": ""}}]


def md_to_blocks(body: str) -> list[dict]:
    blocks: list[dict] = []
    lines = body.splitlines()
    i = 0
    para: list[str] = []

    def flush_para():
        nonlocal para
        if para:
            blocks.append({"object": "block", "type": "paragraph",
                           "paragraph": {"rich_text": rt(" ".join(para))}})
            para = []

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # 코드 블록
        if stripped.startswith("```"):
            flush_para()
            lang = stripped[3:].strip() or "plain text"
            code = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            blocks.append({"object": "block", "type": "code",
                           "code": {"rich_text": rt("\n".join(code)), "language": lang}})
            i += 1
            continue

        if not stripped:
            flush_para()
            i += 1
            continue

        m = re.match(r"^(#{1,3})\s+(.*)", stripped)
        if m:
            flush_para()
            level = len(m.group(1))
            blocks.append({"object": "block", "type": f"heading_{level}",
                           f"heading_{level}": {"rich_text": rt(m.group(2))}})
            i += 1
            continue

        m = re.match(r"^[-*]\s+\[([ xX])\]\s*(.*)", stripped)
        if m:
            flush_para()
            blocks.append({"object": "block", "type": "to_do",
                           "to_do": {"rich_text": rt(m.group(2)),
                                     "checked": m.group(1).lower() == "x"}})
            i += 1
            continue

        m = re.match(r"^[-*]\s+(.*)", stripped)
        if m:
            flush_para()
            blocks.append({"object": "block", "type": "bulleted_list_item",
                           "bulleted_list_item": {"rich_text": rt(m.group(1))}})
            i += 1
            continue

        m = re.match(r"^\d+\.\s+(.*)", stripped)
        if m:
            flush_para()
            blocks.append({"object": "block", "type": "numbered_list_item",
                           "numbered_list_item": {"rich_text": rt(m.group(1))}})
            i += 1
            continue

        if stripped.startswith(">"):
            flush_para()
            blocks.append({"object": "block", "type": "quote",
                           "quote": {"rich_text": rt(stripped.lstrip("> ").strip())}})
            i += 1
            continue

        para.append(stripped)
        i += 1

    flush_para()
    return blocks


# ──────────────────────────────────────────────
# 속성 변환
# ──────────────────────────────────────────────
def split_list(v: str) -> list[str]:
    return [x.strip() for x in re.split(r"[,，]", v) if x.strip()]


def build_properties(meta: dict, fallback_title: str, notion: Notion,
                     auto_create: bool = True) -> tuple[dict, list[str], dict | None]:
    """노션 속성 dict, 경고 목록, 연결된 프로젝트 페이지(없으면 None)를 돌려준다."""
    props: dict = {}
    warnings: list[str] = []
    project_page: dict | None = None

    title = meta.get("제목") or fallback_title
    props["제목"] = {"title": rt(title)}

    for key, (prop, ptype) in PROPERTY_MAP.items():
        if key == "제목":
            continue
        v = meta.get(key, "").strip()
        if not v:
            continue
        if ptype == "date":
            props[prop] = {"date": {"start": v}}
        elif ptype == "select":
            props[prop] = {"select": {"name": v}}
        elif ptype == "status":
            props[prop] = {"status": {"name": v}}
        elif ptype == "multi_select":
            props[prop] = {"multi_select": [{"name": x} for x in split_list(v)]}
        elif ptype == "url":
            props[prop] = {"url": v}
        elif ptype == "number":
            try:
                props[prop] = {"number": float(v)}
            except ValueError:
                warnings.append(f"소요 시간(h) 값이 숫자가 아님: {v!r}")
        elif ptype == "relation":
            project_page = notion.find_project(v)
            if not project_page and auto_create:
                project_page = notion.create_project(v, meta.get("작업 날짜") or None)
                warnings.append(f"프로젝트 '{v}' 가 없어 '개발 프로젝트' DB에 새로 만듦 (종류·기술 스택은 노션에서 채워주세요)")
            if project_page:
                props[prop] = {"relation": [{"id": project_page["id"]}]}
            else:
                warnings.append(f"프로젝트 '{v}' 를 '개발 프로젝트' DB에서 찾지 못함 (연결 생략)")
    return props, warnings, project_page


# ──────────────────────────────────────────────
# 메인
# ──────────────────────────────────────────────
def collect_files(paths: list[str]) -> list[Path]:
    files: list[Path] = []
    for p in paths:
        path = Path(p)
        if path.is_dir():
            files += sorted(path.glob("*.md"))
        elif path.suffix == ".md":
            files.append(path)
    return files


def main():
    ap = argparse.ArgumentParser(description="작업 기록 md → 노션 업로드")
    ap.add_argument("paths", nargs="+", help="md 파일 또는 폴더")
    ap.add_argument("--dry-run", action="store_true", help="업로드하지 않고 파싱 결과만 출력")
    ap.add_argument("--force", action="store_true", help="내용이 안 바뀐 파일도 다시 덮어씀")
    ap.add_argument("--no-create-project", action="store_true",
                    help="프로젝트가 '개발 프로젝트' DB에 없어도 자동 생성하지 않음")
    args = ap.parse_args()

    token = os.environ.get("NOTION_TOKEN")
    if not token and not args.dry_run:
        sys.exit("NOTION_TOKEN 환경변수를 설정하세요.")

    state_path = Path(STATE_FILE)
    state = _json.loads(state_path.read_text()) if state_path.exists() else {}

    files = collect_files(args.paths)
    if not files:
        sys.exit("md 파일을 찾지 못했습니다.")

    notion = Notion(token) if token else None
    created = updated = skipped = failed = 0

    for f in files:
        # 키는 파일명만 사용 → 저장소 폴더를 옮기거나 이름을 바꿔도 기록이 유지됨
        key = f.name
        text = f.read_text(encoding="utf-8")
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()

        prev = state.get(key)
        # 이전 버전 state(키가 절대경로)에서 같은 파일명을 찾아 이전
        if prev is None:
            for old_key in [k for k in state if "/" in k or "\\" in k]:
                if Path(old_key).name == key:
                    prev = state.pop(old_key)
                    break
        # 이전 버전 state(값이 URL 문자열)도 읽을 수 있게 변환
        if isinstance(prev, str):
            # URL 맨 끝의 32자리 hex가 페이지 ID (앞쪽 슬러그에 hex가 섞일 수 있음)
            m = re.search(r"([0-9a-f]{32})(?:[?#].*)?$", prev.split("/")[-1].replace("-", ""))
            prev = {"url": prev, "id": m.group(1) if m else None, "hash": None}

        if prev and prev.get("hash") == digest and not args.force:
            skipped += 1
            continue

        meta, body = parse_frontmatter(text)
        fallback_title = re.sub(r"^\d{4}-\d{2}-\d{2}_[0-9a-f]{7}_", "", f.stem).replace("-", " ")

        if args.dry_run:
            action = "덮어쓰기" if prev else "신규"
            print(f"\n=== {f.name}  [{action}]")
            print("  제목:", meta.get("제목") or fallback_title)
            for k in PROPERTY_MAP:
                if k != "제목" and meta.get(k):
                    print(f"  {k}: {meta[k]}")
            print(f"  본문 블록: {len(md_to_blocks(body))}개")
            continue

        try:
            props, warns, project_page = build_properties(
                meta, fallback_title, notion, auto_create=not args.no_create_project)
            blocks = md_to_blocks(body)
            if meta.get("커밋"):
                blocks.insert(0, {"object": "block", "type": "callout",
                                  "callout": {"rich_text": rt(f"커밋: {meta['커밋']}"),
                                              "icon": {"type": "emoji", "emoji": "🔖"}}})
            if prev and prev.get("id") and not notion.page_alive(prev["id"]):
                print(f"  ℹ {f.name}: 기존 노션 페이지가 삭제됐거나 없음 → 새로 만듦")
                prev = None
            if prev and prev.get("id"):
                url = notion.update_page(prev["id"], props, blocks)
                page_id = prev["id"]
                updated += 1
                print(f"↻ {f.name} (덮어씀)")
            else:
                page_id, url = notion.create_page(props, blocks)
                created += 1
                print(f"✓ {f.name}")
            state[key] = {"id": page_id, "url": url, "hash": digest}
            state_path.write_text(_json.dumps(state, ensure_ascii=False, indent=2))
            if project_page:
                notion.touch_project(project_page, meta.get("작업 날짜") or None)
            for w in warns:
                print(f"    ⚠ {w}")
        except Exception as e:
            failed += 1
            print(f"✗ {f.name}: {e}")

    if not args.dry_run:
        print(f"\n완료: 신규 {created}개, 덮어씀 {updated}개, 변경 없음 {skipped}개, 실패 {failed}개")


if __name__ == "__main__":
    main()
