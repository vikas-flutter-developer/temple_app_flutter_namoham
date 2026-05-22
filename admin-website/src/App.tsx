/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage.tsx';
import LegalPage from './pages/LegalPage.tsx';
import PostRedirect from './pages/PostRedirect.tsx';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/legal/:type" element={<LegalPage />} />
        {/* Android App Links fallback: redirects browser visitors to Play Store */}
        <Route path="/post/:id" element={<PostRedirect />} />
      </Routes>
    </BrowserRouter>
  );
}
