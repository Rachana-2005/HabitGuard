import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ai_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/usage_provider.dart';
import '../../services/ai_assistant_engine.dart';

/// Intelligent AI Assistant Chatbot Screen powered by on-device rule-based analytics
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickSuggestions = [
    'What is my screen time today?',
    'Which app did I use the most?',
    'What is my risk level?',
    'Which category did I use the most?',
    'Compare today\'s usage with yesterday\'s usage',
    'Give me advice to reduce screen time',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      AiMessage(
        text: "Hello! 👋 I'm your **HabitGuard AI Assistant**.\n\nI can analyze your live screen time, category distribution, app rankings, and addiction risk. Ask me anything or tap one of the suggested questions below!",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
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

  void _handleSendMessage([String? prefilledText]) {
    final text = (prefilledText ?? _textController.text).trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(AiMessage.user(text));
      _isTyping = true;
    });
    _scrollToBottom();

    // Access dynamic providers
    final usageProvider = Provider.of<UsageProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Rule-based intelligent answer generation (0 external APIs)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final responseText = AiAssistantEngine.generateResponse(
        query: text,
        usageProvider: usageProvider,
        historyProvider: historyProvider,
        user: authProvider.user,
      );

      setState(() {
        _isTyping = false;
        _messages.add(AiMessage.assistant(responseText));
      });
      _scrollToBottom();
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear all chat messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  AiMessage.assistant(
                    "Conversation cleared. How can I assist you with your digital habits today?",
                  ),
                );
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primarySeed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppTheme.primarySeed,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live Analytics • Ready',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear Chat',
            onPressed: _messages.length > 1 ? _clearChat : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isTyping) {
                          return _buildTypingIndicator(isDark);
                        }
                        final message = _messages[index];
                        return _buildMessageBubble(message, isDark);
                      },
                    ),
            ),

            // Quick Suggestions Carousel
            _buildQuickSuggestions(isDark),

            // Text Input Field Area
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: isDark ? Colors.blueGrey.shade700 : Colors.blueGrey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Ask anything about your screen habits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage message, bool isDark) {
    final isUser = message.isUser;
    final timeStr = "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primarySeed
                        : isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                            width: 0.8,
                          ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.blueGrey.shade500 : Colors.blueGrey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.blueGrey.shade300 : AppTheme.primarySeed,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Analyzing live usage...',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions(bool isDark) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSuggestions.length,
        separatorBuilder: (ctx, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _quickSuggestions[index];
          return ActionChip(
            label: Text(
              suggestion,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade800,
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade50,
            side: BorderSide(
              color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _handleSendMessage(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Text Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.blueGrey.shade700 : Colors.blueGrey.shade200,
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask about your screen time or habits...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          Material(
            color: AppTheme.primarySeed,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleSendMessage,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
