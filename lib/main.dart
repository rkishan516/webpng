import 'package:flutter/material.dart';
import 'package:flutter_image_resize/multiple_image_creator.dart';
import 'package:flutter_image_resize/resizer.dart';
import 'package:flutter_image_resize/webp_coverter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WebPng',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final pageController = PageController();
  int selectedIndex = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          elevation: 10,
          destinations: [
            NavigationRailDestination(
              icon: const Icon(Icons.camera),
              label: Text(
                'Resize',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.image),
              label: Text(
                'Webp Converter',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            NavigationRailDestination(
              icon: const Icon(Icons.create_outlined),
              label: Text(
                'Create 1x 2x',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
          labelType: NavigationRailLabelType.all,
          onDestinationSelected: (value) {
            setState(() {
              selectedIndex = value;
            });
            pageController.animateToPage(
              value,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          },
          selectedIndex: selectedIndex,
        ),
        Expanded(
          child: PageView(
            onPageChanged: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
            controller: pageController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              Resizer(),
              WebpConverter(),
              ImageCreator(),
            ],
          ),
        ),
      ],
    );
  }
}
