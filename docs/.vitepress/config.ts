// .vitepress/config.ts
import { defineConfig } from 'vitepress'

export default defineConfig({
  srcDir: 'docs',
  ignoreDeadLinks: true,

  // Change this string to your project name
  title: "Nuxt4 Monorepo Demo",
  description: "Documentation for the Nuxt4 Monorepo Demo",

  // Configure the Right-Hand Sidebar (Outline)
  outline: {
    level: 'deep',       // 'deep' (same as [2, 6]), or specific array like [2, 3]
    label: 'On this page' // The heading text for the right sidebar
  },

  themeConfig: {

    logo: '/logo.png', // Points to docs/public/logo.png
    siteTitle: 'Nuxt4 Demo', // Optional: Set false to show only logo

    // Top-level Navigation
    nav: [
      { text: 'Coding Standards', link: '/coding-standards/' },
      { text: 'Data Architecture', link: '/data-architecture/' },
      { text: 'Script Guides', link: '/script-guides/' },
      { text: 'System Design', link: '/system-design/' },
    ],

    // Sidebar: Use path keys with trailing slashes
    sidebar: {
      // 1. Coding Standards Section
      '/coding-standards/': [
        {
          text: 'Coding Standards',
          items: [
            // Link to the index.md you created
            { text: 'Overview', link: '/coding-standards/' },
            { text: 'Component Best Practices', link: '/coding-standards/component-best-practices' },
            { text: 'Project Standards', link: '/coding-standards/project-coding-standards' },
            { text: 'Routes & Pages', link: '/coding-standards/routes-and-pages-components-best-practices' },
          ]
        }
      ],

      // 2. Data Architecture Section
      '/data-architecture/': [
        {
          text: 'Architecture Overview',
          items: [
            { text: 'Introduction', link: '/data-architecture/' },
            { text: 'Mock Data Wrapper', link: '/data-architecture/mock-data-wrapper' },
          ]
        },
        {
          text: 'Data Stores',
          items: [
            { text: 'CouchDB', link: '/data-architecture/couchdb/' },
            { text: 'PostgreSQL', link: '/data-architecture/postgresql/' },
            { text: 'Memgraph', link: '/data-architecture/memgraph/' },
            { text: 'MinIO', link: '/data-architecture/minio/' },
            { text: 'OpenSearch', link: '/data-architecture/opensearch/' },
            { text: 'Valkey', link: '/data-architecture/valkey/' },
          ]
        }
      ],

      // 3. Script Guides Section
      '/script-guides/': [
        {
          text: 'Guides',
          items: [
            { text: 'Overview', link: '/script-guides/' },
            { text: 'Script Suite', link: '/script-guides/script-suite' },
          ]
        },
        {
          text: 'PowerShell',
          items: [
            { text: 'Overview', link: '/script-guides/powershell/' },
            { text: 'Provision Project', link: '/script-guides/powershell/provision-project' },
            { text: 'Git Initialise', link: '/script-guides/powershell/git-initialise' },
            // ... add other scripts
          ]
        }
      ]
    }
  }
})
