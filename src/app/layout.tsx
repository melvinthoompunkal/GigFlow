import type { Metadata, Viewport } from 'next';
import '../styles/tailwind.css';
import Providers from './providers';

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  userScalable: false,
  minimumScale: 1,
  maximumScale: 1,
  viewportFit: 'cover',
};

export const metadata: Metadata = {
  title: 'GigFlow — Financial OS for Gig Workers',
  description: 'GigFlow helps gig workers track income, maximize tax deductions, and plan quarterly taxes across all platforms from one dashboard.',
  icons: {
    icon: [{ url: '/favicon.ico', type: 'image/x-icon' }],
  },
  formatDetection: {
    telephone: true,
    email: true,
    address: true,
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'GigFlow',
  },
  openGraph: {
    title: 'GigFlow — Financial OS for Gig Workers',
    description: 'GigFlow helps gig workers track income, maximize tax deductions, and plan quarterly taxes across all platforms from one dashboard.',
    type: 'website',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="bg-background">
      <head>
        <meta name="theme-color" content="#0D0F12" />
        <meta name="mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content="GigFlow" />
      </head>
      <body className="overflow-hidden antialiased" style={{ background: '#0D0F12' }}>
        <div className="flex flex-col h-screen max-w-sm mx-auto relative overflow-hidden" style={{ background: '#0D0F12' }}>
          <Providers>
            {children}
          </Providers>
        </div>
      </body>
    </html>
  );
}
