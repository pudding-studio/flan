import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/ui_constants.dart';
import '../../../models/character/cover_image.dart';
import '../../../utils/character_image_storage.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_title_medium.dart';

class AdditionalImageTab extends StatefulWidget {
  final List<CoverImage> images;
  final String characterName;
  final VoidCallback onUpdate;

  const AdditionalImageTab({
    super.key,
    required this.images,
    required this.characterName,
    required this.onUpdate,
  });

  @override
  State<AdditionalImageTab> createState() => _AdditionalImageTabState();
}

class _AdditionalImageTabState extends State<AdditionalImageTab> {
  static const double _itemHorizontalPadding = 10.0;
  static const double _itemVerticalPadding = 10.0;

  int? _editingImageId;
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

  Future<void> _addImage() async {
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
              : '이미지 ${widget.images.length + 1}',
          order: widget.images.length,
          path: filePath,
          imageType: 'additional',
          isExpanded: true,
        );
        widget.images.add(newImage);
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

  Future<void> _deleteImage(CoverImage image) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: image.name,
    );

    if (confirmed) {
      if (image.path != null) {
        await CharacterImageStorage.deleteImage(image.path!);
      }
      setState(() {
        widget.images.remove(image);
      });
      _notifyUpdate();
    }
  }

  void _toggleEdit(CoverImage image) {
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
    setState(() {
      if (value.isNotEmpty) image.name = value;
      _editingImageId = null;
      _editControllers.remove(image.id!)?.dispose();
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
              text: '추가 이미지',
              helpMessage: '캐릭터에 관련된 참고 이미지를 추가할 수 있습니다.',
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.images.isEmpty
                ? const Center(child: Text('추가 이미지가 없습니다'))
                : ListView.builder(
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) =>
                        _buildImageItem(widget.images[index]),
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: _addImage,
              icon: Icons.add,
              label: '이미지 추가',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(CoverImage image) {
    final displayPath = image.path ?? '';

    return Container(
      key: ValueKey(image.id),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _editingImageId == image.id
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
    if (image.path != null) {
      return FutureBuilder<Uint8List?>(
        future: CharacterImageStorage.loadImage(image.path!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final bytes = snapshot.data;
          if (bytes != null) {
            return Image.memory(bytes, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _errorWidget());
          }
          return Image.file(
            File(image.path!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _errorWidget(),
          );
        },
      );
    }

    if (image.imageData != null) {
      return Image.memory(image.imageData!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorWidget());
    }

    return _errorWidget();
  }

  Widget _errorWidget() {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}
