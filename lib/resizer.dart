import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_resize/messages/basic.pb.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart' hide Size;

import 'package:path/path.dart' as p;
import 'package:rinf/rinf.dart';

class Resizer extends StatefulWidget {
  const Resizer({super.key});

  @override
  State<Resizer> createState() => _ResizerState();
}

class _ResizerState extends State<Resizer> {
  late StreamSubscription<RustSignal> completionSubscription,
      failureSubscription;
  List<ImageGroup> images = [];
  final imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    completionSubscription =
        ResizeCompletionSignal.rustSignalStream.listen((d) {
      setState(() {
        images = images
            .where(
              (e) => !e.paths.contains(d.message.input),
            )
            .toList();
      });
    });
    failureSubscription = ResizeFailureSignal.rustSignalStream.listen((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.error)),
      );
    });
  }

  @override
  void dispose() {
    completionSubscription.cancel();
    failureSubscription.cancel();
    super.dispose();
  }

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
                );
              });
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final List<XFile> images = await imagePicker.pickMultiImage(limit: 3);
          if (images.isEmpty) {
            return;
          }

          final size = ImageSizeGetter.getSize(
            FileInput(File(images.last.path)),
          );

          final imageGroup = ImageGroup(
            paths: images.map((e) => e.path).toList(),
            originalSize: Size(size.width.toDouble(), size.height.toDouble()),
          );
          setState(() {
            this.images.add(imageGroup);
          });
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
  });
  final ImageGroup imageGroup;
  final void Function(ImageGroup) onNewSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          child: Row(
            children: imageGroup.paths
                .map(
                  (e) => Column(
                    children: [
                      Expanded(child: Image.file(File(e))),
                      Text(p.basename(e))
                    ],
                  ),
                )
                .map(
                  (e) => Expanded(
                    child: Center(child: e),
                  ),
                )
                .toList(),
          ),
        ),
        const Text(
          'Sizes for last choosen image',
        ),
        Text(
            'Width: ${imageGroup.originalSize.width} - Height: ${imageGroup.originalSize.height}'),
        Text(
            'New Width: ${imageGroup.newSize?.width.toInt()} - New Height: ${imageGroup.newSize?.height.toInt()}'),
        Slider(
          value: imageGroup.newSize?.width ?? imageGroup.originalSize.width,
          max: imageGroup.originalSize.width,
          min: 0,
          onChanged: (value) {
            onNewSize.call(
              imageGroup.copyWith(
                newSize: Size(
                  value.toDouble(),
                  imageGroup.newSize?.height ?? imageGroup.originalSize.height,
                ),
              ),
            );
          },
        ),
        Slider(
          value: imageGroup.newSize?.height ?? imageGroup.originalSize.height,
          max: imageGroup.originalSize.height,
          min: 0,
          onChanged: (value) {
            onNewSize.call(
              imageGroup.copyWith(
                newSize: Size(
                  imageGroup.newSize?.width ?? imageGroup.originalSize.width,
                  value.toDouble(),
                ),
              ),
            );
          },
        ),
        ElevatedButton(
          child: const Text('Save Images'),
          onPressed: () async {
            if (imageGroup.newSize == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New Size is null')),
              );
              return;
            }
            ResizeableImages(
              paths: imageGroup.paths,
              widthFactor:
                  imageGroup.newSize!.width / imageGroup.originalSize.width,
              heightFactor:
                  imageGroup.newSize!.height / imageGroup.originalSize.height,
            ).sendSignalToRust();
          },
        ),
      ],
    );
  }
}

class ImageGroup {
  final List<String> paths;

  final Size? newSize;
  final Size originalSize;

  const ImageGroup({
    required this.paths,
    required this.originalSize,
    this.newSize,
  });

  ImageGroup copyWith({
    List<String>? paths,
    Size? newSize,
    Size? originalSize,
  }) {
    return ImageGroup(
      originalSize: originalSize ?? this.originalSize,
      paths: paths ?? this.paths,
      newSize: newSize ?? this.newSize,
    );
  }
}
