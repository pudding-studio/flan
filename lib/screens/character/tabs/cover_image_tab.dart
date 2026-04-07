import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/cover_image.dart';
import '../../../utils/character_image_storage.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_title_medium.dart';

class CoverImageTab extends StatefulWidget {
  final List<CoverImage> coverImages;
  final int? selectedCoverImageId;
  final String characterName;
  final Function(int?) onSelectedCoverImageChanged;
  final VoidCallback onUpdate;

  const CoverImageTab({
    super.key,
    required this.coverImages,
    required this.selectedCoverImageId,
    required this.characterName,
    required this.onSelectedCoverImageChanged,
    required this.onUpdate,
  });

  @override
  State<CoverImageTab> createState() => _CoverImageTabState();
}

class _CoverImageTabState extends State<CoverImageTab> {
  static const double _itemHorizontalPadding = 10.0;
  static const double _itemVerticalPadding = 10.0;

  int? _editingCoverImageId;
  final Map<int, TextEditingController> _editControllers = {};
  final ImagePicker _imagePicker = ImagePicker();

  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  @override
  void dispose() {
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _notifyUpdate() {
    widget.onUpdate();
    setState(() {});
  }

  Future<void> _addCoverImage() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final originalName = _baseNameWithoutExt(picked.name);
      final ext = _extractExt(picked.name);
      final characterName = widget.characterName.isNotEmpty
          ? widget.characterName
          : 'unknown';

      final filePath = await CharacterImageStorage.saveImage(
        characterName,
        originalName,
        ext,
        bytes,
      );

      setState(() {
        final newImage = CoverImage(
          id: _getNextTempId(),
          characterId: -1,
          name: originalName.isNotEmpty
              ? originalName
              : '표지 ${widget.coverImages.length + 1}',
          order: widget.coverImages.length,
          path: filePath,
          isExpanded: true,
        );
        widget.coverImages.add(newImage);
        if (widget.coverImages.length == 1) {
          widget.onSelectedCoverImageChanged(newImage.id);
        }
      });
      _notifyUpdate();
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '이미지 저장 중 오류가 발생했습니다: $e',
      );
    }
  }

  Future<void> _deleteCoverImage(CoverImage coverImage) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: coverImage.name,
    );

    if (confirmed) {
      if (coverImage.path != null) {
        await CharacterImageStorage.deleteImage(coverImage.path!);
      }
      setState(() {
        widget.coverImages.remove(coverImage);
        if (widget.selectedCoverImageId == coverImage.id) {
          widget.onSelectedCoverImageChanged(
            widget.coverImages.isNotEmpty
                ? widget.coverImages.first.id
                : null,
          );
        }
      });
      _notifyUpdate();
    }
  }

  void _toggleCoverImageEdit(CoverImage coverImage) {
    setState(() {
      if (_editingCoverImageId == coverImage.id) {
        final controller = _editControllers[coverImage.id!];
        if (controller != null && controller.text.isNotEmpty) {
          coverImage.name = controller.text;
        }
        _editingCoverImageId = null;
        _editControllers.remove(coverImage.id!)?.dispose();
        _notifyUpdate();
      } else {
        _editingCoverImageId = coverImage.id;
        _editControllers[coverImage.id!] =
            TextEditingController(text: coverImage.name);
      }
    });
  }

  void _saveCoverImageName(CoverImage coverImage, String value) {
    setState(() {
      if (value.isNotEmpty) coverImage.name = value;
      _editingCoverImageId = null;
      _editControllers.remove(coverImage.id!)?.dispose();
    });
    _notifyUpdate();
  }

  String _baseNameWithoutExt(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
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
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: CommonTitleMedium(
              text: '표지',
              helpMessage: '캐릭터의 표지 이미지를 추가할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.coverImages.isEmpty
                ? const Center(child: Text('표지 이미지가 없습니다'))
                : ListView.builder(
                    itemCount: widget.coverImages.length,
                    itemBuilder: (context, index) =>
                        _buildCoverImageItem(widget.coverImages[index]),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: _addCoverImage,
              icon: Icons.add,
              label: '표지 이미지 추가',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageItem(CoverImage coverImage) {
    final displayPath = coverImage.path ?? '';

    return Container(
      key: ValueKey(coverImage.id),
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
                setState(() => coverImage.isExpanded = !coverImage.isExpanded),
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _itemHorizontalPadding,
                vertical: _itemVerticalPadding,
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: coverImage.id!,
                    groupValue: widget.selectedCoverImageId,
                    onChanged: (value) {
                      widget.onSelectedCoverImageChanged(value);
                      setState(() {});
                    },
                    visualDensity:
                        const VisualDensity(horizontal: -4, vertical: -4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _editingCoverImageId == coverImage.id
                            ? TextField(
                                controller: _editControllers[coverImage.id!],
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                autofocus: true,
                                onSubmitted: (value) =>
                                    _saveCoverImageName(coverImage, value),
                              )
                            : Text(
                                coverImage.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                        if (displayPath.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            displayPath,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleCoverImageEdit(coverImage),
                    child: Icon(
                      _editingCoverImageId == coverImage.id
                          ? Icons.check
                          : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deleteCoverImage(coverImage),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    coverImage.isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (coverImage.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImagePreview(coverImage),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview(CoverImage coverImage) {
    return FutureBuilder<Uint8List?>(
      future: coverImage.resolveImageData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(bytes, fit: BoxFit.cover, alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => _imageErrorWidget());
        }
        return _imageErrorWidget();
      },
    );
  }

  Widget _imageErrorWidget() {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
