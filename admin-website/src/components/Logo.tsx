/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';

export const LogoIcon = ({ className = "w-10 h-10" }: { className?: string }) => {
  return (
    <svg 
      viewBox="0 0 120 120" 
      fill="none" 
      xmlns="http://www.w3.org/2000/svg" 
      className={className}
    >
      {/* Precision recreation of the provided logo geometry */}
      
      {/* Central Droplet with Tiered Spire */}
      <path 
        d="M60 25C60 25 50 45 50 62C50 78 60 85 60 85C60 85 70 78 70 62C70 45 60 25 60 25Z" 
        stroke="currentColor" 
        strokeWidth="3" 
        strokeLinejoin="round"
        className="text-brand-primary"
      />
      {/* Tiered Temple Spire Detail */}
      <path d="M60 38V50" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" className="text-brand-primary" />
      <path d="M57 48H63" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-brand-primary" />
      <path d="M55 53H65" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-brand-primary" />
      <path d="M53 58H67" stroke="currentColor" strokeWidth="2" strokeLinecap="round" className="text-brand-primary" />

      {/* Outer Petals Left */}
      <path 
        d="M50 60C35 55 30 75 40 95C48 90 50 80 50 65" 
        stroke="currentColor" 
        strokeWidth="3.5" 
        strokeLinecap="round"
        strokeLinejoin="round" 
        className="text-brand-primary"
      />
      
      {/* Outer Petals Right */}
      <path 
        d="M70 60C85 55 90 75 80 95C72 90 70 80 70 65" 
        stroke="currentColor" 
        strokeWidth="3.5" 
        strokeLinecap="round"
        strokeLinejoin="round" 
        className="text-brand-primary"
      />

      {/* Bottom Joining Curve */}
      <path 
        d="M44 92C52 98 68 98 76 92" 
        stroke="currentColor" 
        strokeWidth="3.5" 
        strokeLinecap="round"
        className="text-brand-primary"
      />
    </svg>
  );
};

export const LogoBrand = ({ horizontal = false }: { horizontal?: boolean }) => {
  if (horizontal) {
    return (
      <div className="flex items-center gap-3">
        <LogoIcon className="w-10 h-10" />
        <span className="text-xl font-brand font-bold tracking-[0.2em] text-brand-primary uppercase">
          Namoham
        </span>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center gap-3">
      <LogoIcon className="w-16 h-16 sm:w-24 sm:h-24" />
      <span className="text-2xl sm:text-3xl font-brand font-bold tracking-[0.23em] text-brand-primary uppercase leading-none">
        Namoham
      </span>
    </div>
  );
};
