'use client'

import Image from 'next/image'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

export function AppHeader() {
  const router = useRouter()

  async function signOut() {
    await createClient().auth.signOut()
    router.replace('/login')
  }

  return (
    <header className="sticky top-0 z-10 flex items-center justify-between bg-bg-page p-4">
      <Link href="/" className="focus-ring flex min-h-11 items-center gap-2 rounded-sm">
        <Image src="/icon.svg" alt="" width={32} height={32} unoptimized />
        <span className="text-heading font-bold">딜팟</span>
      </Link>
      <button
        type="button"
        onClick={signOut}
        className="focus-ring h-9 rounded-sm px-3 text-body text-text-secondary transition-colors duration-fast ease-out hover:bg-border"
      >
        로그아웃
      </button>
    </header>
  )
}
