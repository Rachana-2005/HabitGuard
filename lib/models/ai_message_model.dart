/// Represents a single conversation turn in the AI Wellness Coach
class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isMock;
  final bool isError;
  final String? suggestedAction;

  const AiMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isMock = false,
    this.isError = false,
    this.suggestedAction,
  });

  factory AiMessage.user(String message) {
    return AiMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory AiMessage.assistant(String message, {bool isMock = false}) {
    return AiMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
      isMock: isMock,
    );
  }

  factory AiMessage.error(String message) {
    return AiMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
  }
}
