import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { env } from '@/lib/env'

// 서버 컴포넌트·Route Handler용
export async function createClient() {
  const cookieStore = await cookies()
  return createServerClient(env.supabaseUrl, env.supabasePublishableKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll()
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options)
          }
        } catch {
          // 서버 컴포넌트에서 호출되면 쿠키를 쓸 수 없음. proxy가 세션을 갱신하므로 무시.
        }
      }
    }
  })
}
