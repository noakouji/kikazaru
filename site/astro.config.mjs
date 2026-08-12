// @ts-check
import { defineConfig } from 'astro/config'

// Cloudflare Workers の静的アセット配信に載せるため、通常の静的ビルドで出す。
export default defineConfig({
  output: 'static',
  build: { format: 'file' },
})
