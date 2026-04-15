import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/prompt/prompt_parameters.dart';
import 'common_parameter_field.dart';

/// Shared editor for the common AI model parameters (sliders + maxOutputTokens).
/// Used by both PromptEditScreen and AutoSummaryScreen.
class PromptParametersEditor extends StatelessWidget {
  final PromptParameters parameters;
  final ValueChanged<PromptParameters> onChanged;
  final TextEditingController? maxOutputTokensController;

  const PromptParametersEditor({
    super.key,
    required this.parameters,
    required this.onChanged,
    this.maxOutputTokensController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (maxOutputTokensController != null) ...[
          CommonParameterTextField(
            label: l10n.autoSummaryMaxResponseSize,
            helpText: l10n.autoSummaryMaxResponseHelp,
            controller: maxOutputTokensController!,
            onChanged: (value) {
              onChanged(parameters.copyWith(maxOutputTokens: value));
            },
          ),
          const SizedBox(height: UIConstants.spacing20),
        ],
        CommonParameterSlider(
          label: l10n.autoSummaryTemperature,
          value: parameters.temperature,
          defaultValue: 1.0,
          min: 0.0,
          max: 2.0,
          divisions: 40,
          helpText: l10n.autoSummaryTemperatureHelp,
          onChanged: (value) {
            onChanged(parameters.copyWith(temperature: value));
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: 'Top P',
          value: parameters.topP,
          defaultValue: 0.95,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          helpText: l10n.autoSummaryTopPHelp,
          onChanged: (value) {
            onChanged(parameters.copyWith(topP: value));
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: 'Top K',
          value: parameters.topK?.toDouble(),
          defaultValue: 40.0,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          decimalPlaces: 0,
          helpText: l10n.autoSummaryTopKHelp,
          onChanged: (value) {
            onChanged(parameters.copyWith(topK: value?.round()));
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: l10n.autoSummaryPresencePenalty,
          value: parameters.presencePenalty,
          defaultValue: 0.0,
          min: -2.0,
          max: 2.0,
          divisions: 80,
          helpText: l10n.autoSummaryPresencePenaltyHelp,
          onChanged: (value) {
            onChanged(parameters.copyWith(presencePenalty: value));
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: l10n.autoSummaryFrequencyPenalty,
          value: parameters.frequencyPenalty,
          defaultValue: 0.0,
          min: -2.0,
          max: 2.0,
          divisions: 80,
          helpText: l10n.autoSummaryFrequencyPenaltyHelp,
          onChanged: (value) {
            onChanged(parameters.copyWith(frequencyPenalty: value));
          },
        ),
      ],
    );
  }
}
