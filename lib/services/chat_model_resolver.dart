import '../models/chat/chat_room.dart';
import '../models/chat/unified_model.dart';
import '../providers/chat_model_provider.dart';
import '../screens/chat/chat_send_errors.dart';

/// Result of a model resolution. The caller may need to know whether
/// the previously-recorded "custom model load failed" id should now be
/// cleared (because the catalog refresh succeeded), so we surface both.
class ChatModelResolution {
  final UnifiedModel model;
  final bool clearCustomLoadFailedFlag;

  const ChatModelResolution({
    required this.model,
    required this.clearCustomLoadFailedFlag,
  });
}

/// Resolves the model to use for the next API call.
///
/// Unlike a simple getter, this verifies that the saved choice
/// (primary, sub, or this chat room's per-room custom model) actually
/// resolves to an available model. If the saved choice is missing it
/// retries once after refreshing the catalog from disk, and only throws
/// if the model is still unavailable.
///
/// Throwing is intentional: it prevents send paths from silently
/// substituting a default (e.g. Google AIS Gemini Pro) when the user's
/// chosen model can't be found. Callers translate the exception's
/// localized message into a user-facing snackbar.
class ChatModelResolver {
  static Future<ChatModelResolution> resolve({
    required ChatModelSettingsProvider provider,
    required ChatRoom? chatRoom,
    required String? customModelLoadFailedId,
    required String Function(String unresolvedId) subModelLoadFailedMessage,
    required String Function(String unresolvedId) primaryModelLoadFailedMessage,
    required String Function(String unresolvedId) customModelLoadFailedMessage,
  }) async {
    switch (chatRoom?.modelPreset) {
      case 'secondary':
        if (provider.hasSubLoadFailed) {
          final ok = await provider.retryLoadSub();
          if (!ok) {
            throw ChatModelLoadException(
              subModelLoadFailedMessage(provider.unresolvedSubModelId ?? '?'),
            );
          }
        }
        return ChatModelResolution(
          model: provider.subModel,
          clearCustomLoadFailedFlag: false,
        );
      case 'custom':
        // Per-room custom model: re-check against the (possibly stale)
        // available models, refreshing the catalog from disk on a miss
        // before giving up.
        final savedId = chatRoom?.selectedModelId ?? customModelLoadFailedId;
        if (savedId != null) {
          var match = provider.availableModels.where((m) => m.id == savedId);
          if (match.isEmpty) {
            await provider.refreshCustomCatalog();
            match = provider.availableModels.where((m) => m.id == savedId);
          }
          if (match.isEmpty) {
            throw ChatModelLoadException(
              customModelLoadFailedMessage(savedId),
            );
          }
          if (provider.selectedModel.id != savedId) {
            await provider.setModel(match.first);
          }
          return ChatModelResolution(
            model: match.first,
            clearCustomLoadFailedFlag: customModelLoadFailedId != null,
          );
        }
        if (provider.hasPrimaryLoadFailed) {
          final ok = await provider.retryLoadPrimary();
          if (!ok) {
            throw ChatModelLoadException(
              primaryModelLoadFailedMessage(
                provider.unresolvedPrimaryModelId ?? '?',
              ),
            );
          }
        }
        return ChatModelResolution(
          model: provider.selectedModel,
          clearCustomLoadFailedFlag: false,
        );
      default: // 'primary'
        if (provider.hasPrimaryLoadFailed) {
          final ok = await provider.retryLoadPrimary();
          if (!ok) {
            throw ChatModelLoadException(
              primaryModelLoadFailedMessage(
                provider.unresolvedPrimaryModelId ?? '?',
              ),
            );
          }
        }
        return ChatModelResolution(
          model: provider.selectedModel,
          clearCustomLoadFailedFlag: false,
        );
    }
  }
}
