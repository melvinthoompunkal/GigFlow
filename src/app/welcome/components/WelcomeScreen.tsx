'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function WelcomeScreen() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(true);
  const [progress, setProgress] = useState(0);

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

  const handleGetStarted = () => {
    router.push('/onboarding-survey');
  };

  return (
    <div
      className="flex flex-col h-screen items-center justify-center relative overflow-hidden"
      style={{ background: '#0D0F12', maxWidth: 430, margin: '0 auto' }}
    >
      {/* Background gradient accent */}
      <div
        className="absolute inset-0 opacity-30"
        style={{
          background: 'radial-gradient(circle at center, rgba(0, 230, 118, 0.1) 0%, transparent 70%)',
        }}
      />

      {/* Content container */}
      <div className="relative z-10 flex flex-col items-center justify-center h-full px-6 gap-8">
        {/* Title */}
        <div className="text-center">
          <h1
            className="text-4xl font-bold mb-2"
            style={{ color: '#F0F2F5', letterSpacing: '-0.02em' }}
          >
            Welcome to
          </h1>
          <h2
            className="text-4xl font-bold"
            style={{ color: '#00E676', letterSpacing: '-0.02em' }}
          >
            GigFlow
          </h2>
        </div>

        {/* Loading animation section */}
        <div className="flex flex-col items-center gap-8 w-full flex-1 justify-center">
          {/* Scooter rider image with loading bar */}
          <div className="relative w-full h-40 flex items-center justify-center">
            {/* Loading track */}
            <div
              className="absolute w-full h-1 rounded-full"
              style={{ background: '#1A1D23' }}
            />

            {/* Moving scooter image */}
            <div
              className="absolute transition-all duration-300 ease-out"
              style={{
                left: `${Math.max(0, progress - 10)}%`,
                transform: 'translateX(-50%)',
              }}
            >
              <img
                src="/assets/images/scooter-rider.png"
                alt="Scooter rider"
                className="w-20 h-20 object-contain drop-shadow-lg"
              />
            </div>

            {/* Loading progress bar */}
            <div
              className="absolute h-1 rounded-full transition-all duration-300"
              style={{
                width: `${progress}%`,
                background: 'linear-gradient(90deg, #00E676, #00C853)',
              }}
            />
          </div>

          {/* Loading text */}
          {isLoading && (
            <div className="text-center">
              <p className="text-sm" style={{ color: '#8B90A0' }}>
                {progress < 30 && 'Loading your dashboard...'}
                {progress >= 30 && progress < 60 && 'Setting up your profile...'}
                {progress >= 60 && progress < 90 && 'Almost there...'}
                {progress >= 90 && 'Ready to go!'}
              </p>
              <p
                className="text-xs mt-2"
                style={{ color: '#4A4F5C' }}
              >
                {Math.round(progress)}%
              </p>
            </div>
          )}
        </div>

        {/* Get Started button */}
        {!isLoading && (
          <button
            onClick={handleGetStarted}
            className="w-full py-4 rounded-xl font-semibold text-base transition-all active:scale-95 animate-fade-in"
            style={{
              background: '#00E676',
              color: '#0D0F12',
              boxShadow: '0 8px 24px rgba(0, 230, 118, 0.3)',
            }}
          >
            Let&apos;s get Started
          </button>
        )}
      </div>
    </div>
  );
}
