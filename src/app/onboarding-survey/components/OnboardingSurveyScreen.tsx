'use client';
import React, { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, Check } from 'lucide-react';
import { useUserProfile, type Platform, type FilingStatus, type VehicleType, type HousingType } from '../../../context/UserProfileContext';
import { fetchGigAnalysis } from '../../../utils/claudeApi';
import { PLATFORM_CONFIG, VEHICLE_CONFIG, US_STATES, EARNINGS_OPTIONS, FILING_STATUS_OPTIONS } from '../../../utils/constants';
import LoadingScreen from '../../../components/LoadingScreen';

const TOTAL_STEPS = 10;

type Direction = 1 | -1;

const slideVariants = {
  enter: (dir: Direction) => ({ x: dir > 0 ? 300 : -300, opacity: 0 }),
  center: { x: 0, opacity: 1 },
  exit: (dir: Direction) => ({ x: dir > 0 ? -300 : 300, opacity: 0 }),
};

export default function OnboardingSurveyScreen() {
  const router = useRouter();
  const { profile, updateProfile, setAnalysis, activateDemoMode } = useUserProfile();
  const [step, setStep] = useState(0);
  const [direction, setDirection] = useState<Direction>(1);
  const [isLoading, setIsLoading] = useState(false);
  const [stateSearch, setStateSearch] = useState('');

  const goNext = useCallback(() => {
    if (step < TOTAL_STEPS - 1) {
      setDirection(1);
      setStep(s => s + 1);
    } else {
      handleComplete();
    }
  }, [step]);

  const goBack = useCallback(() => {
    if (step > 0) {
      setDirection(-1);
      setStep(s => s - 1);
    }
  }, [step]);

  const handleComplete = async () => {
    setIsLoading(true);
    // Backend integration point: fetchGigAnalysis calls Claude API
    const analysis = await fetchGigAnalysis({ ...profile });
    setAnalysis(analysis);
    updateProfile({ isOnboarded: true });
  };

  const handleLoadingComplete = () => {
    router.push('/income-dashboard');
  };

  if (isLoading) {
    return <LoadingScreen onComplete={handleLoadingComplete} />;
  }

  const platforms = profile.platforms as Platform[];
  const togglePlatform = (p: Platform) => {
    const next = platforms.includes(p) ? platforms.filter(x => x !== p) : [...platforms, p];
    updateProfile({ platforms: next });
  };

  const filteredStates = US_STATES.filter(s =>
    s.name.toLowerCase().includes(stateSearch.toLowerCase()) ||
    s.code.toLowerCase().includes(stateSearch.toLowerCase())
  );

  const expenseLabels: Record<string, string> = {
    gas: 'Gas & Fuel', phone: 'Phone & Data', insurance: 'Vehicle Insurance',
    equipment: 'Tools & Equipment', health: 'Health Insurance', food: 'Food & Meals (business)',
  };

  const canProceed = (): boolean => {
    switch (step) {
      case 0: return platforms.length > 0;
      case 1: return profile.monthlyEarnings > 0;
      case 4: return profile.state !== '';
      default: return true;
    }
  };

  return (
    <div className="flex flex-col h-screen" style={{ background: '#0D0F12', maxWidth: 430, margin: '0 auto' }}>
      {/* Progress bar */}
      <div className="px-5 pt-14 pb-4">
        <div className="flex items-center justify-between mb-3">
          <span className="text-xs" style={{ color: '#8B90A0', fontFamily: 'DM Sans, sans-serif' }}>
            Step {step + 1} of {TOTAL_STEPS}
          </span>
          <button
            onClick={() => { activateDemoMode(); router.push('/income-dashboard'); }}
            className="text-xs px-3 py-1 rounded-full transition-all"
            style={{ color: '#00E676', border: '1px solid rgba(0,230,118,0.3)', background: 'rgba(0,230,118,0.05)' }}
          >
            Demo Mode
          </button>
        </div>
        <div className="w-full h-1 rounded-full" style={{ background: '#2A2D35' }}>
          <motion.div
            className="h-full rounded-full"
            style={{ background: 'linear-gradient(90deg, #00C853, #00E676)' }}
            animate={{ width: `${((step + 1) / TOTAL_STEPS) * 100}%` }}
            transition={{ duration: 0.3 }}
          />
        </div>
      </div>

      {/* Step content */}
      <div className="flex-1 overflow-hidden relative">
        <AnimatePresence custom={direction} mode="wait">
          <motion.div
            key={`step-${step}`}
            custom={direction}
            variants={slideVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{ duration: 0.28, ease: [0.4, 0, 0.2, 1] }}
            className="absolute inset-0 px-5 overflow-y-auto"
          >
            {step === 0 && (
              <StepPlatforms platforms={platforms} onToggle={togglePlatform} />
            )}
            {step === 1 && (
              <StepEarnings
                value={profile.monthlyEarnings}
                onChange={v => updateProfile({ monthlyEarnings: v })}
              />
            )}
            {step === 2 && (
              <StepFilingStatus
                value={profile.filingStatus}
                onChange={v => updateProfile({ filingStatus: v as FilingStatus })}
              />
            )}
            {step === 3 && (
              <StepDependents
                value={profile.hasDependents}
                onChange={v => updateProfile({ hasDependents: v })}
              />
            )}
            {step === 4 && (
              <StepState
                value={profile.state}
                search={stateSearch}
                onSearchChange={setStateSearch}
                onSelect={v => { updateProfile({ state: v }); setStateSearch(''); }}
                filteredStates={filteredStates}
              />
            )}
            {step === 5 && (
              <StepHousing
                value={profile.housingType}
                onChange={v => updateProfile({ housingType: v as HousingType })}
              />
            )}
            {step === 6 && (
              <StepHomeOffice
                value={profile.hasHomeOffice}
                onChange={v => updateProfile({ hasHomeOffice: v })}
              />
            )}
            {step === 7 && (
              <StepVehicle
                value={profile.vehicleType}
                onChange={v => updateProfile({ vehicleType: v as VehicleType })}
              />
            )}
            {step === 8 && (
              <StepExpenses
                expenses={profile.expenses}
                labels={expenseLabels}
                onChange={(key, val) => updateProfile({ expenses: { ...profile.expenses, [key]: val } })}
              />
            )}
            {step === 9 && (
              <StepReview profile={profile} platforms={platforms} />
            )}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Navigation */}
      <div className="px-5 py-4 flex gap-3" style={{ paddingBottom: 'calc(16px + env(safe-area-inset-bottom, 0px))' }}>
        {step > 0 && (
          <button
            onClick={goBack}
            className="w-12 h-12 rounded-xl flex items-center justify-center transition-all active:scale-95"
            style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}
            aria-label="Go back"
          >
            <ChevronLeft size={20} color="#8B90A0" />
          </button>
        )}
        <button
          onClick={goNext}
          disabled={!canProceed()}
          className="flex-1 h-12 rounded-xl font-semibold flex items-center justify-center gap-2 transition-all active:scale-95"
          style={{
            background: canProceed() ? 'linear-gradient(135deg, #00C853, #00E676)' : '#2A2D35',
            color: canProceed() ? '#0D0F12' : '#4A4F5C',
            fontFamily: 'DM Sans, sans-serif',
            fontSize: 16,
            boxShadow: canProceed() ? '0 4px 16px rgba(0, 230, 118, 0.25)' : 'none',
          }}
        >
          {step === TOTAL_STEPS - 1 ? (
            <>Analyze My Finances <Check size={18} /></>
          ) : (
            <>Continue <ChevronRight size={18} /></>
          )}
        </button>
      </div>
    </div>
  );
}

/* ─── Step sub-components ─── */

function StepPlatforms({ platforms, onToggle }: { platforms: Platform[]; onToggle: (p: Platform) => void }) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Which platforms do you work on?</h2>
      <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>Select all that apply. This helps us find your deductions.</p>
      <div className="grid grid-cols-2 gap-3">
        {(Object.keys(PLATFORM_CONFIG) as Platform[]).map(p => {
          const cfg = PLATFORM_CONFIG[p];
          const selected = platforms.includes(p);
          return (
            <button
              key={`platform-${p}`}
              onClick={() => onToggle(p)}
              className="flex items-center gap-3 p-4 rounded-2xl transition-all active:scale-95"
              style={{
                background: selected ? 'rgba(0, 230, 118, 0.1)' : '#1A1D23',
                border: selected ? '1px solid #00E676' : '1px solid #2A2D35',
                boxShadow: selected ? '0 0 12px rgba(0, 230, 118, 0.15)' : 'none',
              }}
            >
              <img 
                src={cfg.logo} 
                alt={cfg.label}
                className="w-8 h-8 object-contain"
              />
              <span className="text-sm font-medium" style={{ color: selected ? '#00E676' : '#F0F2F5' }}>
                {cfg.label}
              </span>
              {selected && (
                <div className="ml-auto w-5 h-5 rounded-full flex items-center justify-center" style={{ background: '#00E676' }}>
                  <Check size={12} color="#0D0F12" strokeWidth={3} />
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function StepEarnings({ value, onChange }: { value: number; onChange: (v: number) => void }) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Monthly earnings across all platforms?</h2>
      <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>Estimate your average monthly gross income.</p>
      <div className="flex flex-col gap-3">
        {EARNINGS_OPTIONS.map(opt => {
          const selected = value === opt.value;
          return (
            <button
              key={`earning-${opt.value}`}
              onClick={() => onChange(opt.value)}
              className="flex items-center justify-between p-4 rounded-2xl transition-all active:scale-95"
              style={{
                background: selected ? 'rgba(0, 230, 118, 0.1)' : '#1A1D23',
                border: selected ? '1px solid #00E676' : '1px solid #2A2D35',
              }}
            >
              <div className="text-left">
                <p className="font-semibold" style={{ color: selected ? '#00E676' : '#F0F2F5', fontFamily: 'DM Mono, monospace' }}>
                  {opt.label}
                </p>
                <p className="text-xs mt-0.5" style={{ color: '#8B90A0' }}>{opt.sublabel}</p>
              </div>
              {selected && (
                <div className="w-6 h-6 rounded-full flex items-center justify-center" style={{ background: '#00E676' }}>
                  <Check size={14} color="#0D0F12" strokeWidth={3} />
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function StepFilingStatus({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>What is your filing status?</h2>
      <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>This affects your standard deduction and tax brackets.</p>
      <div className="flex flex-col gap-3">
        {FILING_STATUS_OPTIONS.map(opt => {
          const selected = value === opt.value;
          return (
            <button
              key={`filing-${opt.value}`}
              onClick={() => onChange(opt.value)}
              className="flex items-start gap-4 p-4 rounded-2xl transition-all active:scale-95 text-left"
              style={{
                background: selected ? 'rgba(0, 230, 118, 0.1)' : '#1A1D23',
                border: selected ? '1px solid #00E676' : '1px solid #2A2D35',
              }}
            >
              <div
                className="w-5 h-5 rounded-full border-2 flex-shrink-0 mt-0.5 flex items-center justify-center"
                style={{ borderColor: selected ? '#00E676' : '#4A4F5C' }}
              >
                {selected && <div className="w-2.5 h-2.5 rounded-full" style={{ background: '#00E676' }} />}
              </div>
              <div>
                <p className="font-semibold text-sm" style={{ color: selected ? '#00E676' : '#F0F2F5' }}>{opt.label}</p>
                <p className="text-xs mt-0.5" style={{ color: '#8B90A0' }}>{opt.description}</p>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function StepDependents({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Do you have dependents?</h2>
      <p className="text-sm mb-8" style={{ color: '#8B90A0' }}>Children or qualifying relatives you support financially.</p>
      <div className="flex flex-col gap-4">
        {[
          { val: true, label: 'Yes', sublabel: 'I claim dependents on my return', emoji: '👨‍👧' },
          { val: false, label: 'No', sublabel: 'Filing without dependents', emoji: '👤' },
        ].map(opt => {
          const selected = value === opt.val;
          return (
            <button
              key={`dep-${opt.label}`}
              onClick={() => onChange(opt.val)}
              className="flex items-center gap-4 p-5 rounded-2xl transition-all active:scale-95"
              style={{
                background: selected ? 'rgba(0, 230, 118, 0.1)' : '#1A1D23',
                border: selected ? '1px solid #00E676' : '1px solid #2A2D35',
              }}
            >
              <span className="text-3xl">{opt.emoji}</span>
              <div className="text-left">
                <p className="font-bold text-lg" style={{ color: selected ? '#00E676' : '#F0F2F5' }}>{opt.label}</p>
                <p className="text-sm" style={{ color: '#8B90A0' }}>{opt.sublabel}</p>
              </div>
              {selected && (
                <div className="ml-auto w-6 h-6 rounded-full flex items-center justify-center" style={{ background: '#00E676' }}>
                  <Check size={14} color="#0D0F12" strokeWidth={3} />
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function StepState({ value, search, onSearchChange, onSelect, filteredStates }: {
  value: string;
  search: string;
  onSearchChange: (v: string) => void;
  onSelect: (v: string) => void;
  filteredStates: typeof US_STATES;
}) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Which state do you work in?</h2>
      <p className="text-sm mb-4" style={{ color: '#8B90A0' }}>State taxes vary significantly for gig workers.</p>
      {value && (
        <div className="mb-4 flex items-center gap-2 px-4 py-3 rounded-xl" style={{ background: 'rgba(0, 230, 118, 0.1)', border: '1px solid #00E676' }}>
          <Check size={16} color="#00E676" />
          <span className="font-semibold text-sm" style={{ color: '#00E676' }}>
            {US_STATES.find(s => s.code === value)?.name ?? value} selected
          </span>
        </div>
      )}
      <input
        type="text"
        placeholder="Search state..."
        value={search}
        onChange={e => onSearchChange(e.target.value)}
        className="w-full px-4 py-3 rounded-xl text-sm mb-3 outline-none"
        style={{
          background: '#1A1D23',
          border: '1px solid #2A2D35',
          color: '#F0F2F5',
          fontFamily: 'DM Sans, sans-serif',
        }}
      />
      <div className="overflow-y-auto" style={{ maxHeight: 320 }}>
        {filteredStates.map(s => (
          <button
            key={`state-${s.code}`}
            onClick={() => onSelect(s.code)}
            className="w-full flex items-center justify-between px-4 py-3 rounded-xl mb-1.5 transition-all active:scale-95"
            style={{
              background: value === s.code ? 'rgba(0, 230, 118, 0.1)' : 'transparent',
              border: value === s.code ? '1px solid rgba(0, 230, 118, 0.4)' : '1px solid transparent',
            }}
          >
            <span className="text-sm" style={{ color: value === s.code ? '#00E676' : '#F0F2F5' }}>
              {s.name}
            </span>
            <span className="text-xs font-mono" style={{ color: '#8B90A0', fontFamily: 'DM Mono, monospace' }}>
              {s.code}
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}

function StepHousing({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Do you own or rent your home?</h2>
      <p className="text-sm mb-8" style={{ color: '#8B90A0' }}>Affects home office deduction calculations.</p>
      <div className="flex flex-col gap-4">
        {[
          { val: 'own', label: 'I own my home', emoji: '🏠', desc: 'Mortgage interest may be deductible' },
          { val: 'rent', label: 'I rent', emoji: '🏢', desc: 'Portion of rent may be deductible' },
        ].map(opt => {
          const selected = value === opt.val;
          return (
            <button
              key={`housing-${opt.val}`}
              onClick={() => onChange(opt.val)}
              className="flex items-center gap-4 p-5 rounded-2xl transition-all active:scale-95"
              style={{
                background: selected ? 'rgba(0, 230, 118, 0.1)' : '#1A1D23',
                border: selected ? '1px solid #00E676' : '1px solid #2A2D35',
              }}
            >
              <span className="text-3xl">{opt.emoji}</span>
              <div className="text-left">
                <p className="font-bold" style={{ color: selected ? '#00E676' : '#F0F2F5' }}>{opt.label}</p>
                <p className="text-sm mt-0.5" style={{ color: '#8B90A0' }}>{opt.desc}</p>
              </div>
              {selected && (
                <div className="ml-auto w-6 h-6 rounded-full flex items-center justify-center" style={{ background: '#00E676' }}>
                  <Check size={14} color="#0D0F12" strokeWidth={3} />
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function StepHomeOffice({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Do you use part of your home for work?</h2>
      <p className="text-sm mb-8" style={{ color: '#8B90A0' }}>A dedicated home office space qualifies for the home office deduction.</p>
      <div className="flex flex-col gap-4">
        {[
          { val: true, label: 'Yes, I have a home office', emoji: '💻', desc: 'Dedicated workspace in my home' },
          { val: false, label: 'No home office', emoji: '🚗', desc: 'I work primarily on the road' },
        ].map(opt => {
          const selected = value === opt.val;
          return (
            <button
              key={`office-${String(opt.val)}`}
              onClick={() => onChange(opt.val)}
              className="flex items-center gap-4 p-5 rounded-2xl transition-all active:scale-95"
              style={{
                background: selected ? 'rgba(0, 230, 118, 0.1)' : '#1A1D23',
                border: selected ? '1px solid #00E676' : '1px solid #2A2D35',
              }}
            >
              <span className="text-3xl">{opt.emoji}</span>
              <div className="text-left">
                <p className="font-bold" style={{ color: selected ? '#00E676' : '#F0F2F5' }}>{opt.label}</p>
                <p className="text-sm mt-0.5" style={{ color: '#8B90A0' }}>{opt.desc}</p>
              </div>
              {selected && (
                <div className="ml-auto w-6 h-6 rounded-full flex items-center justify-center" style={{ background: '#00E676' }}>
                  <Check size={14} color="#0D0F12" strokeWidth={3} />
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function StepVehicle({ value, onChange }: { value: string; onChange: (v: string) => void }) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>What type of vehicle do you use?</h2>
      <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>Used to calculate your mileage deduction rate.</p>
      <div className="flex gap-3 overflow-x-auto pb-3 scrollbar-hide">
        {(Object.entries(VEHICLE_CONFIG) as [VehicleType, typeof VEHICLE_CONFIG[VehicleType]][]).map(([key, cfg]) => {
          const selected = value === key;
          return (
            <button
              key={`vehicle-${key}`}
              onClick={() => onChange(key)}
              className="flex-shrink-0 flex flex-col items-center gap-2 p-4 rounded-2xl transition-all active:scale-95"
              style={{
                width: 100,
                background: selected ? 'rgba(0, 230, 118, 0.1)' : '#1A1D23',
                border: selected ? '1px solid #00E676' : '1px solid #2A2D35',
              }}
            >
              <span className="text-3xl">{cfg.emoji}</span>
              <span className="text-xs font-medium text-center" style={{ color: selected ? '#00E676' : '#F0F2F5' }}>
                {cfg.label}
              </span>
              {cfg.mileageRate > 0 && (
                <span className="text-xs font-mono" style={{ color: '#8B90A0', fontFamily: 'DM Mono, monospace' }}>
                  ${cfg.mileageRate}/mi
                </span>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function StepExpenses({
  expenses,
  labels,
  onChange,
}: {
  expenses: UserProfile['expenses'];
  labels: Record<string, string>;
  onChange: (key: string, val: number) => void;
}) {
  return (
    <div className="pt-4">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Monthly business expenses</h2>
      <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>Drag sliders to estimate your monthly costs. These become deductions.</p>
      <div className="flex flex-col gap-5">
        {(Object.entries(expenses) as [string, number][]).map(([key, val]) => (
          <div key={`exp-${key}`}>
            <div className="flex justify-between items-center mb-2">
              <span className="text-sm font-medium" style={{ color: '#F0F2F5' }}>{labels[key]}</span>
              <span className="text-sm font-mono" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
                ${val}/mo
              </span>
            </div>
            <input
              type="range"
              min={0}
              max={key === 'gas' ? 600 : key === 'health' ? 800 : key === 'insurance' ? 400 : 300}
              step={10}
              value={val}
              onChange={e => onChange(key, Number(e.target.value))}
              style={{
                background: `linear-gradient(to right, #00E676 0%, #00E676 ${(val / (key === 'gas' ? 600 : key === 'health' ? 800 : key === 'insurance' ? 400 : 300)) * 100}%, #2A2D35 ${(val / (key === 'gas' ? 600 : key === 'health' ? 800 : key === 'insurance' ? 400 : 300)) * 100}%, #2A2D35 100%)`,
              }}
              aria-label={labels[key]}
            />
          </div>
        ))}
      </div>
    </div>
  );
}

function StepReview({ profile, platforms }: { profile: UserProfile['expenses'] & any; platforms: Platform[] }) {
  const annualEst = (profile.monthlyEarnings ?? 0) * 12;
  return (
    <div className="pt-4 pb-6">
      <h2 className="text-2xl font-bold mb-1" style={{ color: '#F0F2F5' }}>Ready to analyze your finances</h2>
      <p className="text-sm mb-6" style={{ color: '#8B90A0' }}>Here is a summary of your profile. Tap Analyze to get your personalized tax plan.</p>
      <div className="flex flex-col gap-3">
        <div className="p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
          <p className="text-xs mb-2 uppercase tracking-wider" style={{ color: '#8B90A0' }}>Platforms</p>
          <div className="flex flex-wrap gap-2">
            {platforms.map((p: Platform) => (
              <span key={`rev-plat-${p}`} className="text-xs px-3 py-1 rounded-full flex items-center gap-2" style={{ background: 'rgba(0,230,118,0.1)', color: '#00E676', border: '1px solid rgba(0,230,118,0.2)' }}>
                <img 
                  src={PLATFORM_CONFIG[p]?.logo} 
                  alt={PLATFORM_CONFIG[p]?.label}
                  className="w-4 h-4 object-contain"
                />
                {PLATFORM_CONFIG[p]?.label}
              </span>
            ))}
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div className="p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
            <p className="text-xs mb-1" style={{ color: '#8B90A0' }}>Est. Annual</p>
            <p className="text-lg font-bold font-mono" style={{ color: '#00E676', fontFamily: 'DM Mono, monospace' }}>
              ${annualEst.toLocaleString()}
            </p>
          </div>
          <div className="p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
            <p className="text-xs mb-1" style={{ color: '#8B90A0' }}>State</p>
            <p className="text-lg font-bold" style={{ color: '#F0F2F5' }}>{profile.state || '—'}</p>
          </div>
          <div className="p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
            <p className="text-xs mb-1" style={{ color: '#8B90A0' }}>Filing Status</p>
            <p className="text-sm font-medium capitalize" style={{ color: '#F0F2F5' }}>
              {profile.filingStatus?.replace(/_/g, ' ')}
            </p>
          </div>
          <div className="p-4 rounded-2xl" style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}>
            <p className="text-xs mb-1" style={{ color: '#8B90A0' }}>Vehicle</p>
            <p className="text-sm font-medium" style={{ color: '#F0F2F5' }}>
              {VEHICLE_CONFIG[profile.vehicleType as VehicleType]?.emoji} {VEHICLE_CONFIG[profile.vehicleType as VehicleType]?.label}
            </p>
          </div>
        </div>
        <div className="p-4 rounded-2xl" style={{ background: 'rgba(0, 230, 118, 0.05)', border: '1px solid rgba(0, 230, 118, 0.2)' }}>
          <p className="text-xs font-medium" style={{ color: '#00E676' }}>
            ✨ AI analysis will identify your personalized deductions and quarterly tax schedule
          </p>
        </div>
      </div>
    </div>
  );
}
