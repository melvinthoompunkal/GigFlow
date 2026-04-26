'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function WelcomeScreen() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [progress, setProgress] = useState(0);
  const [scooterPosition, setScooterPosition] = useState(0);

  // Simulate loading progress
  useEffect(() => {
    if (!isLoading) return;

    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          setIsLoading(false);
          clearInterval(interval);
          return 100;
        }
        // Random increment between 5 and 15
        return prev + Math.random() * 10 + 5;
      });
    }, 300);

    return () => clearInterval(interval);
  }, [isLoading]);

  // Update scooter position based on progress
  useEffect(() => {
    setScooterPosition(progress);
  }, [progress]);

  const handleGetStarted = () => {
    router.push('/onboarding-survey');
  };

  return (
    <div
      className="flex flex-col h-screen relative overflow-hidden"
      style={{ background: '#0D0F12', maxWidth: 430, margin: '0 auto' }}
    >
      {/* Subtle background accent */}
      <div
        className="absolute inset-0 opacity-10"
        style={{
          background: 'radial-gradient(circle at center, rgba(0, 230, 118, 0.2) 0%, transparent 70%)',
        }}
      />

      {/* Content container */}
      <div className="relative z-10 flex flex-col h-full px-6 pt-12">
        {/* Get Started Button - Top of page */}
        {!isLoading && (
          <button
            onClick={handleGetStarted}
            className="w-full py-3 rounded-xl font-semibold text-base transition-all active:scale-95 animate-fade-in mb-8"
            style={{
              background: '#00E676',
              color: '#0D0F12',
              boxShadow: '0 8px 24px rgba(0, 230, 118, 0.3)',
            }}
          >
            Let&apos;s get Started
          </button>
        )}

        {/* Scooter Loading Animation - Center */}
        <div className="flex-1 flex flex-col items-center justify-center gap-4">
          {/* Loading track with animated scooter */}
          <div className="relative w-full h-32 flex items-center justify-center">
            {/* Dashed line track */}
            <div
              className="absolute w-full h-0.5"
              style={{
                background:
                  'repeating-linear-gradient(90deg, #2A2D35 0px, #2A2D35 16px, transparent 16px, transparent 32px)',
              }}
            />

            {/* Animated scooter image */}
            <div
              className="absolute transition-all duration-300 ease-out"
              style={{
                left: `${Math.min(scooterPosition, 100)}%`,
                transform: 'translateX(-50%)',
              }}
            >
              <img
                src="/assets/images/scooter-loading.gif"
                alt="Loading"
                className="w-24 h-24 object-contain"
                style={{
                  filter: 'drop-shadow(0 4px 12px rgba(0, 230, 118, 0.2))',
                }}
              />
            </div>
          </div>

          {/* Progress percentage */}
          {isLoading && (
            <p className="text-sm font-medium" style={{ color: '#00E676' }}>
              {Math.round(progress)}%
            </p>
          )}
        </div>

        {/* Welcome Text - Bottom section, professional */}
        <div className="flex flex-col items-center justify-end pb-16 gap-3">
          <p className="text-xs tracking-widest font-medium" style={{ color: '#8B90A0' }}>
            YOUR FINANCIAL OS FOR GIG WORK
          </p>
          <h1
            className="text-3xl font-bold text-center leading-tight"
            style={{ color: '#F0F2F5' }}
          >
            Welcome to{' '}
            <span style={{ color: '#00E676' }}>GigFlow</span>
          </h1>
          <p className="text-xs text-center mt-1" style={{ color: '#4A4F5C' }}>
            Track earnings, maximize deductions, and manage taxes across all gig platforms.
          </p>
        </div>
      </div>
    </div>
  );
}
