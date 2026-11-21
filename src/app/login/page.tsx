import Image from 'next/image'
import { Suspense } from 'react'
import { LoginPanel } from '@/app/login/LoginPanel'

export default function LoginPage() {
  return (
    <main className="flex min-h-dvh flex-col px-5 pb-[calc(24px+env(safe-area-inset-bottom))]">
      <div className="flex flex-1 flex-col justify-center gap-4">
        <Image src="/icon.svg" alt="" width={56} height={56} unoptimized priority />
        <div className="flex flex-col gap-1">
          <h1 className="text-display font-bold">딜팟</h1>
          <p className="text-body text-text-muted">동료가 올린 핫딜을 한 곳에서 다 같이 봐요</p>
        </div>
      </div>
      <Suspense>
        <LoginPanel />
      </Suspense>
    </main>
  )
}
