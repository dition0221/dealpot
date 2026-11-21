# dealpot (딜팟)

### 회사 동료끼리 네이버페이·카카오페이·저가 커피 같은 핫딜을 올리고, 누가 올리든 다 같이 바로 보는 사내 핫딜 게시판

Web : <img src="https://img.shields.io/badge/Next.js-000?style=flat-square&logo=nextdotjs&logoColor=white"/> <img src="https://img.shields.io/badge/React-61DAFB?style=flat-square&logo=react&logoColor=white"/> <img src="https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white"/> <img src="https://img.shields.io/badge/Tailwind CSS-06B6D4?style=flat-square&logo=tailwindcss&logoColor=white"/> <img src="https://img.shields.io/badge/TanStack Query-FF4154?style=flat-square&logo=reactquery&logoColor=white"/> <img src="https://img.shields.io/badge/Motion-000?style=flat-square&logoColor=white"/>  
Backend : <img src="https://img.shields.io/badge/Supabase-3FCF8E?style=flat-square&logo=supabase&logoColor=white"/> <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white"/> <img src="https://img.shields.io/badge/Microsoft Entra ID-0078D4?style=flat-square&logoColor=white"/>  
Tooling : <img src="https://img.shields.io/badge/Node.js-339933?style=flat-square&logo=nodedotjs&logoColor=white"/> <img src="https://img.shields.io/badge/pnpm-F69220?style=flat-square&logo=pnpm&logoColor=white"/> <img src="https://img.shields.io/badge/Biome-60A5FA?style=flat-square&logo=biome&logoColor=white"/>  
Deploy : <img src="https://img.shields.io/badge/Vercel-000?style=flat-square&logo=vercel&logoColor=white"/>

> 🚧 개발 초기 단계 — 프로젝트 뼈대와 로그인 흐름까지 완료

<!-- TODO: 피드 완성 후 스크린샷 추가 -->

---

## 무엇을 하는 앱인가

- **피드**: 동료가 올린 딜을 `오늘 마감 / 내일 마감 / 진행 중`으로 묶어 보여준다. 리스트와 달력으로 바꿔 볼 수 있다.
- **딜 올리기**: 링크를 붙이면 제목과 썸네일을 자동으로 채운다. 장르(커피·편의점 등)와 결제수단(네이버페이·카카오페이 등)을 고른다.
- **씀 체크**: 내가 이미 쓴 딜을 체크하면 묶음 맨 뒤로 내려가고 흐리게 보인다. 체크는 나만 본다.
- **반응**: 좋아요, 댓글(답글 1단계). 새 딜과 댓글은 새로고침 없이 바로 보인다.
- **로그인**: 회사 Microsoft 계정으로 로그인. 회사 이메일 도메인이 아니면 가입 자체를 막는다.

## 기술 스택

| 영역          | 사용 기술                                                                                 |
| ------------- | ----------------------------------------------------------------------------------------- |
| 웹            | Next.js 16 (App Router, `proxy.ts`), React 19, TypeScript                                 |
| UI            | Tailwind CSS v4 (디자인 토큰은 `@theme`), motion, lucide-react, Pretendard                |
| 상태 / 데이터 | TanStack Query (Supabase 조회·캐시), Supabase Realtime (새 딜·댓글 구독)                  |
| 백엔드        | Supabase — PostgreSQL + RLS, Auth (Azure 제공자), Storage. 별도 백엔드 서버 없음          |
| 인증          | Microsoft Entra ID 소셜 로그인 + Supabase Before User Created 훅으로 회사 도메인만 허용   |
| 개발 도구     | pnpm, Biome (린트 + 포맷)                                                                 |
| 배포          | Vercel Hobby (비상업 개인 프로젝트)                                                       |

## 개발

**필요 환경**: Node.js 24+, pnpm 10

```bash
pnpm install
cp .env.example .env.local   # Supabase URL, Publishable key 입력
pnpm dev
```

| 명령             | 설명                       |
| ---------------- | -------------------------- |
| `pnpm dev`       | 개발 서버                  |
| `pnpm build`     | 프로덕션 빌드              |
| `pnpm lint`      | Biome 린트·포맷 검사       |
| `pnpm lint:fix`  | Biome 자동 수정            |
| `pnpm typecheck` | 타입 검사                  |

## 설정

### 1. Supabase

1. 프로젝트를 만들고 Project Settings > API의 URL과 Publishable key를 `.env.local`에 넣는다.
2. SQL Editor에서 `supabase/migrations/20261121000000_init.sql`을 실행한다 (또는 `supabase db push`).
3. 회사 도메인을 등록한다. **도메인은 코드에 남기지 않는다.**
   ```sql
   insert into private.allowed_email_domains (domain) values ('회사도메인.com');
   ```
4. Authentication > Hooks > **Before User Created** → Postgres function `public.hook_before_user_created`.
5. Authentication > URL Configuration > Redirect URLs에 추가:
   - `http://localhost:3000/auth/callback`
   - `https://<배포 도메인>/auth/callback`

### 2. Microsoft 로그인 (Azure)

개인 Azure 계정으로 등록한다. 회사 테넌트에 등록하지 않는다.

1. Microsoft Entra ID > App registrations > New registration
2. Redirect URI (Web): `https://<프로젝트>.supabase.co/auth/v1/callback`
3. Certificates & secrets > New client secret → **Value** 복사
4. Supabase Authentication > Sign In / Providers > **Azure**에 Client ID와 Secret 입력

> 회사 계정으로 처음 로그인할 때 "관리자 승인 필요"가 뜨면 회사 IT의 앱 동의 정책 때문이다. IT에 승인을 요청하거나, 이메일 인증코드 로그인으로 바꾼다.

## 구조

```
dealpot/
├─ src/
│  ├─ proxy.ts              # 로그인 안 했으면 /login으로 보냄 (Next 16의 middleware)
│  ├─ app/
│  │  ├─ page.tsx           # 피드
│  │  ├─ login/             # Microsoft 로그인
│  │  ├─ auth/callback/     # 로그인 후 세션 교환
│  │  ├─ globals.css        # 디자인 토큰 (@theme)
│  │  └─ robots.ts          # 검색 노출 차단
│  ├─ components/           # 공용 컴포넌트
│  └─ lib/
│     ├─ env.ts             # 환경변수 검사
│     └─ supabase/          # 브라우저·서버·proxy 클라이언트
└─ supabase/
   └─ migrations/           # DB 스키마 + RLS
```

### 화면 (예정)

| 경로             | 화면                       |
| ---------------- | -------------------------- |
| `/login`         | Microsoft 로그인           |
| `/onboarding`    | 첫 로그인 닉네임 설정      |
| `/`              | 피드 (리스트 / 달력)       |
| `/deals/new`     | 딜 올리기                  |
| `/deals/[id]`    | 딜 상세 + 댓글             |
| `/deals/archive` | 지난 딜                    |
| `/my`            | 내 정보                    |
| `/admin`         | 장르·결제수단 관리         |

## 디자인 규칙

- 색은 의미 토큰만 쓴다: `bg-bg-page`, `bg-surface`, `text-text-muted`, `text-accent`, `text-danger` … (스케일 단계 직접 사용 금지, 다크 테마 대비)
- 글자 5단계(짝수): `text-caption` 12 · `text-body` 14 · `text-body-lg` 16 · `text-heading` 20 · `text-display` 24, 굵기 400 / 600
- 반경 `rounded-sm` 6 · `rounded-lg` 12 · 원, 아이콘 16 / 24, 트랜지션 `duration-fast` 150 · `duration-base` 200
- margin 대신 `gap` / `padding`, 포커스는 `focus-ring`, 터치 영역 44px 이상

## 브랜치 전략

- `main` — 배포 가능한 안정 버전 (Vercel 프로덕션)
- `develop` — 개발 기본 브랜치 (default)
- `feature/*` — 기능 단위 작업 후 `develop`으로 PR

## 안내

- 사내 동료끼리 쓰는 **비상업 개인 프로젝트**이며 회사와 무관하다.
- 네이버페이·카카오페이·토스페이·Microsoft의 이름과 로고는 각 회사의 상표다. 이 저장소에는 로고 파일을 포함하지 않는다.

## License

[MIT](./LICENSE)
