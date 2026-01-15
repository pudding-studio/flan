import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

/// 이름 필드가 포함된 확장 가능한 리스트 아이템
///
/// 사용처:
/// - 로어북/페르소나/시작설정/프롬프트 항목
/// - 로어북 폴더/표지 이미지 (인라인 편집 버전)
class EditableExpandableItem extends StatelessWidget {
  /// 아이템 아이콘
  final Widget icon;

  /// 타이틀에 표시될 이름
  final String name;

  /// 확장 여부
  final bool isExpanded;

  /// 확장/축소 토글 콜백
  final VoidCallback onToggleExpanded;

  /// 삭제 버튼 콜백
  final VoidCallback onDelete;

  /// 확장된 영역의 컨텐츠 (이름 필드 제외)
  final Widget content;

  /// 이름 필드 표시 여부 (기본값: true)
  /// false인 경우 인라인 편집 모드
  final bool showNameField;

  /// 이름 변경 콜백 (showNameField가 true일 때 사용)
  final void Function(String)? onNameChanged;

  /// 이름 필드 힌트 텍스트
  final String? nameHint;

  /// 인라인 편집 모드 여부
  final bool isEditing;

  /// 편집 토글 콜백 (인라인 편집 모드일 때 사용)
  final VoidCallback? onToggleEdit;

  /// 인라인 편집 컨트롤러
  final TextEditingController? editController;

  /// 인라인 편집 저장 콜백
  final void Function(String)? onSaveEdit;

  const EditableExpandableItem({
    super.key,
    required this.icon,
    required this.name,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDelete,
    required this.content,
    this.showNameField = true,
    this.onNameChanged,
    this.nameHint,
    this.isEditing = false,
    this.onToggleEdit,
    this.editController,
    this.onSaveEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: UIConstants.opacityMedium),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: UIConstants.opacityLow),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          if (isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: onToggleExpanded,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      child: Container(
        padding: UIConstants.containerPadding,
        child: Row(
          children: [
            icon,
            const SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: _buildTitle(context),
            ),
            if (!showNameField && onToggleEdit != null)
              GestureDetector(
                onTap: onToggleEdit,
                child: Icon(
                  isEditing ? Icons.check : Icons.edit_outlined,
                  size: UIConstants.iconSizeMedium,
                ),
              ),
            if (!showNameField && onToggleEdit != null)
              const SizedBox(width: UIConstants.spacing12),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.delete_outline,
                size: UIConstants.iconSizeMedium,
              ),
            ),
            const SizedBox(width: UIConstants.spacing12),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: UIConstants.iconSizeLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    // 인라인 편집 모드
    if (!showNameField && isEditing && editController != null && onSaveEdit != null) {
      return TextField(
        controller: editController,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        autofocus: true,
        onSubmitted: onSaveEdit,
      );
    }

    // 일반 텍스트
    return Text(
      name,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: showNameField ? null : FontWeight.w600,
          ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showNameField && onNameChanged != null) ...[
            Text(
              '이름',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: name,
              decoration: InputDecoration(
                hintText: nameHint ?? '이름',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
                ),
                contentPadding: UIConstants.textFieldPaddingSmall,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodySmall,
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  onNameChanged!(value.trim());
                }
              },
            ),
            const SizedBox(height: UIConstants.spacing12),
          ],
          content,
        ],
      ),
    );
  }
}
