import type { MetadataRoute } from 'next'

// 사내용이라 검색엔진에 노출하지 않음
export default function robots(): MetadataRoute.Robots {
  return { rules: { userAgent: '*', disallow: '/' } }
}
