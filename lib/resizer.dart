import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_resize/image_group.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart' hide Size;

import 'package:image/image.dart' as img;

class Resizer extends StatefulWidget {
  const Resizer({super.key});

  @override
  State<Resizer> createState() => _ResizerState();
}

class _ResizerState extends State<Resizer> {
  final List<ImageGroup> images = [];
  final imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Resize'),
      ),
      body: Center(
        child: Builder(builder: (context) {
          if (images.isEmpty) {
            return const Text('Please pick image to resize');
          }
          return ListView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageGroup = images[index];
                return ImageGroupViewResize(
                  imageGroup: imageGroup,
                  onNewSize: (imageGroup) {
                    setState(() {
                      images[index] = imageGroup;
                    });
                  },
                  onSave: () {
                    images.removeAt(index);
                    setState(() {});
                  },
                );
              });
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final List<XFile> images = await imagePicker.pickMultiImage();
          if (images.isEmpty) {
            return;
          }
          for (var image in images) {
            var size = ImageSizeGetter.getSize(FileInput(File(image.path)));
            final splittedPath = image.path.split('/');
            final x2Path = (List.from(splittedPath)
                  ..insert(splittedPath.length - 1, '2x'))
                .join('/');
            final x3Path = (List.from(splittedPath)
                  ..insert(splittedPath.length - 1, '3x'))
                .join('/');
            if (File(x3Path).existsSync()) {
              size = ImageSizeGetter.getSize(FileInput(File(x3Path)));
            }

            final imageGroup = ImageGroup(
              mainImage1x: image.path,
              originalSize3x:
                  Size(size.width.toDouble(), size.height.toDouble()),
              mainImage2x: File(x2Path).existsSync() ? x2Path : null,
              mainImage3x: File(x3Path).existsSync() ? x3Path : null,
            );
            this.images.add(imageGroup);
            setState(() {});
          }
        },
        tooltip: 'Pick File',
        child: const Icon(Icons.file_copy),
      ),
    );
  }
}

class ImageGroupViewResize extends StatelessWidget {
  const ImageGroupViewResize({
    super.key,
    required this.imageGroup,
    required this.onNewSize,
    required this.onSave,
  });
  final ImageGroup imageGroup;
  final void Function(ImageGroup) onNewSize;
  final void Function() onSave;

  Future<void> _saveImage({
    required BuildContext context,
    required String filePath,
    required double widthFactor,
    required double heightFactor,
  }) async {
    final file = File(filePath);
    final imageSize = ImageSizeGetter.getSize(FileInput(file));
    final size = Size(imageSize.width.toDouble(), imageSize.height.toDouble());
    img.Image? image = await img.decodeWebPFile(filePath);
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Decoding image failed, return null image'),
        ),
      );
      return;
    }
    img.Image resizedImage = img.copyResize(
      image,
      width: (size.width * widthFactor).toInt(),
      height: (size.height * heightFactor).toInt(),
    );

    await img.encodePngFile(filePath.replaceAll('.webp', '.png'), resizedImage);
    // Process.runSync(
    //     'cwebp',
    //     '-q 100 ${filePath.replaceAll('.webp', '.png')} -o $filePath'
    //         .split(' '));
    // File(filePath.replaceAll('.webp', '.png')).deleteSync();
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          imageGroup.mainImage1x,
        ),
        SizedBox(
          height: 300,
          child: Row(
            children: [
              Image.file(
                File(imageGroup.mainImage1x),
              ),
              if (imageGroup.mainImage2x != null)
                Image.file(
                  File(imageGroup.mainImage2x!),
                ),
              if (imageGroup.mainImage3x != null)
                Image.file(File(imageGroup.mainImage3x!))
            ].map((e) => Expanded(child: e)).toList(),
          ),
        ),
        const Text(
          'Sizes for 3x if available',
        ),
        Text(
            'Width: ${imageGroup.originalSize3x.width} - Height: ${imageGroup.originalSize3x.height}'),
        Text(
            'New Width: ${imageGroup.newSize3x?.width.toInt()} - New Height: ${imageGroup.newSize3x?.height.toInt()}'),
        Slider(
          value: imageGroup.newSize3x?.width ?? imageGroup.originalSize3x.width,
          max: imageGroup.originalSize3x.width,
          min: 0,
          onChanged: (value) {
            onNewSize.call(
              imageGroup.copyWith(
                newSize3x: Size(
                  value.toDouble(),
                  imageGroup.originalSize3x.height,
                ),
              ),
            );
          },
        ),
        Slider(
          value:
              imageGroup.newSize3x?.height ?? imageGroup.originalSize3x.height,
          max: imageGroup.originalSize3x.height,
          min: 0,
          onChanged: (value) {
            onNewSize.call(
              imageGroup.copyWith(
                newSize3x: Size(
                  imageGroup.newSize3x?.width ??
                      imageGroup.originalSize3x.width,
                  value.toDouble(),
                ),
              ),
            );
          },
        ),
        ElevatedButton(
          child: const Text('Save Images'),
          onPressed: () async {
            if (imageGroup.newSize3x == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New Size is null'),
                ),
              );
              return;
            }
            await _saveImage(
              context: context,
              filePath: imageGroup.mainImage1x,
              widthFactor:
                  imageGroup.newSize3x!.width / imageGroup.originalSize3x.width,
              heightFactor: imageGroup.newSize3x!.height /
                  imageGroup.originalSize3x.height,
            );
            if (imageGroup.mainImage2x != null) {
              await _saveImage(
                // ignore: use_build_context_synchronously
                context: context,
                filePath: imageGroup.mainImage2x!,
                widthFactor: imageGroup.newSize3x!.width /
                    imageGroup.originalSize3x.width,
                heightFactor: imageGroup.newSize3x!.height /
                    imageGroup.originalSize3x.height,
              );
            }
            if (imageGroup.mainImage3x != null) {
              await _saveImage(
                // ignore: use_build_context_synchronously
                context: context,
                filePath: imageGroup.mainImage3x!,
                widthFactor: imageGroup.newSize3x!.width /
                    imageGroup.originalSize3x.width,
                heightFactor: imageGroup.newSize3x!.height /
                    imageGroup.originalSize3x.height,
              );
            }
            onSave.call();
          },
        ),
      ],
    );
  }
}
