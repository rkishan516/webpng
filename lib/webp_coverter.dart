import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webpng/messages/all.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rinf/rinf.dart';
import 'package:path/path.dart' as p;

class WebpConverter extends StatefulWidget {
  const WebpConverter({super.key});

  @override
  State<WebpConverter> createState() => _WebpConverterState();
}

class _WebpConverterState extends State<WebpConverter> {
  late StreamSubscription<RustSignal<ConversionCompletionSignal>> subscription;
  final List<ConvertImageGroup> imagesToConvertToWebp = [];
  final imagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
    subscription = ConversionCompletionSignal.rustSignalStream.listen((d) {
      final indexOfConvertGroup = imagesToConvertToWebp
          .indexWhere((e) => e.indexOf(d.message.input) != -1);
      if (indexOfConvertGroup == -1) return;
      final imageIndex =
          imagesToConvertToWebp[indexOfConvertGroup].indexOf(d.message.input);
      imagesToConvertToWebp[indexOfConvertGroup].buffers[imageIndex] =
          Uint8List.fromList(d.message.output);
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

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
          final List<XFile> images = await imagePicker.pickMultiImage(limit: 3);
          if (images.isEmpty) return;

          final imageGroup = ConvertImageGroup(
            paths: images.map((e) => e.path).toList(),
          );
          await imageGroup.load();
          setState(() {
            imagesToConvertToWebp.add(imageGroup);
          });
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
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          child: Row(
            children: widget.imageGroup.buffers.indexed
                .map((e) {
                  return Column(
                    children: [
                      Expanded(child: Image.memory(e.$2)),
                      Text(p.basename(widget.imageGroup.paths[e.$1]))
                    ],
                  );
                })
                .map((e) => Expanded(child: Center(child: e)))
                .toList(),
          ),
        ),
        Slider(
          value: widget.imageGroup.quality.toDouble(),
          max: 100,
          min: 0,
          onChanged: (value) {
            ConvertableImages(
              paths: widget.imageGroup.paths,
              quality: value,
            ).sendSignalToRust();
            widget.onNewQuality
                .call(widget.imageGroup.copyWith(quality: value.toInt()));
          },
        ),
        ElevatedButton(
          child: const Text('Save Images'),
          onPressed: () async {
            widget.imageGroup.save();
            widget.onSave.call();
          },
        ),
      ],
    );
  }
}

class ConvertImageGroup {
  final List<String> paths;
  late List<Uint8List> buffers;

  final int quality;

  ConvertImageGroup({
    required this.paths,
    this.quality = 75,
    this.buffers = const [],
  });

  Future<void> load() async {
    buffers = await Future.wait(paths.map((e) => File(e).readAsBytes()));
  }

  Future<void> save() async {
    if (paths.length != buffers.length) return;
    await Future.wait([
      for (int i = 0; i < paths.length; i++)
        File(paths[i].replaceFirst('.png', '.webp')).writeAsBytes(buffers[i]),
      for (int i = 0; i < paths.length; i++) File(paths[i]).delete(),
    ]);
  }

  int indexOf(String filename) {
    return paths.indexOf(filename);
  }

  ConvertImageGroup copyWith({
    List<String>? paths,
    List<Uint8List>? buffers,
    int? quality,
  }) {
    return ConvertImageGroup(
      paths: paths ?? this.paths,
      buffers: buffers ?? this.buffers,
      quality: quality ?? this.quality,
    );
  }
}
