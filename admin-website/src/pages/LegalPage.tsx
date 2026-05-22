/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { motion } from 'motion/react';
import { ChevronLeft } from 'lucide-react';
import { Link, useParams } from 'react-router-dom';
import { LogoBrand } from '../components/Logo';

const LegalContent = ({ type }: { type: string }) => {
  switch (type) {
    case 'privacy':
      return (
        <div className="prose prose-blue max-w-none">
          <h1 className="text-3xl font-bold mb-6">Privacy Policy</h1>
          <p className="text-gray-600 mb-4">Last Updated: April 30, 2026</p>
          <p className="mb-4">Namoham ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how your personal information is collected, used, and disclosed by Namoham.</p>
          
          <h2 className="text-xl font-bold mt-8 mb-4">1. Information We Collect</h2>
          <p className="mb-4">We collect information that you provide directly to us, such as when you create an account, register your temple, or make a donation (Arpan). This may include:</p>
          <ul className="list-disc pl-6 mb-4">
            <li>Name and contact information</li>
            <li>Authentication credentials</li>
            <li>Profile information (for Gurus and Devotees)</li>
            <li>Transaction details for donations and bookings</li>
          </ul>

          <h2 className="text-xl font-bold mt-8 mb-4">2. How We Use Your Information</h2>
          <p className="mb-4">We use the information we collect to:</p>
          <ul className="list-disc pl-6 mb-4">
            <li>Provide, maintain, and improve our services</li>
            <li>Process transactions and send related information</li>
            <li>Verify identity and prevent fraud</li>
            <li>Coordinate between Devotees, Gurus, and Temples for rituals and Sankalps</li>
          </ul>

          <h2 className="text-xl font-bold mt-8 mb-4">3. Data Security</h2>
          <p className="mb-4">We use SSL encryption and secure payment gateways for all financial transactions. We do not store full credit card numbers on our servers; all payment processing is handled by verified third-party providers.</p>
        </div>
      );
    case 'terms':
      return (
        <div className="prose prose-blue max-w-none">
          <h1 className="text-3xl font-bold mb-6">Terms of Service (Terms of Seva)</h1>
          <p className="text-gray-600 mb-4">Last Updated: April 30, 2026</p>
          <p className="mb-4">By using Namoham, you agree to these terms. Please read them carefully.</p>
          
          <h2 className="text-xl font-bold mt-8 mb-4">1. Use of Service</h2>
          <p className="mb-4">Namoham provides a platform to connect devotees with spiritual leaders and temples. You agree to use the service only for lawful and spiritual purposes as intended by the platform.</p>

          <h2 className="text-xl font-bold mt-8 mb-4">2. Donations (Arpan/Chadhava)</h2>
          <p className="mb-4">All donations made through the platform are direct transfers to the respective temple's or guru's verified bank account. Namoham acts as a facilitator and does not guarantee the religious outcome of any offering.</p>

          <h2 className="text-xl font-bold mt-8 mb-4">3. Content Moderation</h2>
          <p className="mb-4">We reserve the right to moderate and remove any content that is disrespectful, hateful, or violates the spiritual sanctity of the community.</p>
        </div>
      );
    case 'refunds':
      return (
        <div className="prose prose-blue max-w-none">
          <h1 className="text-3xl font-bold mb-6">Refund and Cancellation Policy</h1>
          <p className="text-gray-600 mb-4">Last Updated: April 30, 2026</p>
          
          <h2 className="text-xl font-bold mt-8 mb-4">1. Donations (Arpan)</h2>
          <p className="mb-4">Once a donation (Arpan/Chadhava) is processed and successfully transferred to the temple or guru, it is generally non-refundable due to the nature of religious offerings. In case of technical errors (e.g., double billing), please contact us within 48 hours.</p>

          <h2 className="text-xl font-bold mt-8 mb-4">2. Puja & Ritual Bookings</h2>
          <p className="mb-4">Cancellations for booked Pujas or Sankalps are allowed up to 24 hours before the scheduled time. A 90% refund will be issued, with 10% retained for processing fees. No refunds will be issued for cancellations made within 24 hours of the event.</p>

          <h2 className="text-xl font-bold mt-8 mb-4">3. Cancellation by Temple/Guru</h2>
          <p className="mb-4">In the rare event that a temple or guru cannot perform a scheduled ritual, a full 100% refund will be issued to the devotee automatically.</p>
        </div>
      );
    case 'contact':
        return (
          <div className="prose prose-blue max-w-none">
            <h1 className="text-3xl font-bold mb-6">Contact Us</h1>
            <p className="mb-4">For any support, queries regarding your bookings, or temple registration assistance, please reach out to our team.</p>
            
            <div className="grid md:grid-cols-2 gap-8 mt-12">
                <div className="p-6 bg-gray-50 rounded-2xl border border-gray-100">
                    <h3 className="font-bold text-brand-dark mb-2 uppercase tracking-widest text-xs">Email Support</h3>
                    <p className="text-brand-primary font-bold">seva@namoham.com</p>
                </div>
                <div className="p-6 bg-gray-50 rounded-2xl border border-gray-100">
                    <h3 className="font-bold text-brand-dark mb-2 uppercase tracking-widest text-xs">Business Queries</h3>
                    <p className="text-brand-primary font-bold">contact@namoham.com</p>
                </div>
            </div>

            <h2 className="text-xl font-bold mt-12 mb-4">Office Address</h2>
            <p className="mb-4">Namoham Divine Tech Private Limited,<br />
            Spiritual Core Tower, Sector 4,<br />
            Varanasi, Uttar Pradesh - 221001, India.</p>
          </div>
        );
    default:
      return <div>Page not found</div>;
  }
};

export default function LegalPage() {
  const { type } = useParams();

  return (
    <div className="min-h-screen bg-white font-sans antialiased">
      <nav className="fixed top-0 left-0 right-0 bg-white/80 backdrop-blur-md border-b border-gray-100 py-4 z-50">
        <div className="max-w-4xl mx-auto px-6 flex justify-between items-center">
            <Link to="/" className="flex items-center gap-2 text-brand-primary font-bold text-sm uppercase tracking-widest hover:opacity-70 transition-all">
                <ChevronLeft size={16} />
                Back to Home
            </Link>
            <Link to="/" className="hover:opacity-80 transition-opacity scale-75 origin-right">
                <LogoBrand />
            </Link>
        </div>
      </nav>

      <main className="pt-32 pb-24 px-6">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-4xl mx-auto"
        >
          <LegalContent type={type || 'privacy'} />
        </motion.div>
      </main>

      <footer className="bg-gray-50 py-12 border-t border-gray-100">
        <div className="max-w-4xl mx-auto px-6 text-center text-[10px] uppercase tracking-[0.3em] font-bold text-brand-dark/30">
          <p>© 2026 Namoham Divine Ecosystem. All Rights Reserved.</p>
        </div>
      </footer>
    </div>
  );
}
