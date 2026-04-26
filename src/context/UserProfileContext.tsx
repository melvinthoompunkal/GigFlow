'use client';
import React, { createContext, useContext, useState, useCallback, ReactNode } from 'react';

export type Platform = 'uber' | 'lyft' | 'doordash' | 'instacart' | 'upwork' | 'fiverr' | 'amazon_flex' | 'grubhub' | 'taskrabbit' | 'rover';
export type FilingStatus = 'single' | 'married_joint' | 'married_separate' | 'head_of_household';
export type VehicleType = 'car' | 'suv' | 'truck' | 'motorcycle' | 'bicycle' | 'none';
export type HousingType = 'own' | 'rent';

export interface Deduction {
  id: string;
  icon: string;
  name: string;
  explanation: string;
  value: number;
  eligibility: 'high' | 'medium' | 'low';
  category: string;
}

export interface TaxEstimate {
  selfEmployment: number;
  federal: number;
  state: number;
  total: number;
  monthly: number;
  quarterly: number;
}

export interface RoadmapStep {
  id: string;
  step: number;
  title: string;
  description: string;
  deadline: string;
  priority: 'high' | 'medium' | 'low';
  completed: boolean;
}

export interface UserProfile {
  platforms: Platform[];
  monthlyEarnings: number;
  filingStatus: FilingStatus;
  hasDependents: boolean;
  state: string;
  housingType: HousingType;
  hasHomeOffice: boolean;
  vehicleType: VehicleType;
  expenses: {
    gas: number;
    phone: number;
    insurance: number;
    equipment: number;
    health: number;
    food: number;
  };
  claudeAnalysis: {
    deductions: Deduction[];
    taxEstimate: TaxEstimate;
    roadmap: RoadmapStep[];
  } | null;
  isOnboarded: boolean;
  isDemoMode: boolean;
}

const defaultProfile: UserProfile = {
  platforms: [],
  monthlyEarnings: 0,
  filingStatus: 'single',
  hasDependents: false,
  state: '',
  housingType: 'rent',
  hasHomeOffice: false,
  vehicleType: 'car',
  expenses: { gas: 0, phone: 0, insurance: 0, equipment: 0, health: 0, food: 0 },
  claudeAnalysis: null,
  isOnboarded: false,
  isDemoMode: false,
};

// Backend integration point: Replace with API call to fetch user profile
const FALLBACK_DEDUCTIONS: Deduction[] = [
  { id: 'ded-mileage', icon: '🚗', name: 'Standard Mileage Deduction', explanation: 'Deduct 67¢ per mile driven for gig work in 2024. Based on your vehicle type and estimated annual mileage.', value: 3685, eligibility: 'high', category: 'Vehicle' },
  { id: 'ded-phone', icon: '📱', name: 'Phone & Data Plan', explanation: 'Business-use portion of your phone bill. Gig apps require a phone — typically 80-90% deductible.', value: 540, eligibility: 'high', category: 'Technology' },
  { id: 'ded-se-tax', icon: '🏛️', name: 'Self-Employment Tax Deduction', explanation: 'Deduct 50% of your SE tax from gross income. This reduces your adjusted gross income automatically.', value: 1834, eligibility: 'high', category: 'Tax' },
  { id: 'ded-qbi', icon: '💼', name: 'Qualified Business Income (QBI)', explanation: 'Deduct up to 20% of qualified business income under Section 199A. Significant savings for sole proprietors.', value: 2160, eligibility: 'medium', category: 'Business' },
  { id: 'ded-health', icon: '🏥', name: 'Self-Employed Health Insurance', explanation: 'Deduct 100% of health insurance premiums if you are not eligible for employer coverage.', value: 1800, eligibility: 'medium', category: 'Health' },
  { id: 'ded-sep-ira', icon: '🏦', name: 'SEP-IRA Contribution', explanation: 'Contribute up to 25% of net self-employment income to a SEP-IRA and deduct the full amount.', value: 3600, eligibility: 'medium', category: 'Retirement' },
];

const FALLBACK_TAX_ESTIMATE: TaxEstimate = {
  selfEmployment: 6786,
  federal: 3240,
  state: 1296,
  total: 11322,
  monthly: 944,
  quarterly: 2830,
};

const FALLBACK_ROADMAP: RoadmapStep[] = [
  { id: 'rm-1', step: 1, title: 'Open a dedicated business checking account', description: 'Separate your gig income from personal funds. Makes bookkeeping 10x easier and strengthens deduction claims.', deadline: 'This week', priority: 'high', completed: false },
  { id: 'rm-2', step: 2, title: 'Set up automatic tax savings transfer', description: 'Auto-transfer 25% of every deposit to a high-yield savings account earmarked for quarterly taxes.', deadline: 'Within 2 weeks', priority: 'high', completed: false },
  { id: 'rm-3', step: 3, title: 'Start tracking mileage with an app', description: 'Use MileIQ or Everlance to auto-track every business mile. This deduction alone saves you $3,685.', deadline: 'Within 30 days', priority: 'medium', completed: false },
  { id: 'rm-4', step: 4, title: 'File Q2 estimated taxes', description: 'Pay your Q2 estimated taxes by June 17, 2025 to avoid underpayment penalties. Amount: $2,830.', deadline: 'Jun 17, 2025', priority: 'high', completed: false },
];

const DEMO_PROFILE: Partial<UserProfile> = {
  platforms: ['uber', 'doordash', 'lyft'],
  monthlyEarnings: 4200,
  filingStatus: 'single',
  hasDependents: false,
  state: 'CA',
  housingType: 'rent',
  hasHomeOffice: true,
  vehicleType: 'car',
  expenses: { gas: 280, phone: 65, insurance: 150, equipment: 40, health: 180, food: 0 },
  isOnboarded: true,
  isDemoMode: true,
};

interface UserProfileContextType {
  profile: UserProfile;
  updateProfile: (updates: Partial<UserProfile>) => void;
  setAnalysis: (analysis: UserProfile['claudeAnalysis']) => void;
  activateDemoMode: () => void;
  resetProfile: () => void;
}

const UserProfileContext = createContext<UserProfileContextType | null>(null);

export function UserProfileProvider({ children }: { children: ReactNode }) {
  const [profile, setProfile] = useState<UserProfile>(defaultProfile);

  const updateProfile = useCallback((updates: Partial<UserProfile>) => {
    setProfile(prev => ({ ...prev, ...updates }));
  }, []);

  const setAnalysis = useCallback((analysis: UserProfile['claudeAnalysis']) => {
    setProfile(prev => ({ ...prev, claudeAnalysis: analysis }));
  }, []);

  const activateDemoMode = useCallback(() => {
    setProfile(prev => ({
      ...prev,
      ...DEMO_PROFILE,
      claudeAnalysis: {
        deductions: FALLBACK_DEDUCTIONS,
        taxEstimate: FALLBACK_TAX_ESTIMATE,
        roadmap: FALLBACK_ROADMAP,
      },
    }));
  }, []);

  const resetProfile = useCallback(() => {
    setProfile(defaultProfile);
  }, []);

  return (
    <UserProfileContext.Provider value={{ profile, updateProfile, setAnalysis, activateDemoMode, resetProfile }}>
      {children}
    </UserProfileContext.Provider>
  );
}

export function useUserProfile() {
  const ctx = useContext(UserProfileContext);
  if (!ctx) throw new Error('useUserProfile must be used within UserProfileProvider');
  return ctx;
}

export { FALLBACK_DEDUCTIONS, FALLBACK_TAX_ESTIMATE, FALLBACK_ROADMAP };