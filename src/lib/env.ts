// 공개 환경변수. 없으면 바로 알 수 있게 에러를 낸다.
// Next.js는 process.env.NEXT_PUBLIC_* 를 빌드 때 그대로 치환하므로 동적 접근(process.env[key])은 쓰지 않는다.
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
const supabasePublishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabasePublishableKey) {
  throw new Error(
    'NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY를 .env.local에 넣어주세요.'
  )
}

export const env = { supabaseUrl, supabasePublishableKey }
