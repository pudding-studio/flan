import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/cover_image.dart';
import '../../../utils/common_dialog.dart';
import '../../../utils/image_processor.dart';
import '../../../widgets/common/common_title_medium.dart';

class CoverImageTab extends StatefulWidget {
  final List<CoverImage> coverImages;
  final int? selectedCoverImageId;
  final Function(int?) onSelectedCoverImageChanged;
  final VoidCallback onUpdate;

  const CoverImageTab({
    super.key,
    required this.coverImages,
    required this.selectedCoverImageId,
    required this.onSelectedCoverImageChanged,
    required this.onUpdate,
  });

  @override
  State<CoverImageTab> createState() => _CoverImageTabState();
}

class _CoverImageTabState extends State<CoverImageTab> {
  static const double _lorebookItemHorizontalPadding = 10.0;
  static const double _lorebookItemVerticalPadding = 10.0;

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
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      try {
        final Uint8List imageData = await ImageProcessor.processToWebp512(image.path);

        setState(() {
          final newCoverImage = CoverImage(
            id: _getNextTempId(),
            characterId: -1, // Will be set when saving
            name: '표지 ${widget.coverImages.length + 1}',
            order: widget.coverImages.length,
            imageData: imageData,
            isExpanded: true,
          );
          widget.coverImages.add(newCoverImage);

          // 첫 번째 표지를 자동으로 선택
          if (widget.coverImages.length == 1) {
            widget.onSelectedCoverImageChanged(newCoverImage.id);
          }
        });
        _notifyUpdate();
      } catch (e) {
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '이미지 처리 중 오류가 발생했습니다: $e',
        );
      }
    }
  }

  Future<void> _deleteCoverImage(CoverImage coverImage) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: coverImage.name,
    );

    if (confirmed) {
      setState(() {
        widget.coverImages.remove(coverImage);

        // 선택된 표지를 삭제한 경우
        if (widget.selectedCoverImageId == coverImage.id) {
          // 첫 번째 표지를 선택하거나, 없으면 null
          widget.onSelectedCoverImageChanged(
            widget.coverImages.isNotEmpty ? widget.coverImages.first.id : null,
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
        _editControllers[coverImage.id!] = TextEditingController(text: coverImage.name);
      }
    });
  }

  void _saveCoverImageName(CoverImage coverImage, String value) {
    setState(() {
      if (value.isNotEmpty) {
        coverImage.name = value;
      }
      _editingCoverImageId = null;
      _editControllers.remove(coverImage.id!)?.dispose();
    });
    _notifyUpdate();
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
            child: CommonTitleMediumWithHelp(
              label: '표지',
              helpMessage: '캐릭터의 표지 이미지를 추가할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.coverImages.isEmpty
                ? const Center(
                    child: Text('표지 이미지가 없습니다'),
                  )
                : ListView.builder(
                    itemCount: widget.coverImages.length,
                    itemBuilder: (context, index) {
                      return _buildCoverImageItem(widget.coverImages[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addCoverImage,
              icon: const Icon(Icons.add),
              label: const Text('표지 이미지 추가'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImageItem(CoverImage coverImage) {
    return Container(
      key: ValueKey(coverImage.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                coverImage.isExpanded = !coverImage.isExpanded;
              });
            },
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _lorebookItemHorizontalPadding,
                vertical: _lorebookItemVerticalPadding,
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: coverImage.id!,
                    groupValue: widget.selectedCoverImageId,
                    onChanged: (int? value) {
                      widget.onSelectedCoverImageChanged(value);
                      setState(() {});
                    },
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _editingCoverImageId == coverImage.id
                        ? TextField(
                            controller: _editControllers[coverImage.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _saveCoverImageName(coverImage, value),
                          )
                        : Text(
                            coverImage.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleCoverImageEdit(coverImage),
                    child: Icon(
                      _editingCoverImageId == coverImage.id ? Icons.check : Icons.edit_outlined,
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
                    coverImage.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (coverImage.isExpanded && coverImage.imageData != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  coverImage.imageData!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.error_outline),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
