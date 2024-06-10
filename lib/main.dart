import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assets Maker Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedFolder;
  String? outputFolder;
  List<String> assetPaths = [];

  Future<void> _pickFolder() async {
    String? folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath != null) {
      setState(() {
        selectedFolder = folderPath;
      });
      await _loadAssetPaths();
    }
  }

  Future<void> _pickOutputFolder() async {
    String? folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath != null) {
      setState(() {
        outputFolder = folderPath;
      });
    }
  }

  Future<void> _loadAssetPaths() async {
    if (selectedFolder == null) return;

    List<String> paths = await _getAssetPaths(Directory(selectedFolder!));
    setState(() {
      assetPaths = paths;
    });
  }

  Future<void> _generateFile() async {
    if (selectedFolder == null) {
      _showSnackBar('Please select assets folder');
      return;
    }

    if (outputFolder == null) {
      _showSnackBar('Please select output folder');
      return;
    }

    String outputContent = _generateDartContent(assetPaths, selectedFolder!);

    Directory? outputDir;
    if (outputFolder == null) {
      outputDir = await getDownloadsDirectory();
    } else {
      outputDir = Directory(outputFolder!);
    }

    File outputFile = File('${outputDir?.path}/assets.dart');
    await outputFile.writeAsString(outputContent);

    _showSnackBar('Dart file generated successfully');
  }

  Future<List<String>> _getAssetPaths(Directory dir) async {
    List<String> assetPaths = [];
    await for (FileSystemEntity entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        String filePath = entity.path;
        if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg') || filePath.endsWith('.png') || filePath.endsWith('.svg')) {
          assetPaths.add(filePath);
        }
      }
    }
    return assetPaths;
  }

  String _generateDartContent(List<String> assetPaths, String baseFolder) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('class KAssets {');

    for (var path in assetPaths) {
      String relativePath = path.replaceFirst(baseFolder, '').replaceFirst('/', '');
      String fileName = relativePath.split('/').last;
      String variableName = _convertToCamelCase(fileName.split('.').first);
      buffer.writeln('  static const String $variableName = "assets/$relativePath";');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  String _convertToCamelCase(String text) {
    List<String> parts = text.split(RegExp(r'[_\-\s]'));
    String camelCase = parts[0];
    for (int i = 1; i < parts.length; i++) {
      camelCase += parts[i][0].toUpperCase() + parts[i].substring(1);
    }
    return camelCase;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDeveloperInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Assets Maker Flutter'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'The Assets Maker app is a Flutter application designed to assist developers in managing asset files for their projects. It allows users to select an assets folder containing image files (such as JPG, JPEG, PNG, SVG) and an output folder where a Dart file with asset paths will be generated. Additionally, the app provides a preview of the selected assets and allows users to copy the variable names and asset paths for easy integration into their projects.'),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: Text('Develop by: S.m. Kamal Hussain Shahi'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets Maker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDeveloperInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _pickFolder,
              child: const Text('Select Assets Folder'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickOutputFolder,
              child: const Text('Select Output Folder'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateFile,
              child: const Text('Generate Dart File'),
            ),
            const SizedBox(height: 20),
            if (selectedFolder != null) Text('Selected Folder: $selectedFolder'),
            if (outputFolder != null) Text('Output Folder: $outputFolder'),
            const SizedBox(height: 20),
            if (assetPaths.isNotEmpty) _buildGridView(),
          ],
        ),
      ),
    );
  }

  int get _crossAxisCount {
    double screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth > 1200) {
      return 6;
    } else if (screenWidth > 600) {
      return 4;
    } else {
      return 2;
    }
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        crossAxisCount: _crossAxisCount,
      ),
      itemCount: assetPaths.length,
      itemBuilder: (context, index) {
        String path = assetPaths[index];
        return Card(
          child: Stack(
            alignment: Alignment.center,
            children: [
              path.endsWith('.svg') ? SvgPicture.file(File(path)) : Image.file(File(path)),
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    String copyText = "KAssets.${_convertToCamelCase(path.split('/').last.split('.').first)}";
                    Clipboard.setData(ClipboardData(text: copyText));
                    _showSnackBar("Copy text $copyText");
                  },
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    String copyText = "assets/${path.replaceFirst(selectedFolder!, '').replaceFirst('/', '')}";
                    Clipboard.setData(ClipboardData(text: copyText));
                    _showSnackBar("Copy text $copyText");
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
