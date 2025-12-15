import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Unified dropdown field widget for consistent styling across the app
class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.hint = 'Select an option',
    this.enabled = true,
    this.prefixIcon,
    this.isFormField = true,
    this.onTap,
  });

  final String? label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final T? value;
  final String? Function(T?)? validator;
  final String hint;
  final bool enabled;
  final Widget? prefixIcon;
  final bool isFormField;
  final VoidCallback? onTap;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _showDropdownMenu() {
    if (!widget.enabled) return;

    // If custom onTap is provided (for date picker), use it instead
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height - 1,
        offset.dx,
        offset.dy + size.height + 300,
      ),
      items: widget.items
          .map((item) => PopupMenuItem<T>(value: item.value, child: item.child))
          .toList(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      elevation: 8,
      constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
    ).then((value) {
      if (value != null) {
        widget.onChanged(value);
      }
    });
  }

  InputDecoration _getDecoration(bool hasError) {
    return InputDecoration(
      filled: true,
      fillColor: widget.enabled ? Colors.white : Colors.grey[100],
      prefixIcon: widget.prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: widget.prefixIcon,
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: const Padding(
        padding: EdgeInsets.only(right: 12),
        child: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      ),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.grey[300]!,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.grey[300]!,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? Colors.red : AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: null,
      errorStyle: const TextStyle(height: 0),
    );
  }

  String _getDisplayValue() {
    
    if (widget.value != null) {
      
      if (widget.items.isEmpty) {
        return widget.value.toString();
      }
      
      
      for (var item in widget.items) {
        if (item.value == widget.value) {
          if (item.child is Text) {
            return (item.child as Text).data ?? widget.hint;
          }
        }
      }
      return widget.value.toString();
    }

    
    if (!widget.enabled) {
      if (widget.hint.contains('state')) {
        return 'Select country first';
      } else if (widget.hint.contains('city')) {
        return 'Select state first';
      }
    }
    
  
    return widget.hint;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFormField) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C7278),
              ),
            ),
            const SizedBox(height: 8),
          ],
          FormField<T>(
            key: ValueKey('dropdown_${widget.hint}_${widget.enabled}_${widget.value}'),
            initialValue: widget.value,
            validator: widget.validator,
            builder: (FormFieldState<T> state) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (state.value != widget.value) {
                  state.didChange(widget.value);
                }
              });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MouseRegion(
                    cursor: widget.enabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.forbidden,
                    child: GestureDetector(
                      onTap: widget.enabled
                          ? () {
                              _showDropdownMenu();
                            }
                          : null,
                      child: InputDecorator(
                        isFocused: false,
                        isEmpty: widget.value == null,
                        decoration: _getDecoration(state.hasError),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _getDisplayValue(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: widget.value != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Show error message if validation fails
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        state.errorText ?? 'This field is required',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
    } else {
      // Non-form field version
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C7278),
              ),
            ),
            const SizedBox(height: 8),
          ],
          MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: widget.enabled ? _showDropdownMenu : null,
              child: InputDecorator(
                isFocused: false,
                isEmpty: widget.value == null,
                decoration: _getDecoration(false),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _getDisplayValue(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.value != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
