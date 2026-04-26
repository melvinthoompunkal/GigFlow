'use client';
import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';

const LOADING_STEPS = [
  'Analyzing your platforms...',
  'Calculating deductions...',
  'Estimating tax liability...',
  'Building your roadmap...',
  'Personalizing insights...',
];

interface LoadingScreenProps {
  onComplete: () => void;
}

export default function LoadingScreen({ onComplete }: LoadingScreenProps) {
  const [stepIndex, setStepIndex] = useState(0);
  const [progress, setProgress] = useState(0);
  const [isDone, setIsDone] = useState(false);

  useEffect(() => {
    const stepDuration = 600;
    const interval = setInterval(() => {
      setStepIndex(prev => {
        const next = prev + 1;
        if (next >= LOADING_STEPS.length) {
          clearInterval(interval);
          return prev;
        }
        return next;
      });
      setProgress(prev => Math.min(prev + 20, 100));
    }, stepDuration);

    const doneTimer = setTimeout(() => {
      setIsDone(true);
      setTimeout(onComplete, 600);
    }, stepDuration * LOADING_STEPS.length + 400);

    return () => {
      clearInterval(interval);
      clearTimeout(doneTimer);
    };
  }, [onComplete]);

  return (
    <div
      className="fixed inset-0 flex flex-col items-center justify-center z-50"
      style={{ background: '#0D0F12', maxWidth: 430, margin: '0 auto' }}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        className="flex flex-col items-center gap-8 px-8 w-full"
      >
        <div className="relative">
          {isDone ? (
            <motion.div
              initial={{ scale: 0 }}
              animate={{ scale: 1 }}
              transition={{ type: 'spring', stiffness: 300, damping: 20 }}
              className="w-20 h-20 rounded-full flex items-center justify-center"
              style={{ background: 'rgba(0, 230, 118, 0.15)', border: '2px solid #00E676' }}
            >
              <svg width="36" height="36" viewBox="0 0 36 36" fill="none">
                <motion.path
                  d="M8 18 L15 25 L28 11"
                  stroke="#00E676"
                  strokeWidth="3"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  initial={{ pathLength: 0 }}
                  animate={{ pathLength: 1 }}
                  transition={{ duration: 0.4, ease: 'easeOut' }}
                />
              </svg>
            </motion.div>
          ) : (
            <div
              className="w-20 h-20 rounded-full flex items-center justify-center"
              style={{ background: 'rgba(0, 230, 118, 0.08)', border: '2px solid #2A2D35' }}
            >
              <div className="flex gap-1.5">
                <span className="w-2 h-2 rounded-full dot-1" style={{ background: '#00E676' }} />
                <span className="w-2 h-2 rounded-full dot-2" style={{ background: '#00E676' }} />
                <span className="w-2 h-2 rounded-full dot-3" style={{ background: '#00E676' }} />
              </div>
            </div>
          )}
        </div>

        <div className="w-full">
          <div className="flex justify-between mb-2">
            <span className="text-sm" style={{ color: '#8B90A0', fontFamily: 'DM Sans, sans-serif' }}>
              {isDone ? 'Analysis complete!' : LOADING_STEPS[stepIndex]}
            </span>
            <span className="text-sm font-mono" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
              {progress}%
            </span>
          </div>
          <div className="w-full h-1 rounded-full" style={{ background: '#2A2D35' }}>
            <motion.div
              className="h-full rounded-full"
              style={{ background: 'linear-gradient(90deg, #00C853, #00E676)', boxShadow: '0 0 8px rgba(0, 230, 118, 0.4)' }}
              animate={{ width: `${progress}%` }}
              transition={{ duration: 0.4, ease: 'easeOut' }}
            />
          </div>
        </div>

        <div className="text-center">
          <p className="text-lg font-semibold" style={{ color: '#F0F2F5' }}>Building your financial profile</p>
          <p className="text-sm mt-1" style={{ color: '#8B90A0' }}>Personalized for your gig work</p>
        </div>
      </motion.div>
    </div>
  );
}