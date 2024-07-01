import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart' hide Size;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Image Resize',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Image Resize'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final pageController = PageController();
  final imagePicker = ImagePicker();
  final List<ImageGroup> images = [];
  final List<ConvertImageGroup> imagesToConvertToWebp = [];
  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: pageController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Scaffold(
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
        ),
        Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Convert to Webp'),
          ),
          body: Center(
            child: Builder(builder: (context) {
              if (imagesToConvertToWebp.isEmpty) {
                return const Text('Please pick image to convert to webp');
              }
              return ListView.builder(
                itemCount: imagesToConvertToWebp.length,
                itemBuilder: (context, index) {
                  final imageGroup = imagesToConvertToWebp[index];
                  return ImageGroupViewConvertToWebp(
                    imageGroup: imageGroup,
                    onNewQuality: (imageGroup) {
                      setState(() {
                        imagesToConvertToWebp[index] = imageGroup;
                      });
                    },
                    onSave: () {
                      imagesToConvertToWebp.removeAt(index);
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

                final Directory tempDir = await getTemporaryDirectory();
                await image.saveTo('${tempDir.path}/1x.webp');
                if (File(x2Path).existsSync()) {
                  Process.runSync(
                    'cwebp',
                    '-q 75 $x2Path -o ${tempDir.path}/2x.webp'.split(' '),
                  );
                }

                if (File(x3Path).existsSync()) {
                  Process.runSync(
                    'cwebp',
                    '-q 75 $x3Path -o ${tempDir.path}/3x.webp'.split(' '),
                  );
                }

                final imageGroup = ConvertImageGroup(
                  mainImage1x: image.path,
                  mainImage2x: File(x2Path).existsSync() ? x2Path : null,
                  mainImage3x: File(x3Path).existsSync() ? x3Path : null,
                  tempImage1x: '${tempDir.path}/1x.webp',
                  tempImage2x: File(x2Path).existsSync()
                      ? '${tempDir.path}/2x.webp'
                      : null,
                  tempImage3x: File(x3Path).existsSync()
                      ? '${tempDir.path}/3x.webp'
                      : null,
                );
                imagesToConvertToWebp.add(imageGroup);
                setState(() {});
              }
            },
            tooltip: 'Pick File',
            child: const Icon(Icons.file_copy),
          ),
        ),
      ],
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

class ImageGroup {
  final String mainImage1x;
  final String? mainImage2x;
  final String? mainImage3x;

  final Size? newSize3x;
  final Size originalSize3x;

  const ImageGroup({
    required this.mainImage1x,
    required this.originalSize3x,
    this.mainImage2x,
    this.mainImage3x,
    this.newSize3x,
  });

  ImageGroup copyWith({
    String? mainImage1x,
    String? mainImage2x,
    String? mainImage3x,
    Size? newSize3x,
    Size? originalSize3x,
  }) {
    return ImageGroup(
      mainImage1x: mainImage1x ?? this.mainImage1x,
      mainImage2x: mainImage2x ?? this.mainImage2x,
      mainImage3x: mainImage3x ?? this.mainImage3x,
      newSize3x: newSize3x ?? this.newSize3x,
      originalSize3x: originalSize3x ?? this.originalSize3x,
    );
  }
}

extension FileSizeExtensions on num {
  /// method returns a human readable string representing a file size
  /// size can be passed as number or as string
  /// the optional parameter 'round' specifies the number of numbers after comma/point (default is 2)
  /// the optional boolean parameter 'useBase1024' specifies if we should count in 1024's (true) or 1000's (false). e.g. 1KB = 1024B (default is true)
  String toHumanReadableFileSize({int round = 2, bool useBase1024 = true}) {
    const List<String> affixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

    num divider = useBase1024 ? 1024 : 1000;

    num size = this;
    num runningDivider = divider;
    num runningPreviousDivider = 0;
    int affix = 0;

    while (size >= runningDivider && affix < affixes.length - 1) {
      runningPreviousDivider = runningDivider;
      runningDivider *= divider;
      affix++;
    }

    String result =
        (runningPreviousDivider == 0 ? size : size / runningPreviousDivider)
            .toStringAsFixed(round);

    //Check if the result ends with .00000 (depending on how many decimals) and remove it if found.
    if (result.endsWith("0" * round))
      result = result.substring(0, result.length - round - 1);

    return "$result ${affixes[affix]}";
  }
}

class ImageGroupViewConvertToWebp extends StatefulWidget {
  const ImageGroupViewConvertToWebp({
    super.key,
    required this.imageGroup,
    required this.onNewQuality,
    required this.onSave,
  });
  final ConvertImageGroup imageGroup;
  final void Function() onSave;
  final void Function(ConvertImageGroup) onNewQuality;

  @override
  State<ImageGroupViewConvertToWebp> createState() =>
      _ImageGroupViewConvertToWebpState();
}

class _ImageGroupViewConvertToWebpState
    extends State<ImageGroupViewConvertToWebp> {
  void _saveImage({
    required BuildContext context,
    required String filePath,
    required double qualtiy,
  }) {
    Process.runSync(
        'cwebp',
        '-q $qualtiy $filePath -o ${filePath.replaceAll('.png', '.webp')}'
            .split(' '));
    File(filePath).deleteSync();
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.imageGroup.mainImage1x,
        ),
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Image.file(
                File(widget.imageGroup.mainImage1x),
              ),
              if (widget.imageGroup.mainImage2x != null)
                Image.file(
                  File(widget.imageGroup.mainImage2x!),
                ),
              if (widget.imageGroup.mainImage3x != null)
                Image.file(File(widget.imageGroup.mainImage3x!))
            ].map((e) => Expanded(child: Center(child: e))).toList(),
          ),
        ),
        Row(
          children: [
            Text(
                'Size 1x : ${File(widget.imageGroup.tempImage1x).lengthSync().toHumanReadableFileSize()}'),
            if (widget.imageGroup.tempImage2x != null)
              Text(
                  'Size 2x : ${File(widget.imageGroup.tempImage2x!).lengthSync().toHumanReadableFileSize()}'),
            if (widget.imageGroup.tempImage3x != null)
              Text(
                  'Size 3x : ${File(widget.imageGroup.tempImage3x!).lengthSync().toHumanReadableFileSize()}')
          ].map((e) => Expanded(child: Center(child: e))).toList(),
        ),
        Slider(
          value: widget.imageGroup.quality.toDouble(),
          max: 100,
          min: 0,
          onChanged: (value) {
            Process.run(
              'cwebp',
              '-q $value ${widget.imageGroup.mainImage1x} -o ${widget.imageGroup.tempImage1x}'
                  .split(' '),
            ).then((e) {
              setState(() {});
            });
            if (widget.imageGroup.mainImage2x != null) {
              Process.run(
                'cwebp',
                '-q $value ${widget.imageGroup.mainImage2x} -o ${widget.imageGroup.tempImage2x}'
                    .split(' '),
              ).then((e) {
                setState(() {});
              });
              ;
            }
            if (widget.imageGroup.mainImage3x != null) {
              Process.run(
                'cwebp',
                '-q $value ${widget.imageGroup.mainImage3x} -o ${widget.imageGroup.tempImage3x}'
                    .split(' '),
              ).then((e) {
                setState(() {});
              });
              ;
            }
            widget.onNewQuality
                .call(widget.imageGroup.copyWith(quality: value.toInt()));
          },
        ),
        ElevatedButton(
          child: const Text('Save Images'),
          onPressed: () async {
            _saveImage(
              context: context,
              filePath: widget.imageGroup.mainImage1x,
              qualtiy: widget.imageGroup.quality.toDouble(),
            );
            if (widget.imageGroup.mainImage2x != null) {
              _saveImage(
                context: context,
                filePath: widget.imageGroup.mainImage2x!,
                qualtiy: widget.imageGroup.quality.toDouble(),
              );
            }
            if (widget.imageGroup.mainImage3x != null) {
              _saveImage(
                context: context,
                filePath: widget.imageGroup.mainImage3x!,
                qualtiy: widget.imageGroup.quality.toDouble(),
              );
            }
            widget.onSave.call();
          },
        ),
      ],
    );
  }
}

class ConvertImageGroup {
  final String mainImage1x;
  final String? mainImage2x;
  final String? mainImage3x;

  final String tempImage1x;
  final String? tempImage2x;
  final String? tempImage3x;

  final int quality;

  const ConvertImageGroup({
    required this.mainImage1x,
    this.mainImage2x,
    this.mainImage3x,
    this.quality = 75,
    required this.tempImage1x,
    this.tempImage2x,
    this.tempImage3x,
  });

  ConvertImageGroup copyWith({
    String? mainImage1x,
    String? mainImage2x,
    String? mainImage3x,
    String? tempImage1x,
    String? tempImage2x,
    String? tempImage3x,
    int? quality,
  }) {
    return ConvertImageGroup(
      mainImage1x: mainImage1x ?? this.mainImage1x,
      mainImage2x: mainImage2x ?? this.mainImage2x,
      mainImage3x: mainImage3x ?? this.mainImage3x,
      tempImage1x: tempImage1x ?? this.tempImage1x,
      tempImage2x: tempImage2x ?? this.tempImage2x,
      tempImage3x: tempImage3x ?? this.tempImage3x,
      quality: quality ?? this.quality,
    );
  }
}
