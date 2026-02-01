import 'package:flutter/material.dart';
import 'common_custom_text_field.dart';
import 'common_title_medium.dart';

/// 체크박스가 있거나 없는 숫자 입력 파라미터 필드
class CommonParameterTextField extends StatelessWidget {
  /// 필드 라벨
  final String label;

  /// 도움말 텍스트 (? 아이콘 클릭 시 표시)
  final String? helpText;

  /// 텍스트 컨트롤러
  final TextEditingController? controller;

  /// 체크박스 표시 여부
  final bool showCheckbox;

  /// 체크박스 상태 (showCheckbox=true일 때만 유효)
  final bool isChecked;

  /// 체크박스 변경 콜백
  final ValueChanged<bool>? onCheckboxChanged;

  /// 값 변경 콜백
  final ValueChanged<int?>? onChanged;

  /// 힌트 텍스트
  final String hintText;

  const CommonParameterTextField({
    super.key,
    required this.label,
    this.helpText,
    this.controller,
    this.showCheckbox = false,
    this.isChecked = true,
    this.onCheckboxChanged,
    this.onChanged,
    this.hintText = '숫자 입력',
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !showCheckbox || isChecked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CommonCustomTextField.labelHorizontalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showCheckbox) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: (v) => onCheckboxChanged?.call(v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              CommonTitleMedium(
                text: label,
                helpMessage: helpText,
              ),
            ],
          ),
        ),
        const SizedBox(height: CommonCustomTextField.labelBottomSpacing),
        TextFormField(
          controller: controller,
          enabled: isEnabled,
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isEnabled
                    ? null
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CommonCustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: CommonCustomTextField.borderOpacity),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CommonCustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: CommonCustomTextField.borderOpacity),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CommonCustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: CommonCustomTextField.borderOpacity * 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CommonCustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CommonCustomTextField.horizontalPadding,
              vertical: CommonCustomTextField.verticalPadding,
            ),
            isDense: true,
          ),
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          onFieldSubmitted: (text) {
            if (text.isEmpty) {
              onChanged?.call(null);
            } else {
              final newValue = int.tryParse(text);
              if (newValue != null) {
                onChanged?.call(newValue);
              }
            }
          },
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }
}

/// 체크박스가 있는 슬라이더 파라미터 필드
class CommonParameterSlider extends StatelessWidget {
  /// 필드 라벨
  final String label;

  /// 도움말 텍스트
  final String? helpText;

  /// 현재 값 (null이면 비활성화)
  final double? value;

  /// 기본값 (비활성화 상태에서 표시할 값)
  final double defaultValue;

  /// 최소값
  final double min;

  /// 최대값
  final double max;

  /// 슬라이더 구간 수
  final int divisions;

  /// 체크박스 표시 여부
  final bool showCheckbox;

  /// 값 변경 콜백 (null 전달 시 비활성화)
  final ValueChanged<double?> onChanged;

  /// 소수점 자릿수 (기본 2)
  final int decimalPlaces;

  const CommonParameterSlider({
    super.key,
    required this.label,
    this.helpText,
    required this.value,
    required this.defaultValue,
    required this.min,
    required this.max,
    required this.divisions,
    this.showCheckbox = true,
    required this.onChanged,
    this.decimalPlaces = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = value != null;
    final displayValue = value ?? defaultValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CommonCustomTextField.labelHorizontalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showCheckbox) ...[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isEnabled,
                    onChanged: (v) {
                      if (v == true) {
                        onChanged(defaultValue);
                      } else {
                        onChanged(null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              CommonTitleMedium(
                text: label,
                helpMessage: helpText,
              ),
              const Spacer(),
              Text(
                displayValue.toStringAsFixed(decimalPlaces),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CommonCustomTextField.labelBottomSpacing),
        Slider(
          value: displayValue,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: isEnabled ? onChanged : null,
        ),
      ],
    );
  }
}
