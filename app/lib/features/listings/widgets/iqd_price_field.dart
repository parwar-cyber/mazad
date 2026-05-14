import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mazad/core/design/tokens.dart';
import 'package:mazad/core/design/typography.dart';

/// Integer-only IQD price input.  Enforces the money-handling skill at the
/// UI boundary: the user can only enter digits.  Display is plain (no
/// thousands-separator while editing — that would conflict with raw
/// keystrokes); presentation uses [formatIQD] elsewhere.
class IqdPriceField extends StatelessWidget {
  const IqdPriceField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.maxIqd,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? errorText;

  /// If non-null, the inner formatter rejects inputs above this ceiling.
  /// Use 10,000 for Group Bazaar.  Server re-validates regardless.
  final int? maxIqd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      initialValue: value == 0 ? '' : value.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        if (maxIqd != null) _MaxIntFormatter(maxIqd!),
        LengthLimitingTextInputFormatter(12),
      ],
      style: tabularNumeric(theme.textTheme.bodyLarge!),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MazadTokens.radiusSm),
        ),
      ),
      onChanged: (raw) {
        final v = int.tryParse(raw) ?? 0;
        onChanged(v);
      },
    );
  }
}

class _MaxIntFormatter extends TextInputFormatter {
  _MaxIntFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final v = int.tryParse(newValue.text);
    if (v == null || v > max) return oldValue;
    return newValue;
  }
}
