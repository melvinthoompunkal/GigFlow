'use client';
import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Check, Clock, AlertTriangle, ChevronDown, ChevronUp } from 'lucide-react';
import type { RoadmapStep } from '../../../context/UserProfileContext';

const PRIORITY_CONFIG = {
  high: { color: '#FF5252', label: 'High Priority', dot: '🔴' },
  medium: { color: '#FFB300', label: 'Medium', dot: '🟡' },
  low: { color: '#448AFF', label: 'Low Priority', dot: '🔵' },
};

interface RoadmapItemProps {
  step: RoadmapStep;
  isLast: boolean;
}

export default function RoadmapItem({ step, isLast }: RoadmapItemProps) {
  const [expanded, setExpanded] = useState(false);
  const priority = PRIORITY_CONFIG[step.priority];

  return (
    <div className="flex gap-4">
      {/* Timeline column */}
      <div className="flex flex-col items-center" style={{ width: 32, flexShrink: 0 }}>
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: step.step * 0.1 }}
          className="w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 z-10"
          style={{
            background: step.completed
              ? 'linear-gradient(135deg, #00C853, #00E676)'
              : step.priority === 'high' ?'rgba(255, 82, 82, 0.15)' :'#1A1D23',
            border: step.completed
              ? 'none'
              : `2px solid ${priority.color}`,
          }}
        >
          {step.completed ? (
            <Check size={14} color="#0D0F12" strokeWidth={3} />
          ) : (
            <span className="font-mono font-bold text-xs" style={{ color: priority.color, fontFamily: 'DM Mono, monospace' }}>
              {step.step}
            </span>
          )}
        </motion.div>
        {!isLast && (
          <div
            className="flex-1 w-px mt-1"
            style={{
              background: `linear-gradient(to bottom, ${priority.color}60, transparent)`,
              minHeight: 40,
            }}
          />
        )}
      </div>

      {/* Content */}
      <div className="flex-1 mb-4">
        <button
          onClick={() => setExpanded(e => !e)}
          className="w-full text-left p-4 rounded-2xl transition-all active:scale-[0.98]"
          style={{
            background: expanded ? '#22262E' : '#1A1D23',
            border: `1px solid ${expanded ? priority.color + '40' : '#2A2D35'}`,
          }}
          aria-expanded={expanded}
        >
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1 flex-wrap">
                <span
                  className="text-xs px-2 py-0.5 rounded-full"
                  style={{ background: `${priority.color}15`, color: priority.color, border: `1px solid ${priority.color}30` }}
                >
                  {priority.dot} {priority.label}
                </span>
                <span
                  className="text-xs px-2 py-0.5 rounded-full flex items-center gap-1"
                  style={{ background: '#2A2D35', color: '#8B90A0' }}
                >
                  <Clock size={10} />
                  {step.deadline}
                </span>
              </div>
              <p className="text-sm font-semibold" style={{ color: '#F0F2F5' }}>
                {step.title}
              </p>
            </div>
            {expanded ? (
              <ChevronUp size={16} color="#4A4F5C" className="flex-shrink-0 mt-0.5" />
            ) : (
              <ChevronDown size={16} color="#4A4F5C" className="flex-shrink-0 mt-0.5" />
            )}
          </div>

          {expanded && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="mt-3 pt-3"
              style={{ borderTop: '1px solid #2A2D35' }}
            >
              <p className="text-sm leading-relaxed" style={{ color: '#8B90A0' }}>
                {step.description}
              </p>
              {step.priority === 'high' && (
                <div className="flex items-center gap-2 mt-3 p-2 rounded-xl" style={{ background: 'rgba(255, 82, 82, 0.08)' }}>
                  <AlertTriangle size={14} color="#FF5252" />
                  <p className="text-xs" style={{ color: '#FF5252' }}>Deadline approaching — take action soon</p>
                </div>
              )}
            </motion.div>
          )}
        </button>
      </div>
    </div>
  );
}