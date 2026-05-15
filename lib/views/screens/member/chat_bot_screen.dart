import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/chat_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/flex_app_bar.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage(ChatController controller) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    controller.sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: Scaffold(
        appBar: FlexAppBar(
          title: context.tr('Fitness Assistant'),
          showBack: true,
          extraActions: [
            Consumer<ChatController>(
              builder: (context, controller, _) => IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: AppColors.sageDark),
                onPressed: () {
                  controller.clearChat();
                },
                tooltip: context.t('Clear chat', 'Effacer la conversation'),
              ),
            ),
          ],
        ),
        body: Consumer<ChatController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                Expanded(
                  child: controller.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(controller),
                ),
                _buildInputField(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.sage.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('Your Fitness Assistant', 'Votre assistant fitness'),
              style: AppTextStyles.modalTitle,
            ),
            const SizedBox(height: 8),
            Text(
              context.t(
                  'I can help you find the perfect activities and create a training schedule tailored to your goals.',
                  'Je peux vous aider à trouver les activités idéales et à créer un planning d’entraînement adapté à vos objectifs.'),
              style: AppTextStyles.sessionMeta,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(context.t(
                    'Suggest activities for me', 'Suggérer des activités')),
                _buildSuggestionChip(context.t('Create a weekly schedule',
                    'Créer un programme hebdomadaire')),
                _buildSuggestionChip(context.t(
                    'What is Pilates?', 'Qu’est-ce que le Pilates ?')),
                _buildSuggestionChip(context.t('Recommend Padel sessions',
                    'Recommander des séances de Padel')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        return ActionChip(
          label: Text(text, style: AppTextStyles.formInput),
          backgroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.sagePale),
          onPressed: () => controller.sendMessage(text),
        );
      },
    );
  }

  Widget _buildMessageList(ChatController controller) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: controller.messages.length + (controller.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (controller.isLoading && index == controller.messages.length) {
          return _buildTypingIndicator();
        }

        final message = controller.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.sageDark : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTextStyles.body.copyWith(
                color: message.isUser ? AppColors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: AppTextStyles.chip.copyWith(
                color: message.isUser
                    ? AppColors.white.withValues(alpha: 0.7)
                    : AppColors.sage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.sage.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputField(ChatController controller) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: AppTextStyles.formInput,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(controller),
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: AppTextStyles.formInput.copyWith(
                  color: AppColors.textLight,
                ),
                filled: true,
                fillColor: AppColors.mint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: controller.isLoading ? null : () => _sendMessage(controller),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: controller.isLoading
                    ? AppColors.sagePale
                    : AppColors.sageDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: controller.isLoading ? AppColors.sage : AppColors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
