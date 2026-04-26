/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['DM Sans', 'sans-serif'],
        mono: ['DM Mono', 'monospace'],
      },
      colors: {
        'bg-base': '#0D0F12',
        'bg-card': '#1A1D23',
        'bg-elevated': '#22262E',
        'bg-input': '#2A2D35',
        'accent-green': '#00E676',
        'accent-green-dim': '#00C853',
        'accent-teal': '#1DE9B6',
        'accent-amber': '#FFB300',
        'accent-red': '#FF5252',
        'accent-blue': '#448AFF',
        'text-primary': '#F0F2F5',
        'text-secondary': '#8B90A0',
        'text-muted': '#4A4F5C',
        'border-subtle': '#2A2D35',
        'border-medium': '#363A45',
      },
      borderRadius: {
        '2xl': '16px',
        '3xl': '24px',
      },
      screens: {
        xs: '390px',
      },
    },
  },
  plugins: [],
};