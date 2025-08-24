/**
 * @file
 * @copyright 2025
 * @license MIT
 */

import { useEffect } from 'react';

import { useBackend } from '../backend';

/**
 * Hook for applying UI Scale through TGUI's built-in scaling system
 * 
 * Applies scaling via multiple methods:
 * - --scaling-amount CSS variable for vp() functions
 * - --tgui-scale CSS variable for content containers
 * - font-size adjustment for rem-based elements
 */
export function useUiScale() {
  const { config } = useBackend();
  // Safely get ui_scale data with type checking
  const uiScale = (config as any)?.ui_scale;

  useEffect(() => {
    // Apply UI Scale only when enabled
    if (uiScale?.enabled && uiScale?.value) {
      // Set --scaling-amount for vp() functions
      document.documentElement.style.setProperty(
        '--scaling-amount',
        String(uiScale.value),
      );
      // Set --tgui-scale for content containers
      document.documentElement.style.setProperty(
        '--tgui-scale',
        String(uiScale.value),
      );
      // Apply scaling to base font size for rem-based elements
      document.documentElement.style.fontSize = `${12 * uiScale.value}px`;
    } else {
      // Reset to default values
      document.documentElement.style.setProperty('--scaling-amount', '1');
      document.documentElement.style.setProperty('--tgui-scale', '1');
      document.documentElement.style.fontSize = '12px';
    }

    return () => {
      // Cleanup on unmount
      document.documentElement.style.setProperty('--scaling-amount', '1');
      document.documentElement.style.setProperty('--tgui-scale', '1');
      document.documentElement.style.fontSize = '12px';
    };
  }, [uiScale?.enabled, uiScale?.value]);
}
