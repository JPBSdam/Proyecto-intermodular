import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// Widget para mostrar avatares de usuario.

class AvatarDisplay extends StatelessWidget {
  final File? localImage;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData placeholderIcon;
  final VoidCallback? onTap;

  const AvatarDisplay({
    super.key,
    this.localImage,
    this.imageUrl,
    this.size = 56,
    this.backgroundColor,
    this.iconColor,
    this.placeholderIcon = Icons.person,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final iconColorValue = iconColor ?? theme.colorScheme.onSurfaceVariant;

    Widget imageContent;
    if (localImage != null) {
      imageContent = ClipOval(
        child: Image.file(
          localImage!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageContent = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: theme.colorScheme.primary.withAlpha(20),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          errorWidget: (_, __, ___) =>
              _buildPlaceholder(background, iconColorValue),
        ),
      );
    } else {
      imageContent = _buildPlaceholder(background, iconColorValue);
    }

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Center(child: imageContent),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildPlaceholder(Color background, Color iconColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(placeholderIcon, color: iconColor, size: size * 0.55),
    );
  }
}
