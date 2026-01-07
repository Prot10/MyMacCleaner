import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';
import icon from 'astro-icon';

export default defineConfig({
  site: 'https://Prot10.github.io',
  base: '/MyMacCleaner',
  integrations: [
    tailwind(),
    sitemap(),
    icon()
  ],
  output: 'static',
  build: {
    assets: '_assets'
  },
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      wrap: true
    }
  }
});
