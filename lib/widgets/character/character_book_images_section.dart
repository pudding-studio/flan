import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../models/character/cover_image.dart';
import '../../utils/character_image_storage.dart';
import '../../utils/common_dialog.dart';
import '../common/common_button.dart';

/// 설정집의 '등장인물' 항목 안에 표시되는 이미지 목록 섹션.
///
/// 각 이미지는 이름 + 썸네일로 구성되고, `<img="{bookName}_{imageName}">`
/// 형식으로 채팅에서 참조된다. [readOnly]가 true면 추가·수정·삭제 UI를
/// 숨기고 썸네일만 보여준다(드로어 뷰).
class CharacterBookImagesSection extends StatefulWidget {
  final List<CoverImage> images;
  final String characterName;
  final VoidCallback? onUpdate;
  final bool readOnly;

  const CharacterBookImagesSection({
    super.key,
    required this.images,
    required this.characterName,
    this.onUpdate,
    this.readOnly = false,
  });

  @override
  State<CharacterBookImagesSection> createState() =>
      _CharacterBookImagesSectionState();
}

class _CharacterBookImagesSectionState
    extends State<CharacterBookImagesSection> {
  static const double _itemHorizontalPadding = 10.0;
  static const double _itemVerticalPadding = 10.0;

  final ImagePicker _imagePicker = ImagePicker();
  final Map<int, TextEditingController> _editControllers = {};
  int? _editingImageId;

  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  @override
  void dispose() {
    for (final controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notifyUpdate() {
    widget.onUpdate?.call();
    setState(() {});
  }

  Future<void> _addImage() async {
    final XFile? picked =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final ext = _extractExt(picked.name);
      final characterName =
          widget.characterName.isNotEmpty ? widget.characterName : 'unknown';

      // 등장인물 이미지 이름 규칙: 첫 번째는 'default', 이후는 '1'부터 순차.
      // `<img="{characterName}_default">`를 기본 표지로 삼기 위한 관례.
      final assignedName = _nextDefaultName();

      final stored = await CharacterImageStorage.saveImageBytes(
        characterName,
        assignedName,
        ext,
        bytes,
      );

      setState(() {
        widget.images.add(CoverImage(
          id: _getNextTempId(),
          characterId: -1,
          name: assignedName,
          order: widget.images.length,
          path: stored.path,
          imageData: stored.bytes,
          imageType: 'characterBook',
          isExpanded: true,
        ));
      });
      _notifyUpdate();
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: AppLocalizations.of(context)
            .additionalImageSaveError(e.toString()),
      );
    }
  }

  /// 다음에 추가될 이미지의 기본 이름을 계산한다.
  /// - 'default'가 없으면 'default'
  /// - 있으면 '1','2',... 중 가장 작은 미사용 숫자
  /// 사용자가 이름을 바꾸거나 중간을 삭제해도 충돌하지 않도록 한다.
  String _nextDefaultName() {
    final usedNames = widget.images.map((e) => e.name).toSet();
    if (!usedNames.contains('default')) return 'default';
    var n = 1;
    while (usedNames.contains(n.toString())) {
      n++;
    }
    return n.toString();
  }

  Future<void> _deleteImage(CoverImage image) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: image.name,
    );
    if (!confirmed) return;

    if (image.path != null) {
      await CharacterImageStorage.deleteImage(image.path!);
    }
    setState(() => widget.images.remove(image));
    _notifyUpdate();
  }

  void _toggleEdit(CoverImage image) {
    if (image.id == null) return;
    setState(() {
      if (_editingImageId == image.id) {
        final controller = _editControllers[image.id!];
        if (controller != null && controller.text.isNotEmpty) {
          image.name = controller.text;
        }
        _editingImageId = null;
        _editControllers.remove(image.id!)?.dispose();
        _notifyUpdate();
      } else {
        _editingImageId = image.id;
        _editControllers[image.id!] = TextEditingController(text: image.name);
      }
    });
  }

  void _saveName(CoverImage image, String value) {
    if (image.id == null) return;
    setState(() {
      if (value.isNotEmpty) image.name = value;
      _editingImageId = null;
      _editControllers.remove(image.id!)?.dispose();
    });
    _notifyUpdate();
  }

  String _extractExt(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < fileName.length - 1) {
      return fileName.substring(dotIndex + 1).toLowerCase();
    }
    return 'jpg';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.images.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.readOnly
                  ? l10n.characterBookImagesEmptyReadOnly
                  : l10n.characterBookImagesEmpty,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ...widget.images.map(_buildImageItem),
        if (!widget.readOnly) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: _addImage,
              icon: Icons.add,
              label: l10n.characterBookImagesAddButton,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageItem(CoverImage image) {
    return Container(
      key: ValueKey('bookImage_${image.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => image.isExpanded = !image.isExpanded),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _itemHorizontalPadding,
                vertical: _itemVerticalPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _editingImageId == image.id
                        ? TextField(
                            controller: _editControllers[image.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _saveName(image, value),
                          )
                        : Text(
                            image.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  if (!widget.readOnly) ...[
                    GestureDetector(
                      onTap: () => _toggleEdit(image),
                      child: Icon(
                        _editingImageId == image.id
                            ? Icons.check
                            : Icons.edit_outlined,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _deleteImage(image),
                      child: const Icon(Icons.delete_outline, size: 18),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    image.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (image.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImagePreview(image),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(CoverImage image) {
    return FutureBuilder<Uint8List?>(
      future: image.resolveImageData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => _errorWidget(),
          );
        }
        return _errorWidget();
      },
    );
  }

  Widget _errorWidget() {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
