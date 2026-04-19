'use client';

import { useEffect, useState } from 'react';
import { useRouter, useParams } from 'next/navigation';
import ArkaLogo from '@/components/ArkaLogo';
import EventChat from '@/components/EventChat';
import EventPoll from '@/components/EventPoll';
import { useAuth } from '@/lib/auth-context';

const API_URL = 'https://arka-api.claws.page';

interface EventState {
  checkedIn: boolean;
  verifications: string[];
  mingles: string[];
  isHost: boolean;
  mingleActive: boolean;
  currentMingleNum: number | null;
  ended: boolean;
}

interface Event {
  id: string;
  name: string;
  datetime: string;
  location: string;
  hostTgId: string;
  attendees: Record<string, any>;
  mingleActive: boolean;
  ended: boolean;
}

export default function EventPage() {
  const router = useRouter();
  const params = useParams();
  const eventId = params.id as string;
  
  const [isTelegram, setIsTelegram] = useState<boolean | null>(null);
  const [event, setEvent] = useState<Event | null>(null);
  const [state, setState] = useState<EventState | null>(null);
  const [loading, setLoading] = useState(true);
  const [userId, setUserId] = useState<string>('');
  const [username, setUsername] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'event' | 'chat' | 'poll'>('event');
  const [hasAutoJoined, setHasAutoJoined] = useState(false);
  const { user } = useAuth();

  useEffect(() => {
    const tg = window.Telegram?.WebApp;
    if (tg?.initDataUnsafe?.user) {
      setIsTelegram(true);
      tg.ready();
      tg.expand();
      setUserId(tg.initDataUnsafe.user.id.toString());
      setUsername(tg.initDataUnsafe.user.first_name || 'User');
    } else {
      // Not in Telegram, but might have Dynamic wallet
      setIsTelegram(false);
      if (user?.address) {
        setUserId(user.address);
        setUsername(user.username || 'User');
      } else {
        router.replace('/');
      }
    }
  }, [router, user]);

  useEffect(() => {
    if (!userId || !eventId) return;

    const fetchData = async () => {
      try {
        const [eventRes, stateRes] = await Promise.all([
          fetch(`${API_URL}/events/${eventId}`),
          fetch(`${API_URL}/events/${eventId}/state/${userId}`),
        ]);

        if (eventRes.ok) setEvent(await eventRes.json());
        if (stateRes.ok) {
          const stateData = await stateRes.json();
          setState(stateData);
          
          // Auto-join if not already in the event
          if (!hasAutoJoined && !stateData.checkedIn && !stateData.joined) {
            setHasAutoJoined(true);
            try {
              const userKey = isTelegram ? { userId } : { userAddress: userId };
              await fetch(`${API_URL}/events/${eventId}/join`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(userKey),
              });
              console.log('Auto-joined event');
            } catch (err) {
              console.error('Auto-join failed:', err);
            }
          }
        }
      } catch (err) {
        console.error('Failed to fetch event:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 3000); // Poll every 3s
    return () => clearInterval(interval);
  }, [userId, eventId, hasAutoJoined, isTelegram]);

  if (isTelegram === null) return null;
  if (isTelegram === false) return null;
  if (loading) return <div className="flex min-h-screen items-center justify-center">Loading...</div>;
  if (!event || !state) return <div className="flex min-h-screen items-center justify-center">Event not found</div>;

  const attendeeCount = Object.keys(event.attendees).filter(uid => event.attendees[uid].checkedIn).length;
  const verificationProgress = Math.min(state.verifications.length, 3);
  const attendeeList = Object.entries(event.attendees)
    .filter(([_, a]) => a.checkedIn)
    .map(([uid, a]) => ({
      id: uid,
      verifications: a.verifications?.length || 0,
      checkedInAt: a.checkedInAt,
    }));

  const handleCheckIn = () => {
    router.push(`/miniapp/event/${eventId}/scan?mode=checkin`);
  };

  const handleVerify = () => {
    router.push(`/miniapp/event/${eventId}/scan?mode=verify`);
  };

  const handleShowQR = () => {
    router.push(`/miniapp/event/${eventId}/qr`);
  };

  const handleStartMingle = async () => {
    try {
      const res = await fetch(`${API_URL}/events/${eventId}/mingle/start`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
      if (res.ok) {
        alert('Mingle started! 🎲');
      }
    } catch (err) {
      console.error('Failed to start mingle:', err);
    }
  };

  const handleEndEvent = async () => {
    if (!confirm('Are you sure you want to end this event?')) return;
    
    try {
      const res = await fetch(`${API_URL}/events/${eventId}/end`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });
      if (res.ok) {
        const data = await res.json();
        alert(`Event ended!\n\nAttendees: ${data.summary.attendees}\nVerifications: ${data.summary.verifications}\nMingles: ${data.summary.mingles}`);
      }
    } catch (err) {
      console.error('Failed to end event:', err);
    }
  };

  // If mingle is active, show mingle screen
  if (state.mingleActive && state.currentMingleNum) {
    return (
      <main className="mx-auto min-h-screen w-full max-w-md bg-white px-5 py-6">
        <header className="mb-6 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button onClick={() => router.back()} className="text-lg">←</button>
            <ArkaLogo size={24} />
            <span className="text-sm font-bold text-arka-text">arka</span>
          </div>
          <button
            onClick={() => router.push('/miniapp')}
            className="text-xs text-black/40"
          >
            Home
          </button>
        </header>

        <div className="text-center">
          <h1 className="mb-2 text-xl font-bold text-arka-text">{event.name}</h1>
          <p className="mb-8 text-sm text-black/40">Find your mingle match!</p>

          <div className="mb-8 rounded-2xl bg-arka-pink/10 py-12">
            <p className="text-6xl font-black text-arka-pink">#{state.currentMingleNum}</p>
            <p className="mt-2 text-sm text-black/40">Your match number</p>
          </div>

          <button
            onClick={handleShowQR}
            className="mb-4 w-full rounded-xl bg-arka-cyan px-6 py-4 font-semibold text-white"
          >
            Show My QR Code
          </button>

          <button
            onClick={() => router.push(`/miniapp/event/${eventId}/scan?mode=mingle`)}
            className="w-full rounded-xl bg-arka-pink px-6 py-4 font-semibold text-white"
          >
            📷 Scan Partner
          </button>
        </div>
      </main>
    );
  }

  return (
    <main className="mx-auto min-h-screen w-full max-w-md bg-white">
      <header className="sticky top-0 z-10 bg-white px-5 py-4">
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <button onClick={() => router.back()} className="text-lg">←</button>
            <ArkaLogo size={24} />
            <span className="text-sm font-bold text-arka-text">arka</span>
          </div>
          <button
            onClick={() => router.push('/miniapp')}
            className="text-xs text-black/40"
          >
            Home
          </button>
        </div>
        
        {/* Tabs */}
        <div className="flex gap-1 rounded-lg bg-gray-100 p-1">
          <button
            onClick={() => setActiveTab('event')}
            className={`flex-1 rounded-md px-3 py-2 text-xs font-semibold transition ${
              activeTab === 'event' ? 'bg-white text-arka-text shadow-sm' : 'text-black/40'
            }`}
          >
            Event
          </button>
          <button
            onClick={() => setActiveTab('chat')}
            className={`flex-1 rounded-md px-3 py-2 text-xs font-semibold transition ${
              activeTab === 'chat' ? 'bg-white text-arka-text shadow-sm' : 'text-black/40'
            }`}
          >
            Chat
          </button>
          <button
            onClick={() => setActiveTab('poll')}
            className={`flex-1 rounded-md px-3 py-2 text-xs font-semibold transition ${
              activeTab === 'poll' ? 'bg-white text-arka-text shadow-sm' : 'text-black/40'
            }`}
          >
            Poll
          </button>
        </div>
      </header>

      {activeTab === 'chat' && (
        <EventChat eventId={eventId} userId={userId} username={username} />
      )}

      {activeTab === 'poll' && (
        <EventPoll eventId={eventId} userId={userId} isHost={state.isHost} />
      )}

      {activeTab === 'event' && (
        <div className="px-5 py-6">
          {/* Event info */}
          <div className="mb-6">
        <h1 className="mb-1 text-2xl font-bold text-arka-text">{event.name}</h1>
        <p className="text-sm text-black/50">{event.location}</p>
        <p className="text-sm text-black/50">{new Date(event.datetime).toLocaleString()}</p>
        <p className="mt-2 text-sm font-semibold text-arka-cyan">{attendeeCount} attending</p>
      </div>

      {event.ended && (
        <div className="mb-6 rounded-xl bg-black/5 p-4 text-center">
          <p className="font-semibold text-black/60">Event ended 🏁</p>
        </div>
      )}

      {/* Not checked in */}
      {!state.checkedIn && !event.ended && (
        <div className="mb-6">
          <button
            onClick={handleCheckIn}
            className="w-full rounded-xl bg-arka-green px-6 py-4 text-lg font-semibold text-white"
          >
            ✓ Check In
          </button>
          <p className="mt-2 text-center text-xs text-black/40">Scan the host&apos;s QR code to check in</p>
        </div>
      )}

      {/* Checked in - Verification progress */}
      {state.checkedIn && !event.ended && (
        <div className="mb-6">
          <div className="mb-4 rounded-xl bg-arka-green/10 p-4">
            <p className="mb-2 text-sm font-semibold text-arka-green">✓ Checked In</p>
            <p className="text-xs text-black/40">Verification Progress: {verificationProgress}/3</p>
            <div className="mt-2 flex gap-1">
              {[1, 2, 3].map(i => (
                <div
                  key={i}
                  className={`h-2 flex-1 rounded-full ${
                    i <= verificationProgress ? 'bg-arka-green' : 'bg-black/10'
                  }`}
                />
              ))}
            </div>
          </div>

          {verificationProgress < 3 && (
            <button
              onClick={handleVerify}
              className="w-full rounded-xl bg-arka-cyan px-6 py-4 font-semibold text-white"
            >
              🤝 Verify with Attendee
            </button>
          )}

          <button
            onClick={handleShowQR}
            className="mt-3 w-full rounded-xl bg-white px-6 py-3 font-semibold text-arka-text ring-1 ring-black/10"
          >
            Show My QR Code
          </button>
        </div>
      )}

      {/* Host actions */}
      {state.isHost && !event.ended && (
        <div className="mb-6 space-y-3 rounded-xl bg-arka-pink/5 p-4">
          <p className="text-sm font-bold text-arka-pink">Host Controls</p>
          
          <button
            onClick={handleShowQR}
            className="w-full rounded-lg bg-arka-cyan px-4 py-3 text-sm font-semibold text-white"
          >
            Show Check-in QR
          </button>

          <button
            onClick={handleStartMingle}
            disabled={attendeeCount < 2 || event.mingleActive}
            className="w-full rounded-lg bg-arka-green px-4 py-3 text-sm font-semibold text-white disabled:opacity-50"
          >
            🎲 Start Mingle Round
          </button>

          <button
            onClick={handleEndEvent}
            className="w-full rounded-lg bg-black/80 px-4 py-3 text-sm font-semibold text-white"
          >
            End Event
          </button>

          <div className="mt-4">
            <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-black/40">Live Attendees ({attendeeList.length})</p>
            <div className="max-h-40 overflow-y-auto space-y-1">
              {attendeeList.map((att) => (
                <div key={att.id} className="flex items-center justify-between rounded-lg bg-gray-50 px-2 py-1.5">
                  <span className="text-xs text-black/60">
                    {att.id.startsWith('0x') ? `${att.id.slice(0, 6)}...${att.id.slice(-4)}` : `User ${att.id.slice(-4)}`}
                  </span>
                  <div className="flex items-center gap-2">
                    {att.verifications > 0 && (
                      <span className="text-[10px] text-arka-green font-semibold">{att.verifications} verif.</span>
                    )}
                    <span className="text-[9px] text-black/30">{new Date(att.checkedInAt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
        </div>
      )}
    </main>
  );
}
