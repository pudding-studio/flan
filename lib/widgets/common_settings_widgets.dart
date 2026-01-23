import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 공통 AppBar
///
/// 모든 화면에서 일관된 레이아웃과 간격을 제공합니다:
/// - 왼쪽 버튼 (백/클로즈): padding left 16
/// - 버튼-타이틀 간격: 12
/// - 타이틀-오른쪽 버튼 간격: 자동
/// - 오른쪽 버튼-끝 간격: 16
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget; // 커스텀 타이틀 (예: 아바타 + 이름)
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showCloseButton;
  final VoidCallback? onClosePressed; // 닫기 버튼 콜백
  final PreferredSizeWidget? bottom; // TabBar 등을 위한 bottom

  const CommonAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.showCloseButton = false,
    this.onClosePressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          // 왼쪽 버튼 (백 또는 클로즈)
          if (showBackButton || showCloseButton)
            IconButton(
              icon: Icon(showCloseButton ? Icons.close : Icons.arrow_back),
              onPressed: showCloseButton && onClosePressed != null
                  ? onClosePressed
                  : () => Navigator.pop(context),
              padding: const EdgeInsets.only(left: 16),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),

          // 버튼이 있을 때만 간격 추가
          if (showBackButton || showCloseButton)
            const SizedBox(width: 12),

          // 버튼이 없을 때는 왼쪽 여백 추가
          if (!showBackButton && !showCloseButton)
            const SizedBox(width: 16),

          // 타이틀 (커스텀 위젯 또는 텍스트)
          Expanded(
            child: titleWidget ?? Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 오른쪽 액션 버튼들
          if (actions != null) ...actions!,
          const SizedBox(width: 16),
        ],
      ),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// 설정 화면에서 사용하는 정보/도움말 카드
class SettingsInfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const SettingsInfoCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 설정 화면에서 사용하는 Empty State 위젯
class SettingsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const SettingsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.5),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 파라미터 섹션의 인포 배너
class ParameterInfoBanner extends StatelessWidget {
  final String text;

  const ParameterInfoBanner({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// 로그 상세 화면의 정보 행
class LogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const LogInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 로그 상세 화면의 섹션 카드 헤더
class LogSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCopy;
  final bool showFormatToggle;
  final bool formatEnabled;
  final ValueChanged<bool>? onFormatChanged;

  const LogSectionHeader({
    super.key,
    required this.title,
    required this.onCopy,
    this.showFormatToggle = true,
    this.formatEnabled = false,
    this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: onCopy,
          tooltip: '복사',
        ),
        if (showFormatToggle) ...[
          Switch(
            value: formatEnabled,
            onChanged: onFormatChanged,
          ),
          Text('포맷', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// 로그 상세 화면의 코드 블록
class LogCodeBlock extends StatelessWidget {
  final String content;

  const LogCodeBlock({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        content,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}
