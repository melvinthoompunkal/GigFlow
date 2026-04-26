import type { Metadata, Viewport } from 'next';
import '../styles/tailwind.css';
import Providers from './providers';

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
};

export const metadata: Metadata = {
  title: 'GigFlow — Financial OS for Gig Workers',
  description: 'GigFlow helps gig workers track income, maximize tax deductions, and plan quarterly taxes across all platforms from one dashboard.',
  icons: {
    icon: [{ url: '/favicon.ico', type: 'image/x-icon' }],
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>
          {children}
        </Providers>
</body>
    </html>
  );
}