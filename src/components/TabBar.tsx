'use client';
import React from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import { BarChart3, Receipt, MessageCircle } from 'lucide-react';

const TABS = [
  { id: 'tab-dashboard', label: 'Dashboard', icon: BarChart3, route: '/income-dashboard' },
  { id: 'tab-deductions', label: 'Deductions', icon: Receipt, route: '/deductions-roadmap' },
  { id: 'tab-chat', label: 'AI Chat', icon: MessageCircle, route: '/chat' },
];

export default function TabBar() {
  const router = useRouter();
  const pathname = usePathname();

  const activeIndex = TABS?.findIndex(t => pathname?.startsWith(t?.route));

  return (
    <nav
      className="fixed bottom-0 left-0 right-0 z-50 safe-bottom"
      style={{
        maxWidth: 430,
        margin: '0 auto',
        background: 'linear-gradient(to top, #0D0F12 60%, transparent)',
      }}
      role="navigation"
      aria-label="Main navigation"
    >
      <div
        className="flex items-center justify-around px-4 pt-2 pb-1 relative"
        style={{ borderTop: '1px solid #2A2D35', background: '#0D0F12' }}
      >
        {activeIndex >= 0 && (
          <motion.div
            layoutId="tab-pill"
            className="absolute top-0 h-0.5 rounded-full"
            style={{
              background: '#00E676',
              width: 40,
              left: `calc(${(activeIndex / TABS?.length) * 100}% + ${(100 / TABS?.length / 2)}% - 20px)`,
              boxShadow: '0 0 8px rgba(0, 230, 118, 0.6)',
            }}
            transition={{ type: 'spring', stiffness: 400, damping: 30 }}
          />
        )}

        {TABS?.map((tab, i) => {
          const isActive = pathname?.startsWith(tab?.route);
          const IconComponent = tab?.icon;
          return (
            <button
              key={tab?.id}
              onClick={() => router?.push(tab?.route)}
              className="flex flex-col items-center justify-center gap-1 py-3 px-4 rounded-xl transition-all duration-200 active:scale-95"
              style={{ minWidth: 80, minHeight: 56 }}
              aria-label={tab?.label}
              aria-current={isActive ? 'page' : undefined}
            >
              <IconComponent
                size={24}
                style={{ color: isActive ? '#00E676' : '#4A4F5C' }}
                strokeWidth={isActive ? 2.5 : 1.5}
              />
              <span
                className="text-xs font-medium leading-tight"
                style={{
                  color: isActive ? '#00E676' : '#4A4F5C',
                  fontFamily: 'DM Sans, sans-serif',
                  fontSize: 11,
                  letterSpacing: '0.01em',
                }}
              >
                {tab?.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
