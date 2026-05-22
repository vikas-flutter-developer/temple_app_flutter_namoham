/**
 * PostRedirect.tsx
 *
 * Flow when a user opens namoham.com/post/<id> in a browser:
 *
 * 1. BEST CASE  — Android App Links verified:
 *    Android intercepts the URL *before* the browser opens → Temple app
 *    launches directly with the post. This page is never shown.
 *
 * 2. GOOD CASE  — App installed, App Links not yet verified:
 *    Browser opens this page. We immediately try the custom scheme
 *    templeapp://post/<id>. If the app is installed Android will open it
 *    and navigate straight to the post.
 *
 * 3. FALLBACK   — App not installed:
 *    The custom-scheme attempt silently fails (no app handles it).
 *    After 2.5 s we redirect to the Play Store.
 */

import { useEffect, useState, CSSProperties } from 'react';
import { useParams } from 'react-router-dom';

const PLAY_STORE_URL =
  'https://play.google.com/store/apps/details?id=com.abhitreader.temple&pcampaignid=web_share';

const APP_SCHEME = 'templeapp';

export default function PostRedirect() {
  const { id } = useParams<{ id: string }>();
  const [status, setStatus] = useState<'trying' | 'fallback'>('trying');

  useEffect(() => {
    if (!id) return;

    // ── Step 1: Try to open the installed app via the custom URI scheme ──────
    // This is a fire-and-forget attempt; if the app is installed Android will
    // intercept it and we never see the Play-Store redirect below.
    const appUrl = `${APP_SCHEME}://post/${id}`;
    window.location.href = appUrl;

    // ── Step 2: Fallback to Play Store after a short wait ────────────────────
    // If the app is NOT installed the custom scheme silently fails and the
    // page stays open. After 2.5 s we send the user to the Play Store.
    const fallbackTimer = setTimeout(() => {
      setStatus('fallback');
      window.location.href = PLAY_STORE_URL;
    }, 2500);

    return () => clearTimeout(fallbackTimer);
  }, [id]);

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        <div style={styles.icon}>🪷</div>
        <h1 style={styles.heading}>Opening in Namoham</h1>

        {status === 'trying' ? (
          <>
            <p style={styles.sub}>
              Opening the post in the <strong>Namoham Temple app</strong>…
            </p>
            <div style={styles.spinner} />
            <p style={styles.note}>
              Don't have the app?&nbsp;
              <a href={PLAY_STORE_URL} style={styles.link}>
                Get it on Google Play
              </a>
            </p>
          </>
        ) : (
          <>
            <p style={styles.sub}>
              Redirecting you to the Play Store to install the app…
            </p>
            <a href={PLAY_STORE_URL} style={styles.button}>
              <img
                src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
                alt="Get it on Google Play"
                style={styles.badge}
              />
            </a>
          </>
        )}
      </div>
    </div>
  );
}

/* ─── styles ─────────────────────────────────────────────────────────────── */
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
  spinner: {
    width: '36px',
    height: '36px',
    border: '3px solid rgba(251,191,36,0.2)',
    borderTop: '3px solid #fbbf24',
    borderRadius: '50%',
    animation: 'spin 0.8s linear infinite',
    margin: '0 auto 1.5rem',
  },
  note: {
    color: '#9ca3af',
    fontSize: '0.85rem',
    margin: 0,
  },
  link: {
    color: '#fbbf24',
    textDecoration: 'underline',
  },
  button: {
    display: 'inline-block',
    marginBottom: '1.25rem',
  },
  badge: {
    height: '60px',
    borderRadius: '8px',
  },
};
