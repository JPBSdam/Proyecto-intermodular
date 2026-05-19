import 'dart:io';

import 'package:flutter/material.dart';

class ImageSelectorCard extends StatelessWidget {
  final File? localImage;
  final String? imageUrl;
  final VoidCallback onTap;

  final double height;
  final double borderRadius;

  final String placeholderText;
  final IconData placeholderIcon;

  const ImageSelectorCard({
    super.key,
    required this.onTap,
    this.localImage,
    this.imageUrl,
    this.height = 180,
    this.borderRadius = 20,
    this.placeholderText = 'Añadir foto',
    this.placeholderIcon = Icons.camera_alt_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),

          child: _buildContent(primaryColor, theme),
        ),
      ),
    );
  }

  Widget _buildContent(Color primaryColor, ThemeData theme) {
    // Imagen local
    if (localImage != null) {
      return Image.file(localImage!, fit: BoxFit.cover);
    }

    // Imagen remota
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,

        errorBuilder: (_, __, ___) {
          return _buildPlaceholder(primaryColor, theme);
        },
      );
    }

    // Placeholder
    return _buildPlaceholder(primaryColor, theme);
  }

  Widget _buildPlaceholder(Color primaryColor, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(placeholderIcon, size: 40, color: primaryColor),

        const SizedBox(height: 8),

        Text(
          placeholderText,
          style: theme.textTheme.labelLarge?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
