import type { Platform, VehicleType } from '../context/UserProfileContext';

export const PLATFORM_CONFIG: Record<Platform, { label: string; color: string; logo: string; bgColor: string }> = {
  uber: { label: 'Uber', color: '#FFFFFF', logo: '/assets/logos/uber.jpg', bgColor: '#000000' },
  lyft: { label: 'Lyft', color: '#FF00BF', logo: '/assets/logos/lyft.jpg', bgColor: '#1A0A1A' },
  doordash: { label: 'DoorDash', color: '#FF3008', logo: '/assets/logos/doordash.jpg', bgColor: '#1A0A08' },
  instacart: { label: 'Instacart', color: '#43B02A', logo: '/assets/logos/instacart.jpg', bgColor: '#0A1A0A' },
  upwork: { label: 'Upwork', color: '#6FDA44', logo: '/assets/logos/upwork.jpg', bgColor: '#0A1A08' },
  fiverr: { label: 'Fiverr', color: '#1DBF73', logo: '/assets/logos/fiverr.jpg', bgColor: '#081A10' },
  amazon_flex: { label: 'Amazon Flex', color: '#FF9900', logo: '/assets/logos/amazon_flex.jpg', bgColor: '#1A1008' },
  grubhub: { label: 'Grubhub', color: '#F63440', logo: '/assets/logos/grubhub.jpg', bgColor: '#1A0808' },
  taskrabbit: { label: 'TaskRabbit', color: '#5D8A3C', logo: '/assets/logos/taskrabbit.jpg', bgColor: '#0A130A' },
  rover: { label: 'Rover', color: '#15A800', logo: '/assets/logos/rover.jpg', bgColor: '#081508' },
};

export const VEHICLE_CONFIG: Record<VehicleType, { label: string; emoji: string; mileageRate: number }> = {
  car: { label: 'Car', emoji: '🚗', mileageRate: 0.67 },
  suv: { label: 'SUV', emoji: '🚙', mileageRate: 0.67 },
  truck: { label: 'Truck', emoji: '🛻', mileageRate: 0.67 },
  motorcycle: { label: 'Motorcycle', emoji: '🏍️', mileageRate: 0.21 },
  bicycle: { label: 'Bicycle', emoji: '🚲', mileageRate: 0.0 },
  none: { label: 'No Vehicle', emoji: '🚶', mileageRate: 0.0 },
};

export const US_STATES = [
  { code: 'AL', name: 'Alabama' }, { code: 'AK', name: 'Alaska' }, { code: 'AZ', name: 'Arizona' },
  { code: 'AR', name: 'Arkansas' }, { code: 'CA', name: 'California' }, { code: 'CO', name: 'Colorado' },
  { code: 'CT', name: 'Connecticut' }, { code: 'DE', name: 'Delaware' }, { code: 'FL', name: 'Florida' },
  { code: 'GA', name: 'Georgia' }, { code: 'HI', name: 'Hawaii' }, { code: 'ID', name: 'Idaho' },
  { code: 'IL', name: 'Illinois' }, { code: 'IN', name: 'Indiana' }, { code: 'IA', name: 'Iowa' },
  { code: 'KS', name: 'Kansas' }, { code: 'KY', name: 'Kentucky' }, { code: 'LA', name: 'Louisiana' },
  { code: 'ME', name: 'Maine' }, { code: 'MD', name: 'Maryland' }, { code: 'MA', name: 'Massachusetts' },
  { code: 'MI', name: 'Michigan' }, { code: 'MN', name: 'Minnesota' }, { code: 'MS', name: 'Mississippi' },
  { code: 'MO', name: 'Missouri' }, { code: 'MT', name: 'Montana' }, { code: 'NE', name: 'Nebraska' },
  { code: 'NV', name: 'Nevada' }, { code: 'NH', name: 'New Hampshire' }, { code: 'NJ', name: 'New Jersey' },
  { code: 'NM', name: 'New Mexico' }, { code: 'NY', name: 'New York' }, { code: 'NC', name: 'North Carolina' },
  { code: 'ND', name: 'North Dakota' }, { code: 'OH', name: 'Ohio' }, { code: 'OK', name: 'Oklahoma' },
  { code: 'OR', name: 'Oregon' }, { code: 'PA', name: 'Pennsylvania' }, { code: 'RI', name: 'Rhode Island' },
  { code: 'SC', name: 'South Carolina' }, { code: 'SD', name: 'South Dakota' }, { code: 'TN', name: 'Tennessee' },
  { code: 'TX', name: 'Texas' }, { code: 'UT', name: 'Utah' }, { code: 'VT', name: 'Vermont' },
  { code: 'VA', name: 'Virginia' }, { code: 'WA', name: 'Washington' }, { code: 'WV', name: 'West Virginia' },
  { code: 'WI', name: 'Wisconsin' }, { code: 'WY', name: 'Wyoming' },
];

export const EARNINGS_OPTIONS = [
  { label: 'Under $1,500', value: 1250, sublabel: 'Part-time hustle' },
  { label: '$1,500 – $3,000', value: 2250, sublabel: 'Side income' },
  { label: '$3,000 – $5,000', value: 4000, sublabel: 'Primary income' },
  { label: '$5,000 – $8,000', value: 6500, sublabel: 'Full-time gig' },
  { label: '$8,000+', value: 9000, sublabel: 'Power earner' },
];

export const FILING_STATUS_OPTIONS = [
  { value: 'single', label: 'Single', description: 'Not married, no qualifying dependents' },
  { value: 'married_joint', label: 'Married Filing Jointly', description: 'Married, filing with spouse' },
  { value: 'married_separate', label: 'Married Filing Separately', description: 'Married, filing independently' },
  { value: 'head_of_household', label: 'Head of Household', description: 'Unmarried with qualifying dependents' },
];

export const QUARTERLY_DEADLINES = [
  { quarter: 'Q1', label: 'Jan 1 – Mar 31', deadline: 'Apr 15, 2025', status: 'paid' },
  { quarter: 'Q2', label: 'Apr 1 – May 31', deadline: 'Jun 17, 2025', status: 'upcoming' },
  { quarter: 'Q3', label: 'Jun 1 – Aug 31', deadline: 'Sep 16, 2025', status: 'future' },
  { quarter: 'Q4', label: 'Sep 1 – Dec 31', deadline: 'Jan 15, 2026', status: 'future' },
];
