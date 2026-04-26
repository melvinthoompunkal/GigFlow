'use client';
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronDown, ChevronUp } from 'lucide-react';
import type { Deduction } from '../../../context/UserProfileContext';

const ELIGIBILITY_CONFIG = {
  high: { label: 'High Eligibility', color: '#00E676', bg: 'rgba(0, 230, 118, 0.1)', border: 'rgba(0, 230, 118, 0.3)' },
  medium: { label: 'Medium', color: '#FFB300', bg: 'rgba(255, 179, 0, 0.1)', border: 'rgba(255, 179, 0, 0.3)' },
  low: { label: 'Lower Likelihood', color: '#FF5252', bg: 'rgba(255, 82, 82, 0.1)', border: 'rgba(255, 82, 82, 0.3)' },
};

interface DeductionCardProps {
  deduction: Deduction;
  index: number;
}

export default function DeductionCard({ deduction, index }: DeductionCardProps) {
  const [expanded, setExpanded] = useState(false);
  const elig = ELIGIBILITY_CONFIG[deduction.eligibility];

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: index * 0.05 }}
      layout
    >
      <button
        onClick={() => setExpanded(e => !e)}
        className="w-full text-left rounded-2xl overflow-hidden transition-all active:scale-[0.98]"
        style={{
          background: expanded ? '#22262E' : '#1A1D23',
          border: expanded ? `1px solid ${elig.color}40` : '1px solid #2A2D35',
        }}
        aria-expanded={expanded}
        aria-label={`${deduction.name} deduction details`}
      >
        <div className="flex items-center gap-3 p-4">
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 text-xl"
            style={{ background: elig.bg, border: `1px solid ${elig.border}` }}
          >
            {deduction.icon}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-0.5">
              <p className="text-sm font-semibold truncate" style={{ color: '#F0F2F5' }}>
                {deduction.name}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span
                className="text-xs px-2 py-0.5 rounded-full"
                style={{ background: elig.bg, color: elig.color, border: `1px solid ${elig.border}` }}
              >
                {elig.label}
              </span>
              <span className="text-xs" style={{ color: '#8B90A0' }}>{deduction.category}</span>
            </div>
          </div>
          <div className="text-right flex-shrink-0 ml-2">
            <p className="font-mono font-bold text-base" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
              ${deduction.value.toLocaleString()}
            </p>
            {expanded ? (
              <ChevronUp size={14} color="#4A4F5C" className="ml-auto mt-1" />
            ) : (
              <ChevronDown size={14} color="#4A4F5C" className="ml-auto mt-1" />
            )}
          </div>
        </div>

        <AnimatePresence>
          {expanded && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              transition={{ duration: 0.2, ease: [0.4, 0, 0.2, 1] }}
              style={{ overflow: 'hidden' }}
            >
              <div className="px-4 pb-4 pt-0">
                <div className="h-px mb-3" style={{ background: '#2A2D35' }} />
                <p className="text-sm leading-relaxed" style={{ color: '#8B90A0' }}>
                  {deduction.explanation}
                </p>
                <div className="flex items-center gap-3 mt-3">
                  <div className="flex-1 p-3 rounded-xl text-center" style={{ background: '#0D0F12' }}>
                    <p className="text-xs mb-0.5" style={{ color: '#8B90A0' }}>Annual Deduction</p>
                    <p className="font-mono font-bold" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
                      ${deduction.value.toLocaleString()}
                    </p>
                  </div>
                  <div className="flex-1 p-3 rounded-xl text-center" style={{ background: '#0D0F12' }}>
                    <p className="text-xs mb-0.5" style={{ color: '#8B90A0' }}>Tax Savings Est.</p>
                    <p className="font-mono font-bold" style={{ color: '#1DE9B6', fontFamily: 'DM Mono, monospace' }}>
                      ${Math.round(deduction.value * 0.22).toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </button>
    </motion.div>
  );
}