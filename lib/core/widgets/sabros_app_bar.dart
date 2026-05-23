import 'package:flutter/material.dart';
import 'package:app_restaurante/core/widgets/app_logo_title.dart';

// AppBar reutilizable que muestra la marca "SabrosApp" en todas las pantallas.

class SabrosAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SabrosAppBar({
    super.key,
    this.pageTitle,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = false,
  });

  final String? pageTitle;

  final List<Widget>? actions;

  final Widget? leading;

  final Color? backgroundColor;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPageTitle = pageTitle != null && pageTitle!.isNotEmpty;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: hasPageTitle
          ? Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogoTitle(fontSize: 14, iconSize: 16),
                const SizedBox(height: 2),
                Text(
                  pageTitle!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            )
          : const AppLogoTitle(),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
