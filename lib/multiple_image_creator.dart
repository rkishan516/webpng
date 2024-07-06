import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart' hide Size;

class ImageCreator extends StatefulWidget {
  const ImageCreator({super.key});

  @override
  State<ImageCreator> createState() => _ImageCreatorState();
}

class _ImageCreatorState extends State<ImageCreator> {
  final List<ImageCreatorGroup> images = [];
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
              return ImageCreatorView(
                imageGroup: imageGroup,
                onSave: () {
                  images.removeAt(index);
                  setState(() {});
                },
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final List<XFile> images = await imagePicker.pickMultiImage();
          if (images.isEmpty) {
            return;
          }
          for (var image in images) {
            final imageGroup = ImageCreatorGroup(mainImage: image.path);
            this.images.add(imageGroup);
          }
          setState(() {});
        },
        tooltip: 'Pick File',
        child: const Icon(Icons.file_copy),
      ),
    );
  }
}

class ImageCreatorView extends StatelessWidget {
  const ImageCreatorView({
    super.key,
    required this.imageGroup,
    required this.onSave,
  });
  final ImageCreatorGroup imageGroup;
  final void Function() onSave;

  Future<void> _saveImage({
    required BuildContext context,
    required String filePath,
    required String outputFilePath,
    required double widthFactor,
    required double heightFactor,
  }) async {
    final file = File(filePath);
    final imageSize = ImageSizeGetter.getSize(FileInput(file));
    final size = Size(imageSize.width.toDouble(), imageSize.height.toDouble());

    final image = await img.decodePngFile(filePath);
    final newImage = img.copyResize(
      image!,
      width: (size.width * widthFactor).toInt(),
      height: (size.height * heightFactor).toInt(),
    );
    final data = img.encodePng(newImage);
    final newFile = File(outputFilePath);
    newFile.writeAsBytesSync(data);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          imageGroup.mainImage,
        ),
        SizedBox(
          height: 300,
          child: Row(
            children: [
              Image.file(
                File(imageGroup.mainImage),
              ),
            ].map((e) => Expanded(child: e)).toList(),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          child: const Text('Save Images'),
          onPressed: () async {
            await _saveImage(
              context: context,
              outputFilePath: imageGroup.mainImage.replaceAll('/3x', ''),
              filePath: imageGroup.mainImage,
              widthFactor: 1 / 3,
              heightFactor: 1 / 3,
            );
            await _saveImage(
              // ignore: use_build_context_synchronously
              context: context,
              filePath: imageGroup.mainImage,
              outputFilePath: imageGroup.mainImage.replaceAll('/3x/', '/2x/'),
              widthFactor: 2 / 3,
              heightFactor: 2 / 3,
            );

            onSave.call();
          },
        ),
      ],
    );
  }
}

class ImageCreatorGroup {
  final String mainImage;

  const ImageCreatorGroup({
    required this.mainImage,
  });
}
