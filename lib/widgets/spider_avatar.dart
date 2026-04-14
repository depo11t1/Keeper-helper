import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class SpiderAvatar extends StatelessWidget {
  const SpiderAvatar({
    super.key,
    required this.accent,
    this.seed = -1,
    this.label,
    this.size = 68,
    this.photoPath,
  });

  final Color accent;
  final int seed;
  final String? label;
  final double size;
  final String? photoPath;
  static final Map<String, ImageProvider> _imageCache = {};

  static void cachePhoto(String path, List<int> bytes) {
    _imageCache[path] = MemoryImage(Uint8List.fromList(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final hasPreview = seed >= 0;
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    final photoProvider = hasPhoto
        ? _imageCache.putIfAbsent(
            photoPath!,
            () => FileImage(File(photoPath!)),
          )
        : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        color: hasPreview
            ? accent.withValues(alpha: 0.12)
            : accent.withValues(alpha: 0.10),
      ),
      child: Center(
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.26),
                child: Image(
                  image: photoProvider!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.low,
                ),
              )
            : hasPreview
                ? Icon(
                    Icons.photo_size_select_actual_rounded,
                    color: Colors.white.withValues(alpha: 0.88),
                    size: size * 0.38,
                  )
                : Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white.withValues(alpha: 0.82),
                    size: size * 0.40,
                  ),
      ),
    );
  }
}
