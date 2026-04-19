'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import ArkaLogo from '@/components/ArkaLogo';
import { CommunityIcon, MeetupIcon, TrophyIcon, QrIcon } from '@/components/Icons';
import { useAuth } from '@/lib/auth-context';

const API_URL = 'https://arka-api.claws.page';

export default function MiniAppPage() {
  const [isTelegram, setIsTelegram] = useState<boolean | null>(null);
  const router = useRouter();
  const { user, openSignIn, isProHost, isConnected } = useAuth();
  const [showEventForm, setShowEventForm] = useState(false);
  const [eventName, setEventName] = useState('');
  const [eventDateTime, setEventDateTime] = useState('');
  const [eventLocation, setEventLocation] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  useEffect(() => {
    const tg = window.Telegram?.WebApp;
    if (tg?.initDataUnsafe?.user) {
      setIsTelegram(true);
      tg.ready();
      tg.expand();
      tg.setHeaderColor('#ffffff');
      tg.MainButton.setParams({ color: '#E5007D', text_color: '#ffffff' });
      // Enable back button
      (tg as any).BackButton?.show?.();
      (tg as any).BackButton?.onClick?.(() => {
        if (window.history.length > 1) {
          router.back();
        } else {
          (tg as any).close?.();
        }
      });
    } else {
      // Still allow miniapp outside Telegram (direct link)
      setIsTelegram(false);
    }
  }, [router]);

  if (isTelegram === null) return null;

  const tgUser = window.Telegram?.WebApp?.initDataUnsafe?.user;
  const displayName = tgUser?.first_name || user?.username?.replace('@', '') || 'there';

  // If not signed in, show sign-in screen
  if (!isConnected && !tgUser) {
    return (
      <main className="mx-auto flex min-h-screen w-full max-w-md flex-col items-center justify-center bg-white px-8">
        <ArkaLogo size={64} />
        <h1 className="mt-6 text-2xl font-bold text-arka-text">Welcome to arka</h1>
        <p className="mt-2 text-center text-sm text-black/50">
          Real connections, real events. Sign in to get started.
        </p>
        <button
          onClick={openSignIn}
          className="mt-8 w-full rounded-xl bg-arka-pink py-3 text-sm font-bold text-white transition active:scale-95"
        >
          Sign In with Email
        </button>
        <p className="mt-3 text-[10px] text-black/30">An embedded wallet will be created for you</p>
      </main>
    );
  }

  const handleCreateEvent = async () => {
    if (!eventName.trim() || !eventDateTime || !eventLocation.trim()) {
      alert('All fields are required');
      return;
    }
    try {
      setIsCreating(true);
      const res = await fetch(`${API_URL}/events`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          hostTgId: tgUser?.id?.toString(),
          hostAddress: user?.address,
          communityId: null,
          name: eventName,
          datetime: eventDateTime,
          location: eventLocation,
          ephemeral: !isProHost,
        }),
      });
      const data = await res.json();
      if (data.success) {
        router.push(`/miniapp/event/${data.event.id}`);
      } else {
        alert(data.error || 'Failed to create event');
      }
    } catch (error: any) {
      alert(error.message || 'Failed to create event');
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <main className="mx-auto min-h-screen w-full max-w-md bg-white">
      {/* Header */}
      <header className="flex items-center justify-between px-5 py-4">
        <div className="flex items-center gap-2">
          <ArkaLogo size={28} />
          <span className="text-base font-bold text-arka-text">arka</span>
        </div>
        <div className="flex items-center gap-2">
          {user && (
            <span className="text-[10px] text-black/40">{user.username || user.email}</span>
          )}
          <button
            onClick={() => router.push('/miniapp/profile')}
            className="rounded-full bg-arka-pink px-4 py-1.5 text-xs font-semibold text-white transition hover:bg-arka-pink/90"
          >
            Profile
          </button>
        </div>
      </header>

      {/* Welcome */}
      <section className="px-5 pb-4 pt-2">
        <h1 className="text-xl font-bold text-arka-text">
          Hey {displayName} 👋
        </h1>
      </section>

      {/* Quick stats */}
      <section className="grid grid-cols-3 gap-3 px-5 pb-5">
        <div className="rounded-xl bg-arka-pink/10 p-3 text-center">
          <p className="text-2xl font-black text-arka-pink">2</p>
          <p className="text-[10px] text-black/40">Communities</p>
        </div>
        <div className="rounded-xl bg-arka-cyan/10 p-3 text-center">
          <p className="text-2xl font-black text-arka-cyan">5</p>
          <p className="text-[10px] text-black/40">Events</p>
        </div>
        <button
          onClick={() => router.push('/miniapp/leaderboard')}
          className="rounded-xl bg-arka-green/10 p-3 text-center transition active:scale-95"
        >
          <p className="text-2xl font-black text-arka-green">#3</p>
          <p className="text-[10px] text-black/40">Rank →</p>
        </button>
      </section>

      {/* Updates */}
      <section className="px-5 pb-5">
        <p className="mb-2 text-xs font-bold uppercase tracking-wider text-black/30">Updates</p>
        <div className="space-y-2">
          <div className="rounded-xl bg-arka-pink/5 p-3 ring-1 ring-arka-pink/10">
            <div className="flex items-start gap-2">
              <span className="text-sm">🎉</span>
              <div>
                <p className="text-xs font-semibold text-arka-text">New Event: ETH Budapest Meetup</p>
                <p className="text-[10px] text-black/40">Tomorrow, 18:00 · 23 attending</p>
              </div>
            </div>
          </div>
          <div className="rounded-xl bg-arka-green/5 p-3 ring-1 ring-arka-green/10">
            <div className="flex items-start gap-2">
              <span className="text-sm">📈</span>
              <div>
                <p className="text-xs font-semibold text-arka-text">Your reputation rose +120 this week</p>
                <p className="text-[10px] text-black/40">You&apos;re now #3 in ETH Budapest</p>
              </div>
            </div>
          </div>
          <div className="rounded-xl bg-arka-cyan/5 p-3 ring-1 ring-arka-cyan/10">
            <div className="flex items-start gap-2">
              <span className="text-sm">👥</span>
              <div>
                <p className="text-xs font-semibold text-arka-text">3 new members joined Arbitrum Builders</p>
                <p className="text-[10px] text-black/40">Community now has 127 members</p>
              </div>
            </div>
          </div>
          <div className="rounded-xl bg-amber-50 p-3 ring-1 ring-amber-200/30">
            <div className="flex items-start gap-2">
              <span className="text-sm">🏆</span>
              <div>
                <p className="text-xs font-semibold text-arka-text">alex.eth overtook you on the leaderboard</p>
                <p className="text-[10px] text-black/40">Attend more events to reclaim #2!</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Next Event */}
      <section className="px-5 pb-5">
        <p className="mb-2 text-xs font-bold uppercase tracking-wider text-black/30">Next Event</p>
        <button
          onClick={() => router.push('/miniapp/event/mock-eth-budapest')}
          className="w-full rounded-2xl bg-white p-4 text-left shadow-md ring-1 ring-black/5 transition active:scale-[0.98]"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-bold text-arka-text">ETH Budapest Meetup</p>
              <p className="mt-0.5 text-xs text-black/40">Tomorrow, 18:00 · 23 attending</p>
            </div>
            <span className="rounded-full bg-arka-green/15 px-2 py-0.5 text-xs font-semibold text-arka-green">RSVP&apos;d</span>
          </div>
        </button>
      </section>

      {/* Leaderboard preview */}
      <section className="px-5 pb-5">
        <div className="flex items-center justify-between mb-2">
          <p className="text-xs font-bold uppercase tracking-wider text-black/30">Leaderboard</p>
          <button
            onClick={() => router.push('/miniapp/leaderboard')}
            className="text-[10px] font-semibold text-arka-pink"
          >
            View All →
          </button>
        </div>
        <div className="rounded-2xl bg-white p-3 shadow-sm ring-1 ring-black/5">
          {[
            { rank: 1, name: 'alex.eth', rep: 3200, color: 'text-yellow-500' },
            { rank: 2, name: 'sarah.arb', rep: 2800, color: 'text-gray-400' },
            { rank: 3, name: 'You', rep: 2450, color: 'text-amber-600', highlight: true },
          ].map((r) => (
            <div
              key={r.rank}
              className={`flex items-center justify-between rounded-lg px-2 py-2 text-xs ${
                r.highlight ? 'bg-arka-pink/10 font-bold text-arka-pink' : 'text-black/60'
              }`}
            >
              <div className="flex items-center gap-2">
                <span className={`text-sm font-black ${r.color}`}>#{r.rank}</span>
                <span>{r.name}</span>
              </div>
              <span className="font-semibold">{r.rep}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Create Event */}
      <section className="px-5 pb-4">
        <button
          onClick={() => setShowEventForm(true)}
          className="w-full rounded-xl bg-gradient-to-r from-arka-pink to-arka-cyan p-4 text-left text-white shadow-lg transition active:scale-[0.98]"
        >
          <p className="text-sm font-bold">🎉 Create Event</p>
          <p className="text-xs opacity-80">
            {isProHost ? 'Host an event in your community' : 'Create a quick ephemeral event'}
          </p>
        </button>
      </section>

      {/* Quick actions */}
      <section className="space-y-3 px-5 pb-10">
        <p className="mb-1 text-xs font-bold uppercase tracking-wider text-black/30">Quick Actions</p>
        {[
          { Icon: CommunityIcon, color: 'cyan', title: 'Browse Communities', path: '/miniapp/communities' },
          { Icon: MeetupIcon, color: 'green', title: 'Upcoming Events', path: '/miniapp/event/mock-eth-budapest' },
          { Icon: TrophyIcon, color: 'purple', title: 'Leaderboard', path: '/miniapp/leaderboard' },
          { Icon: QrIcon, color: 'orange', title: 'Scan QR Code', path: '/miniapp/event/mock-eth-budapest' },
        ].map(({ Icon, color, title, path }) => (
          <button
            key={title}
            onClick={() => router.push(path)}
            className="flex w-full items-center gap-3 rounded-xl bg-arka-card p-4 text-left transition active:scale-[0.98]"
          >
            <div className={`flex h-10 w-10 items-center justify-center rounded-full bg-arka-${color}/15`}>
              <Icon className={`h-5 w-5 text-arka-${color}`} />
            </div>
            <span className="text-sm font-semibold text-arka-text">{title}</span>
          </button>
        ))}
      </section>

      {/* Event creation modal */}
      {showEventForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={() => setShowEventForm(false)}>
          <div className="mx-5 w-full max-w-sm rounded-2xl bg-white p-6 shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="text-lg font-bold text-arka-text">
              {isProHost ? '🎉 Create Event' : '⚡ Quick Event'}
            </h3>
            {!isProHost && (
              <div className="mt-2 rounded-lg bg-amber-50 p-3 text-xs text-amber-900">
                ⚡ Quick events are ephemeral — data won&apos;t persist. Go Pro to keep it!
              </div>
            )}
            <div className="mt-4 space-y-3">
              <div>
                <label className="text-xs font-medium text-black/60">Event Name *</label>
                <input type="text" value={eventName} onChange={(e) => setEventName(e.target.value)}
                  placeholder="e.g. ETH Budapest Meetup"
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none" />
              </div>
              <div>
                <label className="text-xs font-medium text-black/60">Date & Time *</label>
                <input type="datetime-local" value={eventDateTime} onChange={(e) => setEventDateTime(e.target.value)}
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none" />
              </div>
              <div>
                <label className="text-xs font-medium text-black/60">Location *</label>
                <input type="text" value={eventLocation} onChange={(e) => setEventLocation(e.target.value)}
                  placeholder="e.g. Budapest, Hungary"
                  className="mt-1 w-full rounded-lg border border-black/10 px-3 py-2 text-sm focus:border-arka-pink focus:outline-none" />
              </div>
            </div>
            <div className="mt-5 flex flex-col gap-2">
              <button onClick={handleCreateEvent} disabled={isCreating || !eventName.trim() || !eventDateTime || !eventLocation.trim()}
                className="rounded-xl bg-arka-pink py-3 text-sm font-bold text-white transition hover:bg-arka-pink/90 disabled:opacity-50">
                {isCreating ? 'Creating...' : 'Create Event'}
              </button>
              <button onClick={() => setShowEventForm(false)}
                className="rounded-xl py-3 text-sm font-medium text-black/40 transition hover:bg-black/5">
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
