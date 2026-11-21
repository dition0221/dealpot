import type { Metadata, Viewport } from 'next'
import localFont from 'next/font/local'
import { Providers } from '@/app/providers'
import '@/app/globals.css'

const pretendard = localFont({
  src: './fonts/PretendardVariable.woff2',
  variable: '--font-pretendard',
  weight: '45 920',
  display: 'swap'
})

export const metadata: Metadata = {
  title: '딜팟',
  description: '동료가 올린 핫딜을 한 곳에서 다 같이 봐요',
  // 검색 노출 안 함 (robots.ts와 같이)
  robots: { index: false, follow: false }
}

export const viewport: Viewport = {
  themeColor: '#edf3f6',
  viewportFit: 'cover'
}

export default function RootLayout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="ko" className={`${pretendard.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col">
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
