import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:haticare/core/theme/app_colors.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, required this.title, required this.onBackPressed});

  final String title;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        InkWell(
          onTap: onBackPressed,
          borderRadius: BorderRadius.circular(18),
          child: SvgPicture.asset(
            'assets/icons/back_left_arrow_icon.svg',
            height: 30,
            width: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
