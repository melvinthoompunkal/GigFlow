'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useUserProfile } from '../context/UserProfileContext';

export default function RootPage() {
  const router = useRouter();
  const { profile } = useUserProfile();

  useEffect(() => {
    if (profile?.isOnboarded || profile?.isDemoMode) {
      router?.replace('/income-dashboard');
    } else {
      router?.replace('/onboarding-survey');
    }
  }, [profile?.isOnboarded, profile?.isDemoMode, router]);

  return (
    <div
      className="flex items-center justify-center h-screen"
      style={{ background: '#0D0F12' }}
    >
      <div className="flex gap-1.5">
        <span className="w-2 h-2 rounded-full dot-1" style={{ background: '#00E676' }} />
        <span className="w-2 h-2 rounded-full dot-2" style={{ background: '#00E676' }} />
        <span className="w-2 h-2 rounded-full dot-3" style={{ background: '#00E676' }} />
      </div>
    </div>
  );
}