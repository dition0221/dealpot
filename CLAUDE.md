# 프로젝트 개요

- 딜팟(dealpot) — 회사 동료끼리 핫딜(네이버페이·카카오페이·저가 커피 등)을 올리고 같이 보는 사내 게시판. 개인 FE 포트폴리오 겸 비상업 취미 프로젝트
- 스택: Next.js 16 (App Router) · React 19 · TypeScript · Tailwind v4 · Supabase · TanStack Query · Biome 2.6.2 · pnpm 10 · Node 24
- Next.js는 학습 데이터와 다르다 — 코드 쓰기 전에 `node_modules/next/dist/docs/`의 관련 가이드를 먼저 읽는다 ([AGENTS.md](AGENTS.md))
- `src/proxy.ts`가 예전 middleware다. `next.config`에 `cacheComponents: true`라 서버에서 `cookies()`·`searchParams`를 쓰는 부분은 Suspense로 감싼다
- 명령: `pnpm dev` / `pnpm lint` / `pnpm typecheck` / `pnpm build` — 작업을 마쳤다고 보고하기 전에 lint·typecheck·build를 통과시킨다
- DB 스키마는 `supabase/migrations/`가 기준이다. 보안은 RLS가 맡는다
- 회사 도메인·키는 코드·커밋·문서에 절대 넣지 않는다 (도메인은 DB `private.allowed_email_domains`, 키는 `.env.local`)

# 답변

- **간결하게**: 결론부터, 필요한 것만. 자명한 과정 설명·반복 요약·장황한 근거 나열은 빼고 표·목록은 꼭 필요할 때만 쓴다

# 코드 규칙

- 서식은 Biome가 맡는다: 작은따옴표, 세미콜론 없음, 줄 100자 — 손으로 맞추지 말고 `pnpm lint:fix`
- `src`의 `.ts`·`.tsx`는 `@/*` 별칭으로만 import한다 (상대경로 금지, Biome가 막는다)
- 파일명: 컴포넌트 `.tsx`는 PascalCase, 그 외는 camelCase (kebab-case 금지) — Next 특수 파일(`page`·`layout`·`route` 등)은 예외
- 데이터 조회는 브라우저 supabase-js + TanStack Query로 한다. 실시간은 Supabase Realtime 이벤트 → `invalidateQueries`
- Tailwind 클래스 문자열을 상수로 빼지 않는다. 반복되면 컴포넌트로 묶는다

# 주석 규칙

- **기본은 무주석**: 이름·구조로 의도를 드러낸다
- **한글 한 줄**, 코드만 봐선 알 수 없는 이유·함정만 단다. 2줄 주석 금지
- 코드를 옮겨 적은 설명, 동작을 문장으로 재서술하는 주석은 달지 않는다
- 변수·함수·타입 선언 바로 위는 JSDoc `/** ... */` 한 줄, 함수 본문 안은 `//`
- 한 문장이면 마침표 없이, 두 문장 이상일 때만 쓴다

# 디자인 시스템

토큰은 `src/app/globals.css`의 `@theme`에 있다. 아래를 반드시 지킨다.

## 색

- 의미 토큰만 쓴다: `bg-bg-page` · `bg-surface` · `text-text-primary/secondary/muted/used` · `text-accent` · `text-danger` · `bg-fill-cta` · `border-border` …
- 스케일(`primary-600` 등) 직접 사용 금지 — 다크 테마에서 깨진다
- 빨강(danger)은 '오늘' D-day 글자, 묶음 제목 앞 6px 점, 달력 마감 건수에만 쓴다

## 타이포 · 형태

- 글자 5단계(짝수): `text-caption` 12/16 · `text-body` 14/20 · `text-body-lg` 16/24 · `text-heading` 20/28 · `text-display` 24/32. 굵기는 400/600만. 폰트는 Pretendard
- 반경: `rounded-sm` 6(컨트롤·썸네일) · `rounded-lg` 12(묶음) · `rounded-full`. 그 외 금지
- 아이콘: lucide-react, `strokeWidth` 1.75, 크기는 16(글자 옆) / 24(단독)만. 이모지 아이콘 금지
- margin 금지 → gap·padding. 터치 영역 44px 이상(보이는 컨트롤 높이 36)

## 인터랙션

- 트랜지션: `duration-fast` 150(색) / `duration-base` 200(배경·이동), `ease-out`
- 포커스는 `focus-ring` 유틸(focus-visible만). 누를 수 있는 건 `cursor-pointer`
- 로딩은 스켈레톤 — 실제 레이아웃과 같은 모양 + pulse
- `motion/react`는 '씀' 체크 시 행 이동(layout), 실시간 새 딜, 바텀시트에만 쓴다. 진입 페이드업 금지

## AI 티 금지

- 카드마다 둥근 박스, 메타마다 알약, 그라데이션, 가운데 정렬 남발, 크림 배경

# 화면 스펙

## /login

- 심볼+딜팟, 하단에 "Microsoft 계정으로 계속하기"(주요), "회사 이메일로 인증코드 받기"(플랜B, 연한 버튼)

## /onboarding

- 첫 로그인 닉네임: 2~12자, 중복 불가, 30일 1회 변경
- MS 사진이 없으면 첫 글자 아바타 + 사진 올리기

## / 피드

- 헤더: 심볼+딜팟(→ `/`), 리스트/달력 세그먼트, 아바타(→ `/my`)
- 정렬 탭(최신/마감임박/좋아요, 밑줄). 필터는 왼쪽 고정 '결제 ▾'(바텀시트, 다중 OR) + 장르 칩 한 줄(단일)
- 묶음: 오늘 마감 / 내일 마감 / 진행 중 (모든 탭 공통). 묶음 안에서 내가 '씀' 체크한 딜은 맨 뒤 + 제목·가격만 `text-used`(투명도 X)
- 딜 행: `[씀 체크 24px 원(켜면 accent 채움 + 흰 체크)][썸네일 56(링크 없으면 장르 아이콘)][장르(accent 600) · 결제수단(12px 브랜드색 원+이름) / 제목 1줄 말줄임 / 가격 heading 600][D-day 위 · 하트·댓글 수 아래(0이면 숨김)]`
- 행 전체가 상세 링크(stretched link), 체크만 별도 버튼. hover `bg-row-hover`
- '씀' 체크 시 토스트 4초 "'<제목>'을 씀으로 표시했어요 / 되돌리기"
- 등록: 폰은 우측 하단 고정 확장형 버튼(잉크색, 높이 48, '+ 딜 올리기'), PC(≥900px)는 헤더 버튼. PC는 리스트(최대 720) + 오른쪽 미니 달력(오늘 표시, 마감 건수)
- 상태: 빈 피드 / 필터 결과 없음 / 불러오기 실패 / 오프라인 배너

## /deals/new

- 링크(선택, 붙이면 Route Handler로 OG 제목·이미지 가져옴), 제목*, 장르*(칩 단일), 결제수단(칩 다중), 혜택(할인율|가격|글자 중 하나), 마감일 또는 '상시'
- 하단 고정 '딜 올리기'. 제출 후 피드로 이동 + 새 딜 하이라이트

## /deals/[id]

- 큰 썸네일, 장르·결제·'오늘 마감', 제목(heading) < 혜택 숫자(display), 작성자·시간
- 버튼: '딜 보러 가기'(주요) + 좋아요 + 씀
- 댓글: 답글 1단계, 내 댓글만 삭제, 하단 고정 입력
- ⋯(수정/삭제)는 작성자·관리자만

## /my · /deals/archive · /admin

- /my: 프로필(사진 변경), 닉네임 변경, 내가 쓴 딜, 씀 기록, 알림 설정(준비 중), 로그아웃, 맨 아래 작은 '회원 탈퇴'. 탈퇴해도 글은 남고 작성자는 '탈퇴한 사용자'
- /deals/archive: 지난 딜
- /admin: 장르·결제수단 관리(관리자만)

# 커밋 형식

- **커밋·푸시는 사용자가 지시할 때만 한다**
- **제목**: 영어 conventional commits (ex. `feat(feed): add deal row`)
- **내용**: 영어, 간결한 bullet
- **분할**: 논리 단위로 나눠 커밋, 무관한 변경은 한 커밋에 묶지 않기

# 브랜치 · PR

- `main` 배포용(릴리스 태그) · `develop` 기본 · `feature/<이름>` 작업 후 `develop`으로 PR

## Feature 브랜치 → develop (squash merge)

- **제목**: 영어 (squash 커밋 제목이 된다. ex. `feat(feed): add deal row`)
- **내용**: 한글 변경 요약

## develop → main (릴리스, merge commit)

- **제목**: `Release/<버전>` (ex. `Release/v0.1.0`)
- **내용**: 이전 버전 태그와 비교한 변경사항 한글 릴리스 노트

# PR 머지 후

- **"PR 받았다"는 정리 신호**: 어느 쪽 머지인지 확인하고 아래 순서를 끝까지 돌린다
- **Feature → develop**: `develop`으로 이동 → pull → 머지된 로컬 브랜치 삭제. squash라서 `-d`가 안 먹으므로 `git branch -D`로 지운다
- **develop → main**: main의 머지 커밋에 `git tag -a v<버전>`을 달고 푸시 → `develop`으로 이동 → pull → `git merge --ff-only main` → push. ff가 안 되면 머지하지 말고 알린다
