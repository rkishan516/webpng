import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class WebpConverter extends StatefulWidget {
  const WebpConverter({super.key});

  @override
  State<WebpConverter> createState() => _WebpConverterState();
}

class _WebpConverterState extends State<WebpConverter> {
  final List<ConvertImageGroup> imagesToConvertToWebp = [];
  final imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            final splittedPath = image.path.split('/');
            final x2Path = (List.from(splittedPath)
                  ..insert(splittedPath.length - 1, '2x'))
                .join('/');
            final x3Path = (List.from(splittedPath)
                  ..insert(splittedPath.length - 1, '3x'))
                .join('/');

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
              tempImage2x:
                  File(x2Path).existsSync() ? '${tempDir.path}/2x.webp' : null,
              tempImage3x:
                  File(x3Path).existsSync() ? '${tempDir.path}/3x.webp' : null,
            );
            imagesToConvertToWebp.add(imageGroup);
            setState(() {});
          }
        },
        tooltip: 'Pick File',
        child: const Icon(Icons.file_copy),
      ),
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
    if (result.endsWith("0" * round)) {
      result = result.substring(0, result.length - round - 1);
    }

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
            }
            if (widget.imageGroup.mainImage3x != null) {
              Process.run(
                'cwebp',
                '-q $value ${widget.imageGroup.mainImage3x} -o ${widget.imageGroup.tempImage3x}'
                    .split(' '),
              ).then((e) {
                setState(() {});
              });
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
