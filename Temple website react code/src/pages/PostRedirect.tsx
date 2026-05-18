/**
 * PostRedirect.tsx
 *
 * When a user opens a namoham.com/post/<id> link in a browser (instead of the
 * Android app), we immediately bounce them to the Google Play Store listing so
 * they can install / open the Temple app.
 *
 * Android users who already have the app installed will never reach this page —
 * Android App Links will hand the URL directly to the app before the browser
 * has a chance to navigate.
 */

import { useEffect, CSSProperties } from 'react';
import { useParams } from 'react-router-dom';

const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.abhitreader.temple';

export default function PostRedirect() {
  const { id } = useParams<{ id: string }>();

  useEffect(() => {
    // Give the page a moment to paint the fallback UI, then redirect.
    const timer = setTimeout(() => {
      window.location.href = PLAY_STORE_URL;
    }, 1500);
    return () => clearTimeout(timer);
  }, [id]);

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        {/* Saffron flame / lotus icon placeholder */}
        <div style={styles.icon}>🪷</div>
        <h1 style={styles.heading}>Opening in Namoham Temple</h1>
        <p style={styles.sub}>
          If the app doesn't open automatically, tap the button below to get it
          from the Play Store.
        </p>
        <a href={PLAY_STORE_URL} style={styles.button}>
          <img
            src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
            alt="Get it on Google Play"
            style={styles.badge}
          />
        </a>
        <p style={styles.note}>Redirecting you automatically…</p>
      </div>
    </div>
  );
}

/* ─── inline styles (no build-time dependency on Tailwind / CSS modules) ─── */
const styles: Record<string, CSSProperties> = {
  container: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'linear-gradient(135deg, #1a0a00 0%, #3b1600 60%, #1a0a00 100%)',
    fontFamily: "'Inter', 'Segoe UI', sans-serif",
    padding: '1rem',
  },
  card: {
    background: 'rgba(255,255,255,0.05)',
    border: '1px solid rgba(255,165,0,0.25)',
    borderRadius: '1.5rem',
    padding: '3rem 2.5rem',
    maxWidth: '420px',
    width: '100%',
    textAlign: 'center',
    backdropFilter: 'blur(12px)',
    boxShadow: '0 8px 40px rgba(0,0,0,0.6)',
  },
  icon: {
    fontSize: '4rem',
    marginBottom: '1rem',
  },
  heading: {
    color: '#fbbf24',
    fontSize: '1.5rem',
    fontWeight: 700,
    margin: '0 0 0.75rem',
  },
  sub: {
    color: '#d1d5db',
    fontSize: '0.95rem',
    lineHeight: 1.6,
    margin: '0 0 1.5rem',
  },
  button: {
    display: 'inline-block',
    marginBottom: '1.25rem',
  },
  badge: {
    height: '60px',
    borderRadius: '8px',
  },
  note: {
    color: '#9ca3af',
    fontSize: '0.8rem',
    margin: 0,
  },
};
