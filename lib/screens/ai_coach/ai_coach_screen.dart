import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ai_message_model.dart';
import '../../providers/ai_provider.dart';
import '../../providers/risk_provider.dart';
import '../../providers/usage_provider.dart';

/// Dedicated AI Wellness Coach Screen.
/// Interactive contextual chat powered by Generative AI with behavioral context injection.
class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    'Why is my risk high?',
    'How can I reduce my screen time?',
    'What is my most problematic habit?',
    'Create a plan for tomorrow',
    'Explain my weekly trend',
  ];

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

  void _handleSend(String query) {
    if (query.trim().isEmpty) return;

    final usage = Provider.of<UsageProvider>(context, listen: false);
    final risk = Provider.of<RiskProvider>(context, listen: false);
    final ai = Provider.of<AiProvider>(context, listen: false);

    final features = usage.todayFeatures ?? (usage.todayDailyUsage != null
        ? usage.todayFeatures!
        : null);

    final prediction = risk.currentPrediction;

    if (features == null || prediction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for usage statistics to load before consulting the AI Coach.'),
        ),
      );
      return;
    }

    _textController.clear();
    ai.sendMessage(
      userQuery: query,
      features: features,
      prediction: prediction,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ai = Provider.of<AiProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primarySeed.withAlpha(isDark ? 50 : 30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primarySeed, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Wellness Coach', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Personalized behavioral guidance', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear Conversation',
            onPressed: ai.messages.isEmpty ? null : () => ai.clearMessages(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Service Status Banner if Mock Mode or Unconfigured
            if (ai.genAiService.useMockGenAI)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: Colors.amber.shade800,
                child: const Text(
                  'DEVELOPMENT MODE — Using Contextual Mock AI Generator',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              )
            else if (!ai.genAiService.isConfigured)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: isDark ? const Color(0xFF2C1E1E) : Colors.orange.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Gemini API key not configured. Enable Mock Mode in Profile or add GENAI_API_KEY.',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Messages View
            Expanded(
              child: ai.messages.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: ai.messages.length + (ai.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == ai.messages.length && ai.isLoading) {
                          return _buildLoadingBubble(isDark);
                        }
                        final msg = ai.messages[index];
                        return _buildMessageBubble(msg, isDark);
                      },
                    ),
            ),

            // Quick Action Prompt Chips
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickPrompts.length,
                separatorBuilder: (ctx, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    label: Text(prompt, style: const TextStyle(fontSize: 12)),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade50,
                    side: BorderSide(
                      color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                    ),
                    onPressed: ai.isLoading ? null : () => _handleSend(prompt),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ask HabitGuard AI...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: ai.isLoading ? null : _handleSend,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: ai.isLoading ? Colors.grey : AppTheme.primarySeed,
                    ),
                    onPressed: ai.isLoading ? null : () => _handleSend(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primarySeed.withAlpha(isDark ? 40 : 25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined, size: 48, color: AppTheme.primarySeed),
            ),
            const SizedBox(height: 16),
            const Text(
              'HabitGuard AI Wellness Coach',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me about your smartphone habits, risk score factors, or request a personalized plan for tomorrow.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            const Text(
              'Suggested questions:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((p) {
                return OutlinedButton(
                  onPressed: () => _handleSend(p),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(p, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiMessage msg, bool isDark) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primarySeed
              : (msg.isError
                  ? (isDark ? const Color(0xFF3F1D1D) : const Color(0xFFFFECEC))
                  : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100)),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(2),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    msg.isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                    size: 14,
                    color: msg.isError ? Colors.red : AppTheme.primarySeed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    msg.isError ? 'Notice' : (msg.isMock ? 'HabitGuard AI [Mock]' : 'HabitGuard AI'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: msg.isError ? Colors.red : AppTheme.primarySeed,
                    ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 4),
            Text(
              msg.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (msg.isError
                        ? (isDark ? Colors.red.shade200 : Colors.red.shade900)
                        : (isDark ? Colors.white : Colors.black87)),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primarySeed),
            ),
            SizedBox(width: 10),
            Text('Analyzing behavioral data...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
