'use client'

import { useSearchParams } from 'next/navigation'
import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'

export function LoginPanel() {
  const params = useSearchParams()
  const error = params.get('error')
  const next = params.get('next') ?? '/'
  const [pending, setPending] = useState(false)

  async function signInWithMicrosoft() {
    setPending(true)
    const supabase = createClient()
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'azure',
      options: {
        scopes: 'email offline_access',
        redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`
      }
    })
    if (error) setPending(false)
  }

  return (
    <div className="flex flex-col gap-3">
      {error && (
        <p role="alert" className="text-caption text-danger text-center">
          {error}
        </p>
      )}
      <button
        type="button"
        onClick={signInWithMicrosoft}
        disabled={pending}
        className="focus-ring flex h-12 w-full items-center justify-center gap-2.5 rounded-sm bg-surface text-body-lg font-bold shadow-[inset_0_0_0_1px_var(--color-border)] transition-colors duration-base ease-out hover:bg-bg-row-hover disabled:text-text-muted"
      >
        {/* Microsoft 공식 로고 자리: 브랜드 가이드 파일을 public/brand/에 넣고 교체 */}
        <span
          aria-hidden
          className="size-5 rounded-[4px] bg-bg-page shadow-[inset_0_0_0_1px_var(--color-border)]"
        />
        {pending ? 'Microsoft로 이동 중…' : 'Microsoft 계정으로 계속하기'}
      </button>
      <p className="text-caption text-text-muted text-center">
        회사 이메일 계정만 들어올 수 있어요
      </p>
    </div>
  )
}
