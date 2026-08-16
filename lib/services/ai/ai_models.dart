enum AiModel { auto, fast, balanced, reasoning }
class AiUsage { const AiUsage({this.inputTokens=0,this.outputTokens=0}); final int inputTokens; final int outputTokens; int get totalTokens=>inputTokens+outputTokens; }
class AiConversation { const AiConversation({required this.id,required this.title,required this.messages}); final String id; final String title; final List<Map<String,String>> messages; }
