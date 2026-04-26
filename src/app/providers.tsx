'use client';
import { UserProfileProvider } from '../context/UserProfileContext';
import { Toaster } from 'sonner';

export default function Providers({ children }: { children: React.ReactNode }) {
  return (
    <UserProfileProvider>
      {children}
      <Toaster
        position="bottom-center"
        toastOptions={{
          style: {
            background: '#1A1D23',
            border: '1px solid #2A2D35',
            color: '#F0F2F5',
            fontFamily: 'DM Sans, sans-serif',
            fontSize: 14,
          },
        }}
      />
    </UserProfileProvider>
  );
}