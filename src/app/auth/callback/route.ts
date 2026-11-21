import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

// Microsoft 로그인 후 돌아오는 곳: code를 세션으로 바꿈
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next')
  const safeNext = next?.startsWith('/') && !next.startsWith('//') ? next : '/'

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) return NextResponse.redirect(`${origin}${safeNext}`)
  }

  // 회사 도메인이 아니면 가입 훅이 막아서 여기로 옴
  const reason = searchParams.get('error_description') ?? '로그인하지 못했어요.'
  return NextResponse.redirect(`${origin}/login?error=${encodeURIComponent(reason)}`)
}
