'use client';
import React from 'react';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, ReferenceLine,
} from 'recharts';

interface DataPoint {
  month: string;
  earnings: number;
  projected: number;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{ value: number; name: string; dataKey: string }>;
  label?: string;
}

function CustomTooltip({ active, payload, label }: CustomTooltipProps) {
  if (!active || !payload?.length) return null;
  const actual = payload.find(p => p.dataKey === 'earnings');
  const projected = payload.find(p => p.dataKey === 'projected');
  const val = actual?.value || projected?.value || 0;
  const isProjected = !actual?.value && projected?.value;

  return (
    <div className="px-3 py-2 rounded-xl" style={{ background: '#22262E', border: '1px solid #363A45', boxShadow: '0 4px 16px rgba(0,0,0,0.4)' }}>
      <p className="text-xs mb-1" style={{ color: '#8B90A0', fontFamily: 'DM Sans, sans-serif' }}>{label}</p>
      <p className="font-mono font-bold text-sm" style={{ color: isProjected ? '#8B90A0' : '#00E676', fontFamily: 'DM Mono, monospace' }}>
        ${val.toLocaleString()}
      </p>
      {isProjected && <p className="text-xs" style={{ color: '#8B90A0' }}>Projected</p>}
    </div>
  );
}

export default function EarningsChart({ data }: { data: DataPoint[] }) {
  const currentMonth = new Date().getMonth();
  const currentMonthLabel = data[currentMonth]?.month;

  return (
    <ResponsiveContainer width="100%" height={180}>
      <AreaChart data={data} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
        <defs>
          <linearGradient id="earningsGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#00E676" stopOpacity={0.3} />
            <stop offset="95%" stopColor="#00E676" stopOpacity={0} />
          </linearGradient>
          <linearGradient id="projectedGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#4A4F5C" stopOpacity={0.2} />
            <stop offset="95%" stopColor="#4A4F5C" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#2A2D35" vertical={false} />
        <XAxis
          dataKey="month"
          tick={{ fill: '#4A4F5C', fontSize: 11, fontFamily: 'DM Mono, monospace' }}
          axisLine={false}
          tickLine={false}
        />
        <YAxis
          tick={{ fill: '#4A4F5C', fontSize: 10, fontFamily: 'DM Mono, monospace' }}
          axisLine={false}
          tickLine={false}
          tickFormatter={v => v === 0 ? '' : `$${(v / 1000).toFixed(0)}k`}
        />
        <Tooltip content={<CustomTooltip />} />
        {currentMonthLabel && (
          <ReferenceLine x={currentMonthLabel} stroke="#00E676" strokeDasharray="4 4" strokeOpacity={0.4} />
        )}
        <Area
          type="monotone"
          dataKey="earnings"
          stroke="#00E676"
          strokeWidth={2}
          fill="url(#earningsGrad)"
          dot={false}
          activeDot={{ r: 4, fill: '#00E676', strokeWidth: 0 }}
        />
        <Area
          type="monotone"
          dataKey="projected"
          stroke="#4A4F5C"
          strokeWidth={1.5}
          strokeDasharray="4 4"
          fill="url(#projectedGrad)"
          dot={false}
          activeDot={{ r: 3, fill: '#4A4F5C', strokeWidth: 0 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}