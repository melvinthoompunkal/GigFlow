import { Suspense } from 'react';
import ChatScreen from './components/ChatScreen';

export default function ChatPage() {
  return (
    <Suspense fallback={null}>
      <ChatScreen />
    </Suspense>
  );
}