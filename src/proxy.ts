import type { NextRequest } from 'next/server'
import { updateSession } from '@/lib/supabase/proxy'

export async function proxy(request: NextRequest) {
  return updateSession(request)
}

export const config = {
  matcher: [
    // 정적 파일, 이미지, 아이콘, robots는 제외
    '/((?!_next/static|_next/image|icon.svg|robots.txt|.*\\.(?:svg|png|jpg|jpeg|gif|webp|woff2)$).*)'
  ]
}
