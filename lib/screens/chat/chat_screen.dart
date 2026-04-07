import 'package:flutter/material.dart';
import '../../mixins/chat_room_pagination_mixin.dart';
import '../../widgets/chat/chat_room_card.dart';
import '../../models/chat/chat_room.dart';
import '../../utils/common_dialog.dart';
import '../../utils/metadata_parser.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_edit_text.dart';
import 'chat_room_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with ChatRoomPaginationMixin {
  bool _isLoading = true;
  bool _isEditMode = false;
  final Set<int> _selectedChatRoomIds = {};
  String _sortMethod = 'date';

  @override
  void initState() {
    super.initState();
    initPagination();
  }

  @override
  void dispose() {
    disposePagination();
    super.dispose();
  }

  @override
  void onChatRoomsLoaded() {
    _sortChatRooms();
    _resolveCoverImages();
  }

  Future<void> _resolveCoverImages() async {
    for (final data in chatRooms) {
      final cover = data.coverImage;
      if (cover != null && cover.imageData == null && cover.path != null) {
        cover.imageData = await cover.resolveImageData();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Future<void> loadChatRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await super.loadChatRooms();
    if (mounted) setState(() => _isLoading = false);
  }

  void _sortChatRooms() {
    switch (_sortMethod) {
      case 'date':
        chatRooms.sort((a, b) => b.chatRoom.updatedAt.compareTo(a.chatRoom.updatedAt));
        break;
      case 'name':
        chatRooms.sort((a, b) => a.chatRoom.name.compareTo(b.chatRoom.name));
        break;
      case 'message_count':
        chatRooms.sort((a, b) => b.messageCount.compareTo(a.messageCount));
        break;
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedChatRoomIds.clear();
      }
    });
  }

  void _toggleChatRoomSelection(int id) {
    setState(() {
      if (_selectedChatRoomIds.contains(id)) {
        _selectedChatRoomIds.remove(id);
      } else {
        _selectedChatRoomIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedChatRooms() async {
    if (_selectedChatRoomIds.isEmpty) return;

    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '채팅방 삭제',
      content: '선택한 ${_selectedChatRoomIds.length}개의 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        for (final id in _selectedChatRoomIds) {
          await paginationDb.deleteChatRoom(id);
        }
        setState(() {
          _selectedChatRoomIds.clear();
          _isEditMode = false;
        });
        loadChatRooms();
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '선택한 채팅방이 삭제되었습니다',
        );
      } catch (e) {
        debugPrint('Error deleting chat rooms: $e');
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '채팅방 삭제 중 오류가 발생했습니다',
        );
      }
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks주 전';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months개월 전';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years년 전';
    }
  }

  Future<void> _showRenameChatRoomDialog(ChatRoom chatRoom) async {
    final controller = TextEditingController(text: chatRoom.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방 이름 수정'),
        content: CommonEditText(
          controller: controller,
          hintText: '채팅방 이름',
          size: CommonEditTextSize.medium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != chatRoom.name) {
      try {
        final updatedChatRoom = chatRoom.copyWith(
          name: result,
        );
        await paginationDb.updateChatRoom(updatedChatRoom);
        loadChatRooms();
      } catch (e) {
        debugPrint('Error renaming chat room: $e');
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '채팅방 이름 수정 중 오류가 발생했습니다',
        );
      }
    }

    controller.dispose();
  }

  Future<void> _showDeleteChatRoomDialog(ChatRoom chatRoom) async {
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '채팅방 삭제',
      content: '\'${chatRoom.name}\' 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await paginationDb.deleteChatRoom(chatRoom.id!);
        loadChatRooms();
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '채팅방이 삭제되었습니다',
        );
      } catch (e) {
        debugPrint('Error deleting chat room: $e');
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '채팅방 삭제 중 오류가 발생했습니다',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditMode
          ? '${_selectedChatRoomIds.length}개 선택됨'
          : '채팅',
        showBackButton: false,
        showCloseButton: _isEditMode,
        onClosePressed: _toggleEditMode,
        actions: [
          if (!_isEditMode)
            CommonAppBarIconButton(
              icon: Icons.edit_outlined,
              onPressed: _toggleEditMode,
              tooltip: '편집',
            ),
          if (_isEditMode)
            CommonAppBarIconButton(
              icon: Icons.delete_outline,
              onPressed: _selectedChatRoomIds.isEmpty ? null : _deleteSelectedChatRooms,
              tooltip: '삭제',
            ),
          if (!_isEditMode)
            CommonAppBarPopupMenuButton<String>(
              tooltip: '더보기',
              onSelected: (String value) {
                if (value == 'date' || value == 'name' || value == 'message_count') {
                  setState(() {
                    _sortMethod = value;
                    _sortChatRooms();
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      '정렬방식',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'date',
                    child: Row(
                      children: [
                        if (_sortMethod == 'date')
                          const Icon(Icons.check, size: 20)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 12),
                        const Text('최근 업데이트순'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'name',
                    child: Row(
                      children: [
                        if (_sortMethod == 'name')
                          const Icon(Icons.check, size: 20)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 12),
                        const Text('이름순'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'message_count',
                    child: Row(
                      children: [
                        if (_sortMethod == 'message_count')
                          const Icon(Icons.check, size: 20)
                        else
                          const SizedBox(width: 20),
                        const SizedBox(width: 12),
                        const Text('메시지 수'),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '채팅방이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '캐릭터를 선택하여 새 채팅을 시작해보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: chatScrollController,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
                  itemCount: chatRooms.length + (hasMoreChats ? 1 : 0),
                  separatorBuilder: (context, index) => const SizedBox(height: 20.0),
                  itemBuilder: (context, index) {
                    if (index >= chatRooms.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final data = chatRooms[index];
                    return GestureDetector(
                      onTap: () async {
                        if (_isEditMode) {
                          _toggleChatRoomSelection(data.chatRoom.id!);
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomScreen(
                                chatRoomId: data.chatRoom.id!,
                              ),
                            ),
                          );
                          loadChatRooms();
                        }
                      },
                      onLongPress: _isEditMode ? null : () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.chatRoom.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.edit_outlined),
                                    title: const Text('채팅방 이름 수정'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showRenameChatRoomDialog(data.chatRoom);
                                    },
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    title: Text(
                                      '삭제',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showDeleteChatRoomDialog(data.chatRoom);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: ChatRoomCard(
                        title: data.chatRoom.name,
                        lastMessage: data.lastMessage != null
                            ? MetadataParser.removeMetadataTags(data.lastMessage!.content)
                            : '메시지가 없습니다',
                        date: _formatDate(data.chatRoom.updatedAt),
                        imageData: data.coverImage?.imageData,
                        messageCount: data.messageCount,
                        tokenCount: data.tokenCount,
                        isEditMode: _isEditMode,
                        isSelected: _selectedChatRoomIds.contains(data.chatRoom.id),
                      ),
                    );
                  },
                ),
    );
  }
}
