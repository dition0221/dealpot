import { Soup } from 'lucide-react'
import { AppHeader } from '@/components/AppHeader'

// 피드 자리. 다음 단계에서 deal_feed + React Query로 채움
export default function FeedPage() {
  return (
    <>
      <AppHeader />
      <main className="flex flex-col gap-3 px-3 pb-24">
        <section className="flex flex-col items-center gap-3 rounded-lg bg-surface px-4 py-8 text-center">
          <Soup size={24} strokeWidth={1.75} className="text-icon-muted" aria-hidden />
          <div className="flex flex-col gap-1">
            <h2 className="text-body-lg font-bold">첫 딜을 올려보세요</h2>
            <p className="text-body text-text-muted">동료들이 바로 볼 수 있어요.</p>
          </div>
        </section>
      </main>
    </>
  )
}
