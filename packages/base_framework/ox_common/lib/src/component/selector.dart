
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'platform_style.dart';

class CLSelectorItem<T> {
  const CLSelectorItem({
    required this.value,
    required this.label,
  });

  final T value;
  final Widget label;
}

class CLSelector<T extends Object> extends StatelessWidget {
  const CLSelector({
    super.key,
    required this.items,
    required this.selectedValue$,
    this.padding,
    this.backgroundColor,
    this.constraints,
    this.expanded = false,
  });

  final List<CLSelectorItem<T>> items;
  final ValueNotifier<T?> selectedValue$;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BoxConstraints? constraints;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T?>(
      valueListenable: selectedValue$,
      builder: (context, selectedValue, _) {
        Widget selector;
        if (PlatformStyle.isUseMaterial) {
          selector = _buildMaterialSelector(context, selectedValue);
        } else {
          selector = _buildCupertinoSelector(context, selectedValue);
        }

        Widget result = selector;

        if (expanded) {
          result = SizedBox(
            width: double.infinity,
            child: result,
          );
        } else {
          result = IntrinsicWidth(
            child: result,
          );
        }

        if (constraints != null) {
          result = Container(
            constraints: constraints,
            child: result,
          );
        }

        return result;
      },
    );
  }

  Widget _buildCupertinoSelector(BuildContext context, T? selectedValue) {
    final children = {
      for (final item in items) item.value: item.label,
    };
    
    return CupertinoSlidingSegmentedControl<T>(
      children: children,
      groupValue: selectedValue,
      onValueChanged: (T? value) {
        selectedValue$.value = value;
      },
      padding: padding ?? EdgeInsets.symmetric(vertical: 2, horizontal: 3), //_kHorizontalItemPadding,
      backgroundColor: backgroundColor ?? CupertinoColors.tertiarySystemFill,
    );
  }

  Widget _buildMaterialSelector(BuildContext context, T? selectedValue) {
    final segments = items
        .map((item) => ButtonSegment<T>(value: item.value, label: item.label))
        .toList();

    return SegmentedButton<T>(
      segments: segments,
      selected: selectedValue != null ? {selectedValue} : <T>{},
      onSelectionChanged: (Set<T> selected) {
        selectedValue$.value = selected.isNotEmpty ? selected.first : null;
      },
      style: SegmentedButton.styleFrom(
        backgroundColor: backgroundColor,
        padding: padding,
      ),
    );
  }
}

