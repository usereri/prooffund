'use client';

import { useEffect, useRef, useState } from 'react';
import ArkaLogo from '@/components/ArkaLogo';
import { useAuth } from '@/lib/auth-context';
import { communities, meetups, memberships, currentUserId, formatDate, getCommunityLeaderboard, users, getUserById } from '@/lib/mock-data';
import { CommunityIcon, MeetupIcon, TrophyIcon, QrIcon } from '@/components/Icons';
import { createCommunityOnChain } from '@/lib/arka-pro';
import { QRCodeSVG } from 'qrcode.react';

export default function LandingPage() {
  const containerRef = useRef<HTMLDivElement>(null);
  const { user, isConnected, openSignIn, signOut, primaryWallet } = useAuth();
  const [showTelegramPrompt, setShowTelegramPrompt] = useState<string | null>(null);
  const [expandedCommunity, setExpandedCommunity] = useState<string | null>(null);

  // If signed in, show dashboard
  if (isConnected && user) {
    return (
      <WebDashboard
        user={user}
        signOut={signOut}
        onEventClick={(name) => setShowTelegramPrompt(name)}
        telegramPrompt={showTelegramPrompt}
        onClosePrompt={() => setShowTelegramPrompt(null)}
        expandedCommunity={expandedCommunity}
        onToggleCommunity={(id) => setExpandedCommunity(expandedCommunity === id ? null : id)}
      />
    );
  }

  return (
    <div
      ref={containerRef}
      className="h-screen w-full snap-y snap-mandatory overflow-y-auto"
      style={{ scrollBehavior: 'smooth' }}
    >
      {/* Fixed header */}
      <header className="fixed top-0 left-0 right-0 z-40 flex items-center justify-between px-5 py-4 lg:px-12 bg-white/80 backdrop-blur-sm">
        <div className="flex items-center gap-2">
          <ArkaLogo size={28} />
          <span className="text-base font-bold text-arka-text lg:hidden">arka</span>
        </div>
        <button
          onClick={openSignIn}
          className="rounded-full bg-arka-pink px-4 py-1.5 text-xs font-semibold text-white transition hover:bg-arka-pink/90"
        >
          Sign In
        </button>
      </header>

      {/* Section 1 — Hero + Phone Mockup */}
      <section className="relative flex h-screen w-full snap-start flex-col items-center justify-center overflow-hidden px-5">
        <div className="mx-auto flex w-full max-w-5xl flex-col items-center lg:flex-row lg:items-center lg:justify-between lg:gap-16">
          <div className="w-full max-w-md lg:max-w-lg">
            <h1 className="text-4xl font-bold leading-tight text-arka-text sm:text-5xl lg:text-6xl">
              Real connections,<br />
              <span className="text-arka-pink">Real events.</span>
            </h1>
            <p className="mt-4 text-lg leading-relaxed text-black/55">
              Arka brings communities together through engaging events and reputation.
            </p>
            <p className="mt-2 text-lg font-medium text-arka-text">
              Join for free.
            </p>
            <div className="mt-6 flex flex-wrap gap-3">
              <button
                onClick={openSignIn}
                className="inline-flex items-center gap-2 rounded-full bg-arka-pink px-6 py-3 text-sm font-semibold text-white transition hover:bg-arka-pink/90"
              >
                Get Started
              </button>
              <a
                href="https://t.me/arka_telegram_bot"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-full bg-[#2AABEE] px-6 py-3 text-sm font-semibold text-white transition hover:bg-[#229ED9]"
              >
                <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.37 0 0 5.37 0 12s5.37 12 12 12 12-5.37 12-12S18.63 0 12 0zm5.53 8.15l-1.8 8.5c-.13.6-.5.75-.99.47l-2.76-2.04-1.33 1.28c-.15.15-.27.27-.56.27l.2-2.8 5.1-4.6c.22-.2-.05-.3-.34-.13l-6.3 3.97-2.72-.85c-.59-.18-.6-.59.12-.87l10.63-4.1c.5-.18.93.12.77.87z"/></svg>
                Open in Telegram
              </a>
            </div>
          </div>

          <div className="mt-8 lg:mt-0 lg:flex-shrink-0">
            <PhoneMockup>
              <div className="space-y-3 p-4">
                <div className="flex items-center gap-2">
                  <ArkaLogo size={20} />
                  <span className="text-sm font-bold text-arka-text">arka</span>
                </div>
                <div className="rounded-xl bg-arka-pink/10 p-3">
                  <p className="text-xs font-semibold text-arka-pink">Next Event</p>
                  <p className="mt-1 text-sm font-bold text-arka-text">ETH Budapest Meetup</p>
                  <p className="text-xs text-black/50">Tomorrow, 18:00 · 23 attending</p>
                </div>
                <div className="rounded-xl bg-arka-card p-3">
                  <p className="text-xs font-semibold text-black/40">Your Match</p>
                  <p className="mt-1 text-center text-3xl font-black text-arka-pink">#7</p>
                  <p className="text-center text-xs text-black/40">Find your partner!</p>
                </div>
                <div className="rounded-xl bg-arka-card p-3">
                  <p className="text-xs font-semibold text-black/40">Reputation</p>
                  <div className="mt-1 flex items-center justify-between">
                    <span className="text-sm font-bold">2,450 rep</span>
                    <span className="rounded-full bg-arka-green/15 px-2 py-0.5 text-xs font-semibold text-arka-green">#3</span>
                  </div>
                </div>
              </div>
            </PhoneMockup>
          </div>
        </div>

        <div className="absolute bottom-8 flex animate-bounce flex-col items-center text-black/20">
          <svg className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M19 14l-7 7m0 0l-7-7"/></svg>
        </div>
      </section>

      {/* Section 2 — Leaderboard + Events */}
      <section className="flex h-screen w-full snap-start flex-col items-center justify-center px-5">
        <div className="mx-auto w-full max-w-md space-y-6">
          <h2 className="text-3xl font-bold text-arka-text">
            Show up.<br />
            <span className="text-arka-cyan">Get recognized.</span>
          </h2>
          <p className="text-base text-black/55">
            Every event builds your on-chain reputation. Rise on the leaderboard. Earn badges.
          </p>
          <div className="rounded-2xl bg-white p-4 shadow-lg ring-1 ring-black/5">
            <p className="mb-3 text-xs font-bold uppercase tracking-wider text-black/30">Leaderboard</p>
            {[
              { rank: 1, name: 'alex.eth', rep: 3200, color: 'text-yellow-500' },
              { rank: 2, name: 'sarah.arb', rep: 2800, color: 'text-gray-400' },
              { rank: 3, name: 'You', rep: 2450, color: 'text-amber-600', highlight: true },
              { rank: 4, name: 'danny.dev', rep: 1900, color: 'text-black/30' },
              { rank: 5, name: 'kate.web3', rep: 1650, color: 'text-black/30' },
            ].map((r) => (
              <div
                key={r.rank}
                className={`flex items-center justify-between rounded-xl px-3 py-2.5 text-sm ${
                  r.highlight ? 'bg-arka-pink/10 font-bold text-arka-pink' : 'text-black/70'
                }`}
              >
                <div className="flex items-center gap-3">
                  <span className={`text-lg font-black ${r.color}`}>#{r.rank}</span>
                  <span>{r.name}</span>
                </div>
                <span className="font-semibold">{r.rep}</span>
              </div>
            ))}
          </div>
          <div className="space-y-2">
            <p className="text-xs font-bold uppercase tracking-wider text-black/30">Upcoming</p>
            {[
              { name: 'Web3 Workshop', time: 'Mon, 18:00', count: 12 },
              { name: 'DeFi Deep Dive', time: 'Wed, 19:30', count: 8 },
            ].map((e) => (
              <div key={e.name} className="flex items-center justify-between rounded-xl bg-white p-3 shadow-sm ring-1 ring-black/5">
                <div>
                  <p className="text-sm font-semibold">{e.name}</p>
                  <p className="text-xs text-black/40">{e.time}</p>
                </div>
                <span className="rounded-full bg-arka-green/10 px-2 py-1 text-xs font-semibold text-arka-green">{e.count} going</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Section 3 — Pricing */}
      <section className="flex h-screen w-full snap-start flex-col items-center justify-center px-5">
        <div className="mx-auto w-full max-w-md">
          <h2 className="mb-2 text-3xl font-bold text-arka-text">Simple pricing.</h2>
          <p className="mb-8 text-base text-black/55">Free forever for users. Pro for community hosts.</p>
          <div className="grid grid-cols-2 gap-3">
            <div className="rounded-2xl bg-white p-5 shadow-lg ring-1 ring-black/5">
              <p className="text-xs font-bold uppercase tracking-wider text-black/30">User</p>
              <p className="mt-2 text-2xl font-black text-arka-text">Free</p>
              <p className="text-xs text-black/40">forever</p>
              <div className="mt-4 space-y-2 text-xs text-black/55">
                <p>· Browse communities</p>
                <p>· Attend events</p>
                <p>· Create meetings</p>
                <p>· QR matching</p>
                <p>· Earn reputation</p>
                <p>· Leaderboard</p>
              </div>
            </div>
            <div className="rounded-2xl bg-arka-pink p-5 text-white shadow-lg">
              <p className="text-xs font-bold uppercase tracking-wider text-white/60">Pro Host</p>
              <p className="mt-2 text-2xl font-black">$15</p>
              <p className="text-xs text-white/60">/month</p>
              <div className="mt-4 space-y-2 text-xs text-white/80">
                <p>· Create communities</p>
                <p>· Charge memberships</p>
                <p>· Meeting rooms</p>
                <p>· Coffee tabs</p>
                <p>· Content vault</p>
                <p>· Arweave backup</p>
                <p>· Calendar + RSVPs</p>
                <p>· Analytics</p>
              </div>
            </div>
          </div>
          <button
            onClick={openSignIn}
            className="mt-8 flex w-full items-center justify-center gap-2 rounded-2xl bg-arka-pink py-4 text-base font-bold text-white transition hover:bg-arka-pink/90"
          >
            Get Started
          </button>
          <p className="mt-3 text-center text-xs text-black/30">
            Built on Arbitrum · Powered by Dynamic
          </p>
        </div>
      </section>
    </div>
  );
}

// --- Web Dashboard (shown after sign-in) ---
function WebDashboard({
  user,
  signOut,
  onEventClick,
  telegramPrompt,
  onClosePrompt,
  expandedCommunity,
  onToggleCommunity,
}: {
  user: NonNullable<ReturnType<typeof useAuth>['user']>;
  signOut: () => void;
  onEventClick: (name: string) => void;
  telegramPrompt: string | null;
  onClosePrompt: () => void;
  expandedCommunity: string | null;
  onToggleCommunity: (id: string) => void;
}) {
  const { isProHost, becomeHost, primaryWallet } = useAuth();
  const [showProModal, setShowProModal] = useState(false);
  const [expandedStat, setExpandedStat] = useState<string | null>(null);
  const [showCommunityForm, setShowCommunityForm] = useState(false);
  const [communityName, setCommunityName] = useState('');
  const [communityDescription, setCommunityDescription] = useState('');
  const [communityLocation, setCommunityLocation] = useState('');
  const [isCreating, setIsCreating] = useState(false);
  const [showEventForm, setShowEventForm] = useState(false);
  const [eventFormType, setEventFormType] = useState<'pro' | 'quick'>('pro');
  const [eventName, setEventName] = useState('');
  const [eventDateTime, setEventDateTime] = useState('');
  const [eventLocation, setEventLocation] = useState('');
  const [createdEventId, setCreatedEventId] = useState<string | null>(null);
  const [showQRModal, setShowQRModal] = useState(false);

  const handleSubscribe = async () => {
    try {
      setIsCreating(true);
      await becomeHost();
      setShowProModal(false);
      setShowCommunityForm(true);
    } catch (error: any) {
      alert(error.message || 'Subscription failed');
    } finally {
      setIsCreating(false);
    }
  };

  const handleCreateCommunity = async () => {
    if (!communityName.trim()) {
      alert('Community name is required');
      return;
    }
    try {
      setIsCreating(true);
      const result = await createCommunityOnChain(primaryWallet, communityName);
      if (result.success) {
        await fetch('http://localhost:3053/communities', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: communityName,
            description: communityDescription,
            location: communityLocation,
            creatorAddress: user.address,
          }),
        });
        setShowCommunityForm(false);
        setCommunityName('');
        setCommunityDescription('');
        setCommunityLocation('');
        alert('Community created successfully!');
      } else {
        alert(result.error || 'Failed to create community');
      }
    } catch (error: any) {
      alert(error.message || 'Failed to create community');
    } finally {
      setIsCreating(false);
    }
  };

  const handleCreateEvent = async () => {
    if (!eventName.trim() || !eventDateTime || !eventLocation.trim()) {
      alert('All fields are required');
      return;
    }
    try {
      setIsCreating(true);
      const res = await fetch('http://localhost:3053/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          hostAddress: user.address,
          communityId: user.hostedCommunityId || null,
          name: eventName,
          datetime: eventDateTime,
          location: eventLocation,
          ephemeral: eventFormType === 'quick',
        }),
      });
      const data = await res.json();
      if (data.success) {
        setCreatedEventId(data.event.id);
        setEventName('');
        setEventDateTime('');
        setEventLocation('');
      } else {
        alert(data.error || 'Failed to create event');
      }
    } catch (error: any) {
      alert(error.message || 'Failed to create event');
    } finally {
      setIsCreating(false);
    }
  };

  const joinedCommunities = communities.filter((c) =>
    memberships.some((m) => m.userId === currentUserId && m.communityId === c.id)
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="sticky top-0 z-40 flex items-center justify-between bg-white/90 px-5 py-4 shadow-sm backdrop-blur-sm lg:px-12">
        <div className="flex items-center gap-2">
          <ArkaLogo size={28} />
          <span className="text-base font-bold text-arka-text lg:hidden">arka</span>
        </div>
        <div className="flex items-center gap-3">
          <WalletBadge user={user} primaryWallet={primaryWallet} />
          <button
            onClick={signOut}
            className="rounded-full border border-black/10 px-3 py-1 text-xs font-medium text-black/50 transition hover:bg-black/5"
          >
            Sign Out
          </button>
        </div>
      </header>

      <main className="mx-auto max-w-2xl px-5 py-8">
        {/* Welcome */}
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold text-arka-text">
              Welcome back, {user.username.replace('@', '')} 👋
            </h1>
            <p className="mt-1 text-sm text-black/40">
              {user.address && user.address !== '0x0000...0000' ? `${user.address.slice(0, 6)}...${user.address.slice(-4)}` : user.email}
            </p>
          </div>
          <button
            onClick={() => setShowQRModal(true)}
            className="rounded-full bg-arka-cyan/10 p-2 transition hover:bg-arka-cyan/20"
            title="Show my QR code"
          >
            <QrIcon className="h-5 w-5 text-arka-cyan" />
          </button>
        </div>

        {/* Stats */}
        <div className="mt-6 grid grid-cols-3 gap-3">
          <button onClick={() => setExpandedStat(expandedStat === 'communities' ? null : 'communities')} className={`rounded-xl bg-white p-4 text-center shadow-sm ring-1 transition ${expandedStat === 'communities' ? 'ring-arka-pink/30' : 'ring-black/5'}`}>
            <p className="text-2xl font-black text-arka-pink">{joinedCommunities.length}</p>
            <p className="text-[11px] text-black/40">Communities</p>
          </button>
          <button onClick={() => setExpandedStat(expandedStat === 'events' ? null : 'events')} className={`rounded-xl bg-white p-4 text-center shadow-sm ring-1 transition ${expandedStat === 'events' ? 'ring-arka-cyan/30' : 'ring-black/5'}`}>
            <p className="text-2xl font-black text-arka-cyan">{meetups.length}</p>
            <p className="text-[11px] text-black/40">Events</p>
          </button>
          <button onClick={() => setExpandedStat(expandedStat === 'reputation' ? null : 'reputation')} className={`rounded-xl bg-white p-4 text-center shadow-sm ring-1 transition ${expandedStat === 'reputation' ? 'ring-arka-green/30' : 'ring-black/5'}`}>
            <p className="text-2xl font-black text-arka-green">2,450</p>
            <p className="text-[11px] text-black/40">Reputation</p>
          </button>
        </div>

        {/* Expanded stat details */}
        {expandedStat === 'events' && (
          <div className="mt-3 rounded-2xl bg-white p-4 shadow-sm ring-1 ring-black/5">
            <p className="text-xs font-bold uppercase tracking-wider text-black/30 mb-2">Events Attended</p>
            <div className="space-y-2">
              {[
                { name: 'ETH Budapest Kickoff', date: 'Mar 15', rep: '+80', interactions: 4 },
                { name: 'Arbitrum Builders Call', date: 'Mar 22', rep: '+120', interactions: 6 },
                { name: 'Web3 Nomads Lisbon', date: 'Apr 2', rep: '+60', interactions: 2 },
                { name: 'DeFi Deep Dive', date: 'Apr 10', rep: '+90', interactions: 5 },
                { name: 'ETH Budapest Demo Day', date: 'Apr 16', rep: '+100', interactions: 7 },
              ].map((e) => (
                <div key={e.name} className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2">
                  <div>
                    <p className="text-xs font-semibold text-arka-text">{e.name}</p>
                    <p className="text-[10px] text-black/40">{e.date} · {e.interactions} interactions</p>
                  </div>
                  <span className="text-xs font-bold text-arka-green">{e.rep}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {expandedStat === 'reputation' && (
          <div className="mt-3 rounded-2xl bg-white p-4 shadow-sm ring-1 ring-black/5">
            <p className="text-xs font-bold uppercase tracking-wider text-black/30 mb-2">Reputation Breakdown</p>
            <div className="space-y-2">
              {[
                { source: 'Event attendance', points: 450, icon: '📅' },
                { source: 'QR check-ins', points: 380, icon: '✅' },
                { source: 'Mingle matches', points: 520, icon: '🤝' },
                { source: 'Verifications', points: 600, icon: '🔐' },
                { source: 'Poll participation', points: 200, icon: '📊' },
                { source: 'Community engagement', points: 300, icon: '💬' },
              ].map((r) => (
                <div key={r.source} className="flex items-center justify-between rounded-lg bg-gray-50 px-3 py-2">
                  <div className="flex items-center gap-2">
                    <span className="text-sm">{r.icon}</span>
                    <p className="text-xs text-arka-text">{r.source}</p>
                  </div>
                  <span className="text-xs font-bold text-arka-green">+{r.points}</span>
                </div>
              ))}
              <div className="flex items-center justify-between border-t border-black/5 pt-2 mt-1 px-3">
                <p className="text-xs font-bold text-arka-text">Total</p>
                <p className="text-sm font-black text-arka-green">2,450</p>
              </div>
            </div>
          </div>
        )}

        {/* Go Pro Card */}
        {!isProHost && (
          <section className="mt-6 rounded-2xl bg-gradient-to-br from-arka-pink to-arka-cyan p-6 text-white shadow-lg">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-lg font-bold">🌟 Go Pro</h3>
                <p className="mt-1 text-sm opacity-90">Create your own community & host events</p>
                <p className="mt-2 text-xs opacity-75">0.001 ETH/month</p>
              </div>
              <button
                onClick={() => setShowProModal(true)}
                className="rounded-full bg-white px-5 py-2 text-sm font-bold text-arka-pink transition hover:bg-white/90"
              >
                Upgrade
              </button>
            </div>
          </section>
        )}

        {/* Pro Host: Create Community */}
        {isProHost && !user.hostedCommunityId && (
          <section className="mt-6 rounded-2xl bg-gradient-to-br from-arka-green to-arka-cyan p-6 text-white shadow-lg">
            <h3 className="text-lg font-bold">✨ You&apos;re a Pro Host!</h3>
            <p className="mt-1 text-sm opacity-90">Ready to create your community?</p>
            <button
              onClick={() => setShowCommunityForm(true)}
              className="mt-3 rounded-full bg-white px-5 py-2 text-sm font-bold text-arka-green transition hover:bg-white/90"
            >
              Create Community
            </button>
          </section>
        )}

        {/* Quick Event Creation for Free Users */}
        {!isProHost && (
          <section className="mt-6 rounded-2xl bg-gradient-to-br from-amber-400 to-orange-500 p-6 text-white shadow-lg">
            <h3 className="text-lg font-bold">⚡ Create Quick Event</h3>
            <p className="mt-1 text-sm opacity-90">Free users can create ephemeral events</p>
            <button
              onClick={() => { setEventFormType('quick'); setShowEventForm(true); }}
              className="mt-3 rounded-full bg-white px-5 py-2 text-sm font-bold text-orange-600 transition hover:bg-white/90"
            >
              Create Quick Event
            </button>
          </section>
        )}

        {/* Pro Host: Create Event */}
        {isProHost && user.hostedCommunityId && (
          <section className="mt-6 rounded-2xl bg-gradient-to-br from-arka-pink to-arka-cyan p-6 text-white shadow-lg">
            <h3 className="text-lg font-bold">🎉 Create Event</h3>
            <p className="mt-1 text-sm opacity-90">Host an event in your community</p>
            <button
              onClick={() => { setEventFormType('pro'); setShowEventForm(true); }}
              className="mt-3 rounded-full bg-white px-5 py-2 text-sm font-bold text-arka-pink transition hover:bg-white/90"
            >
              Create Event
            </button>
          </section>
        )}

        {/* Communities */}
        <section className="mt-8">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-black/30">Your Communities</h2>
          <div className="space-y-3">
            {(joinedCommunities.length > 0 ? joinedCommunities : communities.slice(0, 3)).map((c) => {
              const isExpanded = expandedCommunity === c.id;
              const communityMeetups = meetups.filter((m) => m.communityId === c.id);
              const leaderboard = getCommunityLeaderboard(c.id);
              return (
                <div key={c.id} className="rounded-2xl bg-white shadow-sm ring-1 ring-black/5 transition-all">
                  <button
                    onClick={() => onToggleCommunity(c.id)}
                    className="flex w-full items-center justify-between p-4 text-left"
                  >
                    <div>
                      <p className="text-sm font-bold text-arka-text">{c.name}</p>
                      <p className="text-xs text-black/40">{c.location} · {c.members} members</p>
                    </div>
                    <svg className={`h-4 w-4 text-black/20 transition-transform ${isExpanded ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                      <path d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                  {isExpanded && (
                    <div className="border-t border-black/5 px-4 pb-4 pt-3">
                      {c.description && (
                        <p className="mb-3 text-xs text-black/50">{c.description}</p>
                      )}
                      <div className="mb-3 flex gap-3 text-xs">
                        <span className="text-black/40">Stake: <span className="font-semibold text-arka-text">{c.stake}</span></span>
                        {c.membershipFee && (
                          <span className="text-black/40">Fee: <span className="font-semibold text-arka-text">{c.membershipFee}</span></span>
                        )}
                      </div>
                      {/* Leaderboard */}
                      {leaderboard.length > 0 && (
                        <div className="mb-3">
                          <p className="text-[10px] font-bold uppercase tracking-wider text-black/25 mb-1">Leaderboard</p>
                          <div className="rounded-xl bg-gray-50 p-2">
                            {leaderboard.slice(0, 5).map((entry) => (
                              <div
                                key={entry.user.id}
                                className={`flex items-center justify-between rounded-lg px-2 py-1.5 text-xs ${
                                  entry.user.id === currentUserId ? 'bg-arka-pink/10 font-bold text-arka-pink' : 'text-black/60'
                                }`}
                              >
                                <div className="flex items-center gap-2">
                                  <span className={`font-black ${entry.rank === 1 ? 'text-yellow-500' : entry.rank === 2 ? 'text-gray-400' : entry.rank === 3 ? 'text-amber-600' : 'text-black/25'}`}>#{entry.rank}</span>
                                  <span>{entry.user.id === currentUserId ? 'You' : entry.user.username}</span>
                                </div>
                                <span className="font-semibold">{entry.rep}</span>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Events */}
                      {communityMeetups.length > 0 ? (
                        <div className="space-y-2">
                          <p className="text-[10px] font-bold uppercase tracking-wider text-black/25">Events</p>
                          {communityMeetups.map((m) => (
                            <button
                              key={m.id}
                              onClick={() => onEventClick(m.name)}
                              className="flex w-full items-center justify-between rounded-xl bg-gray-50 p-3 text-left transition hover:bg-gray-100"
                            >
                              <div>
                                <p className="text-xs font-semibold text-arka-text">{m.name}</p>
                                <p className="text-[10px] text-black/40">{formatDate(m.datetime)} · {m.attendeeIds.length} attending</p>
                              </div>
                              <svg className="h-3 w-3 text-black/20" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24"><path d="M9 5l7 7-7 7" /></svg>
                            </button>
                          ))}
                        </div>
                      ) : (
                        <p className="text-xs text-black/30">No upcoming events</p>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </section>

        {/* Events */}
        <section className="mt-8">
          <h2 className="mb-3 text-sm font-bold uppercase tracking-wider text-black/30">Upcoming Events</h2>
          <div className="space-y-3">
            {meetups.map((m) => (
              <button
                key={m.id}
                onClick={() => onEventClick(m.name)}
                className="w-full rounded-2xl bg-white p-4 text-left shadow-sm ring-1 ring-black/5 transition hover:shadow-md active:scale-[0.99]"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-bold text-arka-text">{m.name}</p>
                    <p className="text-xs text-black/40">
                      {formatDate(m.datetime)} · {m.attendeeIds?.length || 0} attending
                    </p>
                  </div>
                  <svg className="h-4 w-4 text-black/20" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path d="M9 5l7 7-7 7" />
                  </svg>
                </div>
              </button>
            ))}
          </div>
        </section>

        {/* Telegram CTA */}
        <section className="mt-8 rounded-2xl bg-[#2AABEE]/10 p-5 text-center">
          <p className="text-sm font-semibold text-[#2AABEE]">📱 Get the full experience</p>
          <p className="mt-1 text-xs text-black/40">QR matching, check-ins, and notifications work best in the Telegram mini app.</p>
          <a
            href="https://t.me/arka_telegram_bot"
            target="_blank"
            rel="noopener noreferrer"
            className="mt-3 inline-flex items-center gap-2 rounded-full bg-[#2AABEE] px-5 py-2 text-sm font-semibold text-white transition hover:bg-[#229ED9]"
          >
            <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.37 0 0 5.37 0 12s5.37 12 12 12 12-5.37 12-12S18.63 0 12 0zm5.53 8.15l-1.8 8.5c-.13.6-.5.75-.99.47l-2.76-2.04-1.33 1.28c-.15.15-.27.27-.56.27l.2-2.8 5.1-4.6c.22-.2-.05-.3-.34-.13l-6.3 3.97-2.72-.85c-.59-.18-.6-.59.12-.87l10.63-4.1c.5-.18.93.12.77.87z"/></svg>
            Open in Telegram
          </a>
        </section>
      </main>

      {/* Telegram prompt modal */}
      {telegramPrompt && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={onClosePrompt}>
          <div className="mx-5 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-arka-text">Open in Telegram</h3>
            <p className="mt-2 text-sm text-black/50">
              <strong>{telegramPrompt}</strong> — RSVP, QR matching, and check-ins are available in the Telegram mini app.
            </p>
            <div className="mt-5 flex flex-col gap-2">
              <a
                href="https://t.me/arka_telegram_bot"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2 rounded-xl bg-[#2AABEE] py-3 text-sm font-bold text-white transition hover:bg-[#229ED9]"
              >
                <svg className="h-4 w-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0C5.37 0 0 5.37 0 12s5.37 12 12 12 12-5.37 12-12S18.63 0 12 0zm5.53 8.15l-1.8 8.5c-.13.6-.5.75-.99.47l-2.76-2.04-1.33 1.28c-.15.15-.27.27-.56.27l.2-2.8 5.1-4.6c.22-.2-.05-.3-.34-.13l-6.3 3.97-2.72-.85c-.59-.18-.6-.59.12-.87l10.63-4.1c.5-.18.93.12.77.87z"/></svg>
                Open in Telegram
              </a>
              <button
                onClick={onClosePrompt}
                className="rounded-xl py-3 text-sm font-medium text-black/40 transition hover:bg-black/5"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Pro subscription modal */}
      {showProModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setShowProModal(false)}>
          <div className="mx-5 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-arka-text">🌟 Upgrade to Pro</h3>
            <p className="mt-2 text-sm text-black/50">
              Become a community host and create your own events!
            </p>
            <div className="mt-4 rounded-xl bg-gray-50 p-4">
              <p className="text-xs text-black/40">Subscription Price</p>
              <p className="mt-1 text-2xl font-bold text-arka-pink">0.001 ETH</p>
              <p className="text-xs text-black/40">Valid for 30 days</p>
            </div>
            <p className="mt-3 text-xs text-black/40">
              You&apos;ll be prompted to connect MetaMask and switch to Arbitrum Sepolia.
            </p>
            <div className="mt-5 flex flex-col gap-2">
              <button
                onClick={handleSubscribe}
                disabled={isCreating}
                className="rounded-xl bg-arka-pink py-3 text-sm font-bold text-white transition hover:bg-arka-pink/90 disabled:opacity-50"
              >
                {isCreating ? 'Processing...' : 'Subscribe with MetaMask'}
              </button>
              <button
                onClick={() => setShowProModal(false)}
                className="rounded-xl py-3 text-sm font-medium text-black/40 transition hover:bg-black/5"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* QR Code Modal */}
      {showQRModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setShowQRModal(false)}>
          <div className="mx-5 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-arka-text">My QR Code</h3>
            <p className="mt-1 text-xs text-black/40">Scan to verify or check in</p>
            <div className="mt-4 flex justify-center">
              <QRCodeSVG
                value={JSON.stringify({
                  type: 'arka',
                  action: 'host-checkin',
                  hostAddress: user.address,
                  userId: user.address,
                })}
                size={240}
                level="H"
              />
            </div>
            <p className="mt-3 text-center text-xs text-black/30">{user.address}</p>
            <button
              onClick={() => setShowQRModal(false)}
              className="mt-4 w-full rounded-xl bg-black/5 py-3 text-sm font-medium text-black/60 transition hover:bg-black/10"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Create event form */}
      {showEventForm && !createdEventId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setShowEventForm(false)}>
          <div className="mx-5 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-arka-text">
              {eventFormType === 'quick' ? '⚡ Create Quick Event' : '🎉 Create Event'}
            </h3>
            {eventFormType === 'quick' && (
              <div className="mt-2 rounded-lg bg-amber-50 p-3 text-xs text-amber-900">
                ⚡ Quick events are ephemeral — data won&apos;t be saved after the event ends. Go Pro to keep your data!
              </div>
            )}
            <div className="mt-4 space-y-3">
              <div>
                <label className="text-xs font-medium text-black/60">Event Name *</label>
                <input
                  type="text"
                  value={eventName}
                  onChange={(e) => setEventName(e.target.value)}
                  placeholder="e.g. ETH Budapest Meetup"
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-black/60">Date & Time *</label>
                <input
                  type="datetime-local"
                  value={eventDateTime}
                  onChange={(e) => setEventDateTime(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-black/60">Location *</label>
                <input
                  type="text"
                  value={eventLocation}
                  onChange={(e) => setEventLocation(e.target.value)}
                  placeholder="e.g. Budapest, Hungary"
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none"
                />
              </div>
            </div>
            <div className="mt-5 flex flex-col gap-2">
              <button
                onClick={handleCreateEvent}
                disabled={isCreating || !eventName.trim() || !eventDateTime || !eventLocation.trim()}
                className="rounded-xl bg-arka-pink py-3 text-sm font-bold text-white transition hover:bg-arka-pink/90 disabled:opacity-50"
              >
                {isCreating ? 'Creating...' : 'Create Event'}
              </button>
              <button
                onClick={() => setShowEventForm(false)}
                className="rounded-xl py-3 text-sm font-medium text-black/40 transition hover:bg-black/5"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Event created - show shareable links */}
      {createdEventId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setCreatedEventId(null)}>
          <div className="mx-5 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-arka-text">✨ Event Created!</h3>
            <p className="mt-2 text-sm text-black/50">
              Share these links to invite attendees:
            </p>
            <div className="mt-4 space-y-3">
              <div>
                <p className="text-xs font-semibold text-black/40 mb-1">Telegram Deep Link</p>
                <div className="flex items-center gap-2">
                  <code className="flex-1 rounded-lg bg-gray-100 px-3 py-2 text-xs text-arka-text break-all">
                    https://t.me/arka_telegram_bot?startapp=event_{createdEventId}
                  </code>
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(`https://t.me/arka_telegram_bot?startapp=event_${createdEventId}`);
                      alert('Copied!');
                    }}
                    className="rounded-lg bg-arka-cyan px-3 py-2 text-xs font-semibold text-white"
                  >
                    Copy
                  </button>
                </div>
              </div>
              <div>
                <p className="text-xs font-semibold text-black/40 mb-1">Direct Link</p>
                <div className="flex items-center gap-2">
                  <code className="flex-1 rounded-lg bg-gray-100 px-3 py-2 text-xs text-arka-text break-all">
                    https://arka.social/miniapp/event/{createdEventId}
                  </code>
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(`https://arka.social/miniapp/event/${createdEventId}`);
                      alert('Copied!');
                    }}
                    className="rounded-lg bg-arka-cyan px-3 py-2 text-xs font-semibold text-white"
                  >
                    Copy
                  </button>
                </div>
              </div>
            </div>
            <button
              onClick={() => { setCreatedEventId(null); setShowEventForm(false); }}
              className="mt-5 w-full rounded-xl bg-arka-pink py-3 text-sm font-bold text-white transition hover:bg-arka-pink/90"
            >
              Done
            </button>
          </div>
        </div>
      )}

      {/* Create community form */}
      {showCommunityForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setShowCommunityForm(false)}>
          <div className="mx-5 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-arka-text">✨ Create Your Community</h3>
            <div className="mt-4 space-y-3">
              <div>
                <label className="text-xs font-medium text-black/60">Community Name *</label>
                <input
                  type="text"
                  value={communityName}
                  onChange={(e) => setCommunityName(e.target.value)}
                  placeholder="e.g. SF Web3 Builders"
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-black/60">Description</label>
                <textarea
                  value={communityDescription}
                  onChange={(e) => setCommunityDescription(e.target.value)}
                  placeholder="What's your community about?"
                  rows={3}
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none"
                />
              </div>
              <div>
                <label className="text-xs font-medium text-black/60">Location</label>
                <input
                  type="text"
                  value={communityLocation}
                  onChange={(e) => setCommunityLocation(e.target.value)}
                  placeholder="e.g. San Francisco, CA"
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none"
                />
              </div>
            </div>
            <div className="mt-5 flex flex-col gap-2">
              <button
                onClick={handleCreateCommunity}
                disabled={isCreating || !communityName.trim()}
                className="rounded-xl bg-arka-green py-3 text-sm font-bold text-white transition hover:bg-arka-green/90 disabled:opacity-50"
              >
                {isCreating ? 'Creating...' : 'Create Community'}
              </button>
              <button
                onClick={() => setShowCommunityForm(false)}
                className="rounded-xl py-3 text-sm font-medium text-black/40 transition hover:bg-black/5"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function WalletBadge({ user, primaryWallet }: { user: any; primaryWallet: any }) {
  const [showDetails, setShowDetails] = useState(false);
  const [balance, setBalance] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!user?.address || !user.address.startsWith('0x')) return;
    const fetchBalance = async () => {
      try {
        const resp = await fetch('https://sepolia-rollup.arbitrum.io/rpc', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ jsonrpc: '2.0', method: 'eth_getBalance', params: [user.address, 'latest'], id: 1 }),
        });
        const data = await resp.json();
        const wei = parseInt(data.result, 16);
        setBalance((wei / 1e18).toFixed(4));
      } catch { setBalance(null); }
    };
    fetchBalance();
    const interval = setInterval(fetchBalance, 15000);
    return () => clearInterval(interval);
  }, [user?.address]);

  const copyAddress = () => {
    if (user?.address) {
      navigator.clipboard.writeText(user.address);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  return (
    <div className="relative">
      <button
        onClick={() => setShowDetails(!showDetails)}
        className="flex flex-col items-end"
      >
        <span className="text-xs font-medium text-black/50">{user.username}</span>
        {balance !== null && (
          <span className="text-[10px] font-semibold text-arka-cyan">{balance} ETH</span>
        )}
      </button>
      {showDetails && user?.address && (
        <div className="absolute right-0 top-full mt-2 z-50 w-64 rounded-xl bg-white p-3 shadow-lg ring-1 ring-black/10">
          <p className="text-[10px] text-black/30 mb-1">Wallet Address</p>
          <button onClick={copyAddress} className="flex items-center gap-2 w-full text-left">
            <code className="text-xs text-arka-text break-all">{user.address}</code>
            <span className="text-[10px] text-arka-pink font-semibold shrink-0">{copied ? '✓' : 'Copy'}</span>
          </button>
          {balance !== null && (
            <div className="mt-2 pt-2 border-t border-black/5">
              <p className="text-[10px] text-black/30">Balance (Arb Sepolia)</p>
              <p className="text-sm font-bold text-arka-text">{balance} ETH</p>
            </div>
          )}
          <p className="mt-2 text-[9px] text-black/20">Network: Arbitrum Sepolia</p>
        </div>
      )}
    </div>
  );
}

function PhoneMockup({ children }: { children: React.ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.style.transform = 'translateX(0)';
          el.style.opacity = '1';
        }
      },
      { threshold: 0.3 }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={ref}
      className="transition-all duration-700 ease-out"
      style={{ transform: 'translateX(60px)', opacity: 0 }}
    >
      <div className="mx-auto w-[220px] rounded-[28px] border-[6px] border-black/80 bg-white shadow-2xl lg:w-[280px]">
        <div className="mx-auto mt-1 h-[14px] w-[60px] rounded-full bg-black/80" />
        <div className="h-[380px] overflow-hidden rounded-b-[22px] lg:h-[480px]">
          {children}
        </div>
      </div>
    </div>
  );
}
