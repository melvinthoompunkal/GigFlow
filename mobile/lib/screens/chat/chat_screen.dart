import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/claude_api.dart';
import '../../widgets/app_tab_bar.dart';

class _Message {
  final String id;
  final bool isUser;
  String content;
  final DateTime timestamp;
  _Message({required this.id, required this.isUser, required this.content, required this.timestamp});
}

const _suggestedPrompts = [
  'What is my biggest deduction opportunity?',
  'How do I pay quarterly taxes?',
  'Can I deduct my car payment?',
  'What records should I keep?',
  'Explain the QBI deduction',
  'How much should I save each week?',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <_Message>[
    _Message(
      id: 'welcome',
      isUser: false,
      content: "Hey! I'm GigFlow AI 👋 I've analyzed your gig work profile and I'm here to help you navigate taxes, maximize deductions, and build better financial habits. What would you like to know?",
      timestamp: DateTime.now(),
    ),
  ];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isStreaming = false;
  String? _streamingId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? text]) async {
    final messageText = (text ?? _controller.text).trim();
    if (messageText.isEmpty || _isStreaming) return;

    final provider = context.read<UserProfileProvider>();
    if (!provider.profile.isOnboarded && !provider.profile.isDemoMode) {
      provider.activateDemoMode();
    }

    final userMsg = _Message(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      content: messageText,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _controller.clear();
      _isStreaming = true;
    });
    _scrollToBottom();

    final assistantId = 'assistant-${DateTime.now().millisecondsSinceEpoch}';
    final assistantMsg = _Message(id: assistantId, isUser: false, content: '', timestamp: DateTime.now());
    setState(() {
      _messages.add(assistantMsg);
      _streamingId = assistantId;
    });

    final history = _messages
        .where((m) => m.id != assistantId)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.content})
        .toList();

    try {
      await for (final chunk in streamChatMessage(history, provider.profile)) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == assistantId);
          if (idx >= 0) _messages[idx].content += chunk;
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() { _isStreaming = false; _streamingId = null; });
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F12),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2A2D35)))),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/income-dashboard'),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A1D23), border: Border.all(color: const Color(0xFF2A2D35))),
                        child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF8B90A0), size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
                      ),
                      child: const Center(child: Text('💰', style: TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GigFlow AI', style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14, fontWeight: FontWeight.w600)),
                        Row(children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Online', style: GoogleFonts.dmSans(color: const Color(0xFF00E676), fontSize: 12)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _messages.length + (_messages.length == 1 ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return _buildSuggestedPrompts();
                }
                final msg = _messages[i];
                return _buildMessage(msg);
              },
            ),
          ),

          // Input bar
          Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2A2D35)))),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1D23),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A2D35)),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.dmSans(color: const Color(0xFFF0F2F5), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Ask about taxes, deductions, savings...',
                            hintStyle: GoogleFonts.dmSans(color: const Color(0xFF4A4F5C), fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (_, value, __) {
                        final hasText = value.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: hasText && !_isStreaming ? _sendMessage : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              gradient: hasText && !_isStreaming
                                  ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)])
                                  : null,
                              color: hasText && !_isStreaming ? null : const Color(0xFF2A2D35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.send_rounded,
                              color: hasText && !_isStreaming ? const Color(0xFF0D0F12) : const Color(0xFF4A4F5C),
                              size: 18),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          const AppTabBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(_Message msg) {
    final isStreaming = msg.id == _streamingId && _isStreaming;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
              ),
              child: const Center(child: Text('💰', style: TextStyle(fontSize: 12))),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: msg.isUser ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]) : null,
                    color: msg.isUser ? null : const Color(0xFF1A1D23),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: msg.isUser ? null : Border.all(color: const Color(0xFF2A2D35)),
                  ),
                  child: msg.content.isEmpty && isStreaming
                      ? _TypingIndicator()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(child: Text(
                              msg.content,
                              style: GoogleFonts.dmSans(
                                color: msg.isUser ? const Color(0xFF0D0F12) : const Color(0xFFF0F2F5),
                                fontSize: 14, height: 1.5,
                              ),
                            )),
                            if (isStreaming && msg.content.isNotEmpty) ...[
                              const SizedBox(width: 2),
                              Container(
                                width: 2, height: 14,
                                color: const Color(0xFF00E676),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(_formatTime(msg.timestamp), style: GoogleFonts.dmSans(color: const Color(0xFF4A4F5C), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested questions:', style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _suggestedPrompts.map((prompt) => GestureDetector(
              onTap: () => _sendMessage(prompt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D23),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2D35)),
                ),
                child: Text(prompt, style: GoogleFonts.dmSans(color: const Color(0xFF8B90A0), fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    ));
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Opacity(
            opacity: 0.3 + _controllers[i].value * 0.7,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFF8B90A0), shape: BoxShape.circle),
            ),
          ),
        ),
      )),
    );
  }
}
