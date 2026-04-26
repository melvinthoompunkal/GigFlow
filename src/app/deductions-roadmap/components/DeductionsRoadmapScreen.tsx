'use client';
import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { useUserProfile } from '../../../context/UserProfileContext';
import { FALLBACK_DEDUCTIONS, FALLBACK_ROADMAP } from '../../../context/UserProfileContext';
import TabBar from '../../../components/TabBar';
import DeductionCard from './DeductionCard';
import RoadmapItem from './RoadmapItem';

type Tab = 'deductions' | 'roadmap';

export default function DeductionsRoadmapScreen() {
  const router = useRouter();
  const { profile, activateDemoMode } = useUserProfile();
  const [activeTab, setActiveTab] = useState<Tab>('deductions');

  const isReady = profile.isOnboarded || profile.isDemoMode;

  const deductions = profile.claudeAnalysis?.deductions ?? FALLBACK_DEDUCTIONS;
  const roadmap = profile.claudeAnalysis?.roadmap ?? FALLBACK_ROADMAP;
  const totalSavings = deductions.reduce((sum, d) => sum + d.value, 0);

  if (!isReady) {
    return (
      <div className="flex flex-col h-screen items-center justify-center px-6" style={{ background: '#0D0F12' }}>
        <div className="text-center">
          <div className="text-5xl mb-4">🧾</div>
          <h2 className="text-xl font-bold mb-2" style={{ color: '#F0F2F5' }}>No deductions yet</h2>
          <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>Complete onboarding to unlock your personalized deduction analysis.</p>
          <button
            onClick={() => router.push('/onboarding-survey')}
            className="px-6 py-3 rounded-xl font-semibold text-sm active:scale-95 transition-all"
            style={{ background: 'linear-gradient(135deg, #00C853, #00E676)', color: '#0D0F12' }}
          >
            Start Onboarding
          </button>
          <button
            onClick={() => activateDemoMode()}
            className="block mx-auto mt-3 text-sm"
            style={{ color: '#8B90A0' }}
          >
            or try Demo Mode
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen overflow-hidden" style={{ background: '#0D0F12' }}>
      <div className="flex-1 overflow-y-auto scrollbar-hide pb-24">
        {/* Header */}
        <div className="px-5 pt-14 pb-4">
          <h1 className="text-2xl font-bold" style={{ color: '#F0F2F5' }}>Tax Optimizer</h1>
          <p className="text-sm mt-1" style={{ color: '#8B90A0' }}>Deductions & 90-day action plan</p>
        </div>

        {/* Sticky segmented control */}
        <div className="sticky top-0 z-10 px-5 pb-4" style={{ background: '#0D0F12' }}>
          <div
            className="flex p-1 rounded-2xl relative"
            style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}
          >
            {(['deductions', 'roadmap'] as Tab[]).map(tab => (
              <button
                key={`seg-${tab}`}
                onClick={() => setActiveTab(tab)}
                className="flex-1 py-2.5 rounded-xl text-sm font-semibold relative z-10 transition-colors duration-200"
                style={{
                  color: activeTab === tab ? '#0D0F12' : '#8B90A0',
                  fontFamily: 'DM Sans, sans-serif',
                }}
              >
                {activeTab === tab && (
                  <motion.div
                    layoutId="seg-pill"
                    className="absolute inset-0 rounded-xl"
                    style={{ background: 'linear-gradient(135deg, #00C853, #00E676)' }}
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
                <span className="relative z-10">
                  {tab === 'deductions' ? '💰 Deductions' : '🗺️ Roadmap'}
                </span>
              </button>
            ))}
          </div>
        </div>

        <AnimatePresence mode="wait">
          {activeTab === 'deductions' ? (
            <motion.div
              key="deductions-tab"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.2 }}
            >
              {/* Deductions summary */}
              <div className="mx-5 mb-4 p-4 rounded-2xl" style={{ background: 'rgba(0, 230, 118, 0.06)', border: '1px solid rgba(0, 230, 118, 0.2)' }}>
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-xs uppercase tracking-wider mb-1" style={{ color: '#8B90A0', letterSpacing: '0.1em' }}>
                      TOTAL IDENTIFIED DEDUCTIONS
                    </p>
                    <p className="font-mono font-bold text-2xl" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
                      ${totalSavings.toLocaleString()}
                    </p>
                    <p className="text-xs mt-1" style={{ color: '#8B90A0' }}>
                      {deductions.length} deductions found for your profile
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs" style={{ color: '#8B90A0' }}>Effective saving</p>
                    <p className="font-mono font-bold text-lg" style={{ color: '#1DE9B6', fontFamily: 'DM Mono, monospace' }}>
                      ~{Math.round((totalSavings / ((profile.monthlyEarnings * 12) || 1)) * 100)}%
                    </p>
                    <p className="text-xs" style={{ color: '#8B90A0' }}>of gross income</p>
                  </div>
                </div>
              </div>

              {/* Eligibility legend */}
              <div className="flex gap-3 px-5 mb-4">
                {[
                  { key: 'high', label: 'High Eligibility', color: '#00E676' },
                  { key: 'medium', label: 'Medium', color: '#FFB300' },
                  { key: 'low', label: 'Low', color: '#FF5252' },
                ].map(e => (
                  <div key={`elig-${e.key}`} className="flex items-center gap-1.5">
                    <div className="w-2 h-2 rounded-full" style={{ background: e.color }} />
                    <span className="text-xs" style={{ color: '#8B90A0' }}>{e.label}</span>
                  </div>
                ))}
              </div>

              {/* Deduction cards */}
              <div className="px-5 flex flex-col gap-3 pb-4">
                {deductions.map((ded, i) => (
                  <DeductionCard key={ded.id} deduction={ded} index={i} />
                ))}
              </div>

              {/* Disclaimer */}
              <div className="mx-5 mb-4 p-3 rounded-xl" style={{ background: '#1A1D23' }}>
                <p className="text-xs" style={{ color: '#8B90A0' }}>
                  ⚠️ These estimates are for planning purposes only. Consult a CPA for filing advice. Deduction amounts may vary based on actual documentation.
                </p>
              </div>
            </motion.div>
          ) : (
            <motion.div
              key="roadmap-tab"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 20 }}
              transition={{ duration: 0.2 }}
            >
              {/* Roadmap header */}
              <div className="px-5 mb-4">
                <div className="p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
                  <p className="text-sm font-semibold mb-1" style={{ color: '#F0F2F5' }}>Your 90-Day Financial Roadmap</p>
                  <p className="text-xs" style={{ color: '#8B90A0' }}>Personalized action steps to optimize your gig finances and minimize tax liability.</p>
                  <div className="flex gap-3 mt-3">
                    {[
                      { label: 'Steps', value: roadmap.length, color: '#00E676' },
                      { label: 'High Priority', value: roadmap.filter(r => r.priority === 'high').length, color: '#FF5252' },
                      { label: 'Completed', value: roadmap.filter(r => r.completed).length, color: '#8B90A0' },
                    ].map(stat => (
                      <div key={`rm-stat-${stat.label}`} className="flex-1 text-center">
                        <p className="font-mono font-bold text-lg" style={{ color: stat.color, fontFamily: 'DM Mono, monospace' }}>{stat.value}</p>
                        <p className="text-xs" style={{ color: '#8B90A0' }}>{stat.label}</p>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Timeline */}
              <div className="px-5 pb-4">
                {roadmap.map((step, i) => (
                  <RoadmapItem key={step.id} step={step} isLast={i === roadmap.length - 1} />
                ))}
              </div>

              {/* Chat CTA */}
              <div className="mx-5 mb-6">
                <button
                  onClick={() => router.push('/chat?prompt=Tell+me+more+about+my+90-day+financial+roadmap')}
                  className="w-full py-4 rounded-2xl font-semibold text-sm flex items-center justify-center gap-2 transition-all active:scale-95"
                  style={{
                    background: 'linear-gradient(135deg, #00C853, #00E676)',
                    color: '#0D0F12',
                    boxShadow: '0 4px 16px rgba(0, 230, 118, 0.25)',
                    fontFamily: 'DM Sans, sans-serif',
                  }}
                >
                  💬 Ask AI About My Roadmap
                </button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <TabBar />
    </div>
  );
}