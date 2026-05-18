/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { motion } from 'motion/react';
import { 
  Download, 
  Church, 
  Users, 
  UsersRound, 
  HeartHandshake, 
  CalendarClock, 
  LayoutDashboard, 
  ShieldCheck, 
  History,
  Smartphone,
  ArrowRight,
  Menu,
  X
} from 'lucide-react';
import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { LogoBrand, LogoIcon } from '../components/Logo';

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 50);
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${isScrolled ? 'bg-white/90 backdrop-blur-md border-b border-gray-100 py-4 shadow-sm' : 'bg-transparent py-6'}`}>
      <div className="max-w-7xl mx-auto px-6 flex justify-between items-center">
        <Link to="/" className="hover:opacity-80 transition-opacity">
          <LogoBrand horizontal />
        </Link>

        {/* Desktop Nav */}
        <div className="hidden md:flex items-center gap-8 text-[11px] font-bold opacity-70 uppercase tracking-[0.2em] text-brand-dark">
          <a href="#about" className="hover:text-brand-primary transition-colors">About</a>
          <a href="#services" className="hover:text-brand-primary transition-colors">Services</a>
          <a href="#community" className="hover:text-brand-primary transition-colors">Community</a>
          <button className="bg-brand-primary hover:bg-blue-400 px-6 py-2.5 rounded-full transition-all shadow-blue-soft hover:shadow-blue-glow text-white font-bold cursor-pointer">
            Join Now
          </button>
        </div>

        {/* Mobile Toggle */}
        <button className="md:hidden text-brand-dark" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
          {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <motion.div 
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="absolute top-full left-0 right-0 bg-white border-b border-gray-100 p-6 flex flex-col gap-4 md:hidden shadow-xl"
        >
          <a href="#about" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium text-brand-dark">About</a>
          <a href="#services" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium text-brand-dark">Services</a>
          <a href="#community" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium text-brand-dark">Community</a>
          <button className="bg-brand-primary p-4 rounded-xl font-bold text-white">Download App</button>
        </motion.div>
      )}
    </nav>
  );
};

const Hero = () => {
  return (
    <section className="relative pt-32 pb-20 overflow-hidden min-h-[90vh] flex items-center bg-white">
      {/* Soft Background Aura */}
      <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-brand-primary/5 rounded-full blur-[100px] -translate-y-1/2 translate-x-1/3 pointer-events-none" />
      <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-brand-primary/5 rounded-full blur-[80px] translate-y-1/2 -translate-x-1/4 pointer-events-none" />
      
      <div className="max-w-7xl mx-auto px-6 grid md:grid-cols-2 gap-16 items-center relative z-10">
        <motion.div 
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          viewport={{ once: true }}
        >
          <div className="inline-flex items-center gap-2 px-3 py-1 bg-brand-primary/10 rounded-full text-brand-primary text-[10px] font-bold uppercase tracking-widest mb-6 border border-brand-primary/20">
            <span className="w-1.5 h-1.5 bg-brand-primary rounded-full animate-pulse" />
            Empowering Devotion
          </div>
          <h1 className="text-5xl md:text-7xl font-bold leading-[1.1] mb-8 text-brand-dark">
            Ancient Roots. <br />
            <span className="blue-gradient-text">Digital Futures.</span>
          </h1>
          <p className="font-serif text-lg md:text-xl text-brand-gray mb-10 max-w-xl leading-relaxed italic">
            "Namoham is the ultimate Sanatan ecosystem where Temples, Gurus, and Devotees unite through high-trust Divine Tech."
          </p>
          <div className="flex flex-col sm:flex-row gap-4">
            <button className="bg-brand-primary px-8 py-4 rounded-2xl font-bold flex items-center justify-center gap-3 shadow-blue-soft hover:shadow-blue-glow transition-all group text-white cursor-pointer">
              <Download size={20} />
              Download App
            </button>
            <button className="border border-gray-200 px-8 py-4 rounded-2xl font-bold flex items-center justify-center gap-3 hover:bg-gray-50 transition-all text-brand-dark cursor-pointer">
              Register your Temple
              <ArrowRight size={20} />
            </button>
          </div>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, scale: 0.9 }}
          whileInView={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1, ease: "easeOut" }}
          viewport={{ once: true }}
          className="relative flex justify-center"
        >
          {/* Logo Frame - Representing Namoham App */}
          <div className="relative w-64 md:w-80 h-[500px] md:h-[650px] bg-white rounded-[3rem] border-[12px] border-gray-900 overflow-hidden shadow-2xl">
            <div className="absolute inset-x-0 top-0 h-8 bg-gray-900 rounded-b-xl z-20 flex justify-center pt-1">
               <div className="w-16 h-1 bg-gray-800 rounded-full" />
            </div>
            
            {/* App UI Simulation */}
            <div className="h-full flex flex-col bg-gray-50">
               <div className="p-6 pt-12">
                  <div className="w-full h-40 bg-white rounded-2xl mb-4 flex items-center justify-center shadow-lg transform -rotate-1 relative overflow-hidden border border-gray-100">
                     <LogoIcon className="w-16 h-16" />
                  </div>
                  <div className="space-y-4">
                    <div className="h-4 w-3/4 bg-gray-200 rounded-full" />
                    <div className="h-4 w-1/2 bg-gray-200 rounded-full" />
                    <div className="grid grid-cols-2 gap-3 mt-8">
                       <div className="h-20 bg-white rounded-xl border border-gray-200" />
                       <div className="h-20 bg-white rounded-xl border border-gray-200" />
                    </div>
                  </div>
               </div>
               <div className="mt-auto p-6 bg-white border-t border-gray-100 flex justify-between">
                  <div className="w-10 h-10 bg-brand-primary/10 rounded-full flex items-center justify-center text-brand-primary"><Church size={20}/></div>
                  <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-gray-400"><Users size={20}/></div>
                  <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-gray-400"><History size={20}/></div>
                  <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center text-gray-400"><HeartHandshake size={20}/></div>
               </div>
            </div>

            <div className="absolute bottom-12 left-0 right-0 px-6 z-10">
              <motion.div 
                animate={{ y: [0, -6, 0] }}
                transition={{ duration: 4, repeat: Infinity }}
                className="bg-white p-4 rounded-2xl shadow-xl border border-gray-100 flex items-center gap-4"
              >
                <div className="w-10 h-10 bg-brand-primary rounded-lg flex items-center justify-center text-white shadow-blue-soft">
                   <HeartHandshake size={20} />
                </div>
                <div>
                  <p className="font-bold text-sm text-brand-dark leading-tight">Offer Chadhava</p>
                  <p className="text-[10px] text-brand-gray">Direct to Kashi Vishwanath</p>
                </div>
              </motion.div>
            </div>
          </div>
          
          {/* Decorative Radial Elements */}
          <div className="absolute -z-10 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[120%] h-[120%] bg-brand-primary/5 rounded-full blur-[100px]" />
          <motion.div 
            animate={{ rotate: 360 }}
            transition={{ duration: 40, repeat: Infinity, ease: "linear" }}
            className="absolute -z-5 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[110%] h-[110%] border border-brand-primary/10 rounded-full border-dashed"
          />
        </motion.div>
      </div>
    </section>
  );
};

const AccountCard = ({ title, subtitle, icon: Icon, features }: { title: string, subtitle: string, icon: any, features: string[] }) => (
  <motion.div 
    whileHover={{ y: -12 }}
    className="light-card p-10 rounded-[2.5rem] group relative overflow-hidden"
  >
    <div className="absolute top-0 right-0 w-32 h-32 bg-brand-primary/5 rounded-bl-full group-hover:bg-brand-primary/10 transition-colors" />
    <div className="w-16 h-16 bg-brand-primary/10 border border-brand-primary/20 rounded-2xl flex items-center justify-center mb-8 group-hover:bg-brand-primary transition-all duration-500 shadow-blue-soft group-hover:shadow-blue-glow">
      <Icon className="text-brand-primary group-hover:text-white transition-colors duration-500" size={32} />
    </div>
    <h3 className="text-2xl font-bold mb-3 tracking-tight text-brand-dark uppercase">{title}</h3>
    <p className="text-brand-primary font-serif italic mb-8 text-sm">"{subtitle}"</p>
    <ul className="space-y-4">
      {features.map((f, i) => (
        <li key={i} className="flex items-start gap-4 text-sm text-brand-gray leading-snug">
          <div className="w-2 h-2 bg-brand-primary rounded-full mt-1.5 shrink-0 shadow-sm" />
          {f}
        </li>
      ))}
    </ul>
  </motion.div>
);

const TrinitySection = () => {
  return (
    <section className="py-24 bg-gray-50/50" id="about">
      <div className="max-w-7xl mx-auto px-6">
        <div className="text-center mb-20">
          <h2 className="text-4xl md:text-5xl font-bold mb-6 text-brand-dark">The Trinity of <span className="text-brand-primary">Connection</span></h2>
          <p className="text-brand-gray max-w-2xl mx-auto uppercase tracking-[0.3em] text-[10px] font-bold">Unifying the Sanatan Community through Tech</p>
        </div>
        
        <div className="grid lg:grid-cols-3 gap-10">
          <AccountCard 
            title="Temples"
            subtitle="Digitalize your Dhama."
            icon={Church}
            features={[
              "Post Live Darshans directly to devotees",
              "Manage Aarti & Puja bookings effortlessly",
              "Receive secure direct Hundi donations",
              "Transparent reporting & community lead"
            ]}
          />
          <AccountCard 
            title="Gurus"
            subtitle="Spread the Wisdom."
            icon={Users}
            features={[
              "Share daily Pravachans & Bhajans",
              "Direct connection with your spiritual family",
              "Secure Dakshina & support collection",
              "Vedic knowledge management tools"
            ]}
          />
          <AccountCard 
            title="Devotees"
            subtitle="Deepen your Sadhana."
            icon={UsersRound}
            features={[
              "Engage with authentic spiritual content",
              "Book exclusive rituals & Pujas remotely",
              "Directly support favorite gurus & temples",
              "Custom feed focused on spiritual growth"
            ]}
          />
        </div>
      </div>
    </section>
  );
};

const FeatureItem = ({ icon: Icon, title, desc }: { icon: any, title: string, desc: string }) => (
  <motion.div 
    whileHover={{ x: 12 }}
    className="flex gap-6 items-start p-8 rounded-3xl hover:bg-white transition-all cursor-default hover:shadow-lg hover:shadow-blue-500/5 group"
  >
    <div className="mt-1 p-4 bg-gray-50 rounded-2xl border border-gray-100 group-hover:bg-brand-primary/10 group-hover:border-brand-primary/20 transition-colors">
      <Icon className="text-brand-primary" size={24} />
    </div>
    <div>
      <h4 className="font-bold mb-2 text-xl text-brand-dark uppercase tracking-tight">{title}</h4>
      <p className="text-brand-gray leading-relaxed font-serif text-sm">{desc}</p>
    </div>
  </motion.div>
);

const FeaturesSection = () => {
  return (
    <section className="py-32 bg-white relative overflow-hidden" id="services">
      <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-brand-primary/20 to-transparent" />
      
      <div className="max-w-7xl mx-auto px-6">
        <div className="flex flex-col md:flex-row justify-between items-end mb-20 gap-10">
          <div className="max-w-2xl">
            <h2 className="text-4xl md:text-5xl font-bold mb-6 italic font-serif text-brand-dark">Sacred Services</h2>
            <p className="text-brand-gray text-lg leading-relaxed">Harnessing the power of high-trust technology to serve your spiritual journey with complete transparency and purity.</p>
          </div>
          <button className="text-brand-primary font-bold text-xs uppercase tracking-widest flex items-center gap-3 group whitespace-nowrap bg-brand-primary/5 px-6 py-3 rounded-full hover:bg-brand-primary/10 transition-all cursor-pointer">
            View All Features <ArrowRight size={16} className="group-hover:translate-x-2 transition-transform" />
          </button>
        </div>

        <div className="grid md:grid-cols-2 gap-x-16 gap-y-10">
          <FeatureItem 
            icon={ShieldCheck}
            title="Verified Arpan"
            desc="Offerings reach temples instantly. We ensure 100% transparency with direct-to-temple bank transfers."
          />
          <FeatureItem 
            icon={CalendarClock}
            title="Sankalp & Puja Seva"
            desc="Distance is no longer a barrier. Join live Sankalp sessions and sacred rituals from any corner of the world."
          />
          <FeatureItem 
            icon={LayoutDashboard}
            title="Sat-Sanga Feed"
            desc="A purified digital space for spiritual growth. High-quality wisdom minus the social media noise."
          />
          <FeatureItem 
            icon={History}
            title="Vedic Panchang"
            desc="Geo-precise Muhurta calculations. Stay aligned with cosmic rhythms according to your exact location."
          />
        </div>
      </div>
    </section>
  );
};

const StatsSection = () => {
  return (
    <section className="py-24 border-y border-gray-100 relative overflow-hidden bg-gray-50/30">
      <div className="max-w-7xl mx-auto px-6 relative z-10 text-center">
        <div className="grid md:grid-cols-3 gap-16">
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }}>
            <p className="text-5xl md:text-6xl font-bold text-brand-primary mb-4 tracking-tighter shadow-blue-soft">500+</p>
            <p className="uppercase tracking-[0.4em] text-[10px] font-black text-brand-dark/40">Verified Temples</p>
          </motion.div>
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.2 }}>
            <p className="text-5xl md:text-6xl font-bold text-brand-primary mb-4 tracking-tighter shadow-blue-soft">1000+</p>
            <p className="uppercase tracking-[0.4em] text-[10px] font-black text-brand-dark/40">Verified Gurus</p>
          </motion.div>
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: 0.4 }}>
            <p className="text-5xl md:text-6xl font-bold text-brand-primary mb-4 tracking-tighter shadow-blue-soft">1M+</p>
            <p className="uppercase tracking-[0.4em] text-[10px] font-black text-brand-dark/40">Devotees Strong</p>
          </motion.div>
        </div>
        
        <div className="mt-32 max-w-4xl mx-auto">
          <motion.p 
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-2xl md:text-4xl font-serif italic text-brand-dark/80 leading-relaxed mb-10"
          >
            “Connecting the modern seeker to their eternal roots through the power of integrity and technology.”
          </motion.p>
          <div className="w-20 h-1 bg-brand-primary mx-auto rounded-full shadow-blue-soft" />
        </div>
      </div>
    </section>
  );
};

const Footer = () => {
  return (
    <footer className="bg-white pt-24 pb-12">
      <div className="max-w-7xl mx-auto px-6">
        <div className="grid md:grid-cols-4 gap-16 mb-24">
          <div className="col-span-1 md:col-span-2">
            <Link to="/" className="block mb-8 hover:opacity-80 transition-opacity">
              <LogoBrand />
            </Link>
            <p className="text-brand-gray text-base max-w-md mb-10 font-serif leading-relaxed italic">
              Empowering the world's oldest tradition with modern digital security. 
              We bridge ancient wisdom and future tech, creating a pure space for faith to flourish.
            </p>
            <div className="flex gap-10 text-brand-dark/30">
              <ShieldCheck size={22} className="hover:text-brand-primary cursor-pointer transition-colors" />
              <Smartphone size={22} className="hover:text-brand-primary cursor-pointer transition-colors" />
              <History size={22} className="hover:text-brand-primary cursor-pointer transition-colors" />
            </div>
          </div>
          
          <div>
            <h5 className="font-bold mb-8 text-[11px] uppercase tracking-[0.3em] text-brand-dark/40">Ecosystem</h5>
            <ul className="space-y-5 text-sm font-bold text-brand-dark/60 uppercase tracking-widest text-[10px]">
              <li><a href="#" className="hover:text-brand-primary transition-colors">Developer Portal</a></li>
              <li><a href="#" className="hover:text-brand-primary transition-colors">Temple Registration</a></li>
              <li><a href="#" className="hover:text-brand-primary transition-colors">Guru Verification</a></li>
              <li><a href="#" className="hover:text-brand-primary transition-colors">Transparency Hub</a></li>
            </ul>
          </div>

          <div>
            <h5 className="font-bold mb-8 text-[11px] uppercase tracking-[0.3em] text-brand-dark/40">Trust & Safety</h5>
            <div className="space-y-4">
              <div className="flex items-center gap-3 text-[10px] font-bold uppercase tracking-widest text-brand-gray bg-gray-50 p-4 rounded-2xl border border-gray-100">
                <ShieldCheck size={16} className="text-brand-primary" />
                SSL 256-Bit Secure
              </div>
              <div className="flex items-center gap-3 text-[10px] font-bold uppercase tracking-widest text-brand-gray bg-gray-50 p-4 rounded-2xl border border-gray-100">
                <Smartphone size={16} className="text-brand-primary" />
                Direct Transfer
              </div>
            </div>
          </div>
        </div>
        
        <div className="pt-10 border-t border-gray-100 flex flex-col md:flex-row justify-between items-center gap-8 text-[10px] uppercase tracking-[0.4em] font-bold text-brand-dark/30 text-center">
          <p>© 2026 Namoham Divine Ecosystem. All Rights Reserved.</p>
          <div className="flex gap-12">
            <Link to="/legal/privacy" className="hover:text-brand-dark transition-colors">Privacy Policy</Link>
            <Link to="/legal/terms" className="hover:text-brand-dark transition-colors">Terms of Seva</Link>
            <Link to="/legal/refunds" className="hover:text-brand-dark transition-colors">Refund Policy</Link>
            <Link to="/legal/contact" className="hover:text-brand-dark transition-colors">Contact Us</Link>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default function LandingPage() {
  return (
    <div className="font-sans antialiased bg-white text-brand-dark selection:bg-brand-primary selection:text-white scroll-smooth cursor-default">
      <Navbar />
      <main>
        <Hero />
        <TrinitySection />
        <FeaturesSection />
        <StatsSection />
      </main>
      <Footer />
    </div>
  );
}
