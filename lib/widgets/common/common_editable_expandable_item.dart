import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import 'common_edit_text.dart';

/// 이름 필드가 포함된 확장 가능한 리스트 아이템
///
/// 사용처:
/// - 로어북/페르소나/시작설정/프롬프트 항목
/// - 로어북 폴더/표지 이미지 (인라인 편집 버전)
class CommonEditableExpandableItem extends StatefulWidget {
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

  /// 삭제 버튼 표시 여부
  final bool showDeleteButton;

  const CommonEditableExpandableItem({
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
    this.showDeleteButton = true,
  });

  @override
  State<CommonEditableExpandableItem> createState() => _CommonEditableExpandableItemState();
}

class _CommonEditableExpandableItemState extends State<CommonEditableExpandableItem> {
  TextEditingController? _nameController;

  @override
  void initState() {
    super.initState();
    if (widget.showNameField && widget.onNameChanged != null) {
      _nameController = TextEditingController(text: widget.name);
    }
  }

  @override
  void didUpdateWidget(CommonEditableExpandableItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_nameController != null && widget.name != oldWidget.name && widget.name != _nameController!.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nameController!.text = widget.name;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController?.dispose();
    super.dispose();
  }

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
          if (widget.isExpanded) ...[
            const Divider(height: 1),
            _buildExpandedContent(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: widget.onToggleExpanded,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
      child: Container(
        padding: UIConstants.containerPadding,
        child: Row(
          children: [
            widget.icon,
            const SizedBox(width: UIConstants.spacing12),
            Expanded(
              child: _buildTitle(context),
            ),
            if (!widget.showNameField && widget.onToggleEdit != null)
              GestureDetector(
                onTap: widget.onToggleEdit,
                child: Icon(
                  widget.isEditing ? Icons.check : Icons.edit_outlined,
                  size: UIConstants.iconSizeMedium,
                ),
              ),
            if (!widget.showNameField && widget.onToggleEdit != null)
              const SizedBox(width: UIConstants.spacing12),
            if (widget.showDeleteButton) ...[
              GestureDetector(
                onTap: widget.onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  size: UIConstants.iconSizeMedium,
                ),
              ),
              const SizedBox(width: UIConstants.spacing12),
            ],
            Icon(
              widget.isExpanded ? Icons.expand_less : Icons.expand_more,
              size: UIConstants.iconSizeLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    // 인라인 편집 모드
    if (!widget.showNameField && widget.isEditing && widget.editController != null && widget.onSaveEdit != null) {
      return TextField(
        controller: widget.editController,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        autofocus: true,
        onSubmitted: widget.onSaveEdit,
      );
    }

    // 일반 텍스트
    return Text(
      widget.name,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: widget.showNameField ? null : FontWeight.w600,
          ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showNameField && widget.onNameChanged != null && _nameController != null) ...[
            Text(
              '이름',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            CommonEditText(
              hintText: widget.nameHint ?? '이름',
              size: CommonEditTextSize.small,
              controller: _nameController,
              onFocusLost: (value) {
                if (value.trim().isNotEmpty) {
                  widget.onNameChanged!(value.trim());
                }
              },
            ),
            const SizedBox(height: UIConstants.spacing12),
          ],
          widget.content,
        ],
      ),
    );
  }
}
