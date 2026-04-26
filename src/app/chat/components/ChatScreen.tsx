'use client';
import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useSearchParams } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Send, ArrowLeft } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useUserProfile } from '../../../context/UserProfileContext';
import { streamChatMessage } from '../../../utils/claudeApi';
import TabBar from '../../../components/TabBar';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;}

const SUGGESTED_PROMPTS = [
  'What is my biggest deduction opportunity?',
  'How do I pay quarterly taxes?',
  'Can I deduct my car payment?',
  'What records should I keep?',
  'Explain the QBI deduction',
  'How much should I save each week?',
];

const WELCOME_MESSAGE: Message = {
  id: 'msg-welcome',
  role: 'assistant',
  content: "Hey! I'm GigFlow AI 👋 I've analyzed your gig work profile and I'm here to help you navigate taxes, maximize deductions, and build better financial habits. What would you like to know?",
  timestamp: new Date(),
};

export default function ChatScreen() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { profile, activateDemoMode } = useUserProfile();
  const [messages, setMessages] = useState<Message[]>([WELCOME_MESSAGE]);
  const [input, setInput] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const [streamingId, setStreamingId] = useState<string | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const hasInitialized = useRef(false);

  // Pre-populate from query param
  useEffect(() => {
    if (hasInitialized.current) return;
    hasInitialized.current = true;
    const prompt = searchParams.get('prompt');
    if (prompt) {
      setInput(decodeURIComponent(prompt));
    }
  }, [searchParams]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isStreaming]);

  const isReady = profile.isOnboarded || profile.isDemoMode;

  const sendMessage = useCallback(async (text?: string) => {
    const messageText = (text ?? input).trim();
    if (!messageText || isStreaming) return;

    if (!isReady) {
      activateDemoMode();
    }

    const userMsg: Message = {
      id: `msg-user-${Date.now()}`,
      role: 'user',
      content: messageText,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMsg]);
    setInput('');
    setIsStreaming(true);

    const assistantId = `msg-assistant-${Date.now()}`;
    setStreamingId(assistantId);
    setMessages(prev => [...prev, {
      id: assistantId,
      role: 'assistant',
      content: '',
      timestamp: new Date(),
    }]);

    const history = [...messages, userMsg].map(m => ({
      role: m.role,
      content: m.content,
    }));

    // Backend integration point: streamChatMessage calls Claude API with streaming
    try {
      const stream = streamChatMessage(history, profile);
      for await (const chunk of stream) {
        setMessages(prev => prev.map(m =>
          m.id === assistantId ? { ...m, content: m.content + chunk } : m
        ));
      }
    } finally {
      setIsStreaming(false);
      setStreamingId(null);
    }
  }, [input, isStreaming, messages, profile, isReady, activateDemoMode]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
  };

  return (
    <div className="flex flex-col h-screen" style={{ background: '#0D0F12', maxWidth: 430, margin: '0 auto' }}>
      {/* Chat header */}
      <div
        className="flex items-center gap-3 px-5 pt-14 pb-4"
        style={{ borderBottom: '1px solid #2A2D35', background: '#0D0F12' }}
      >
        <button
          onClick={() => router.back()}
          className="w-9 h-9 rounded-full flex items-center justify-center transition-all active:scale-95"
          style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}
          aria-label="Go back"
        >
          <ArrowLeft size={18} color="#8B90A0" />
        </button>
        <div className="flex items-center gap-3 flex-1">
          <div
            className="w-9 h-9 rounded-full flex items-center justify-center text-base"
            style={{ background: 'linear-gradient(135deg, #00C853, #00E676)' }}
          >
            💰
          </div>
          <div>
            <p className="text-sm font-semibold" style={{ color: '#F0F2F5' }}>GigFlow AI</p>
            <div className="flex items-center gap-1.5">
              <div className="w-1.5 h-1.5 rounded-full" style={{ background: '#00E676', animation: 'pulse-green 2s ease-in-out infinite' }} />
              <p className="text-xs" style={{ color: '#00E676' }}>Online</p>
            </div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-4 scrollbar-hide" style={{ paddingBottom: 120 }}>
        <AnimatePresence initial={false}>
          {messages.map((msg, i) => (
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 12, scale: 0.96 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.2, ease: [0.4, 0, 0.2, 1] }}
              className={`flex mb-4 ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              {msg.role === 'assistant' && (
                <div
                  className="w-7 h-7 rounded-full flex items-center justify-center text-sm flex-shrink-0 mr-2 mt-1"
                  style={{ background: 'linear-gradient(135deg, #00C853, #00E676)' }}
                >
                  💰
                </div>
              )}
              <div className={`max-w-[75%] ${msg.role === 'user' ? 'items-end' : 'items-start'} flex flex-col`}>
                <div
                  className="px-4 py-3 rounded-2xl"
                  style={{
                    background: msg.role === 'user' ?'linear-gradient(135deg, #00C853, #00E676)' :'#1A1D23',
                    border: msg.role === 'user' ? 'none' : '1px solid #2A2D35',
                    borderBottomRightRadius: msg.role === 'user' ? 4 : 16,
                    borderBottomLeftRadius: msg.role === 'assistant' ? 4 : 16,
                  }}
                >
                  {msg.content === '' && msg.id === streamingId ? (
                    <TypingIndicator />
                  ) : (
                    <p
                      className="text-sm leading-relaxed whitespace-pre-wrap"
                      style={{
                        color: msg.role === 'user' ? '#0D0F12' : '#F0F2F5',
                        fontFamily: 'DM Sans, sans-serif',
                      }}
                    >
                      {msg.content}
                      {msg.id === streamingId && isStreaming && (
                        <span
                          className="inline-block w-0.5 h-4 ml-0.5 align-middle"
                          style={{ background: '#00E676', animation: 'pulse-green 1s ease-in-out infinite' }}
                        />
                      )}
                    </p>
                  )}
                </div>
                <p className="text-xs mt-1 px-1" style={{ color: '#4A4F5C' }}>
                  {formatTime(msg.timestamp)}
                </p>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>

        {/* Suggested prompts — shown after welcome message only */}
        {messages.length === 1 && (
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="mt-2"
          >
            <p className="text-xs mb-3 px-1" style={{ color: '#8B90A0' }}>Suggested questions:</p>
            <div className="flex flex-wrap gap-2">
              {SUGGESTED_PROMPTS.map(prompt => (
                <button
                  key={`prompt-${prompt.slice(0, 20)}`}
                  onClick={() => sendMessage(prompt)}
                  className="px-3 py-2 rounded-xl text-xs font-medium transition-all active:scale-95"
                  style={{
                    background: '#1A1D23',
                    border: '1px solid #2A2D35',
                    color: '#8B90A0',
                  }}
                >
                  {prompt}
                </button>
              ))}
            </div>
          </motion.div>
        )}

        <div ref={bottomRef} />
      </div>

      {/* Input bar */}
      <div
        className="px-4 py-3"
        style={{
          background: '#0D0F12',
          borderTop: '1px solid #2A2D35',
          paddingBottom: 'calc(80px + env(safe-area-inset-bottom, 0px))',
        }}
      >
        <div
          className="flex items-center gap-3 px-4 py-3 rounded-2xl"
          style={{ background: '#1A1D23', border: '1px solid #2A2D35' }}
        >
          <input
            ref={inputRef}
            type="text"
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Ask about taxes, deductions, savings..."
            className="flex-1 bg-transparent outline-none text-sm"
            style={{
              color: '#F0F2F5',
              fontFamily: 'DM Sans, sans-serif',
            }}
            aria-label="Chat message input"
          />
          <button
            onClick={() => sendMessage()}
            disabled={!input.trim() || isStreaming}
            className="w-9 h-9 rounded-xl flex items-center justify-center transition-all active:scale-95"
            style={{
              background: input.trim() && !isStreaming
                ? 'linear-gradient(135deg, #00C853, #00E676)'
                : '#2A2D35',
              border: 'none',
            }}
            aria-label="Send message"
          >
            <Send size={16} color={input.trim() && !isStreaming ? '#0D0F12' : '#4A4F5C'} />
          </button>
        </div>
      </div>

      <TabBar />
    </div>
  );
}

function TypingIndicator() {
  return (
    <div className="flex items-center gap-1.5 py-1">
      <span className="w-2 h-2 rounded-full dot-1" style={{ background: '#8B90A0' }} />
      <span className="w-2 h-2 rounded-full dot-2" style={{ background: '#8B90A0' }} />
      <span className="w-2 h-2 rounded-full dot-3" style={{ background: '#8B90A0' }} />
    </div>
  );
}