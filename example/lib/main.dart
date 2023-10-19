import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:save_in_cloud/save_in_cloud.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map content = {
    "Map": {},
    "String": "string",
    "int": 0,
    "bool": true,
    "List": []
  };
  Map newContent = {
    "Map": {},
    "String": "string",
    "int": 0,
    "bool": true,
    "List": ["updated"]
  };
  String filename = "file";
  String folderName = "Folder";
  String description = "This is a description of the folder";
  String apiKey = "YOUR_API_KEY"; // todo: insert the API key here

  /// Sign in Google with scope: https://www.googleapis.com/auth/drive.file
  /// For more information: https://developers.google.com/identity/protocols/oauth2/scopes?hl=en#drive
  void _signIn() async => await GoogleDriveWrite.signIn();

  /// Sign out
  void _signOut() async => await GoogleDriveWrite.signOut();

  /// Create a JSON file
  void _createJsonFile() async => await GoogleDriveWrite.createJsonFile(
      filename: filename, content: content);

  /// Create a folder without description
  void _createFolder() async =>
      await GoogleDriveWrite.createFolder(folderName: folderName);

  /// Create a folder with description
  void _createFolderWithDescription() async =>
      await GoogleDriveWrite.createFolder(
          folderName: folderName, description: description);

  /// Updating an existing file
  void _updateJsonFile() async => await GoogleDriveWrite.updateJsonFile(
      filename: filename, content: newContent);

  /// Create a JSON file in an existing folder
  void _createJsonFileInFolder() async =>
      await GoogleDriveWrite.createJsonFileInFolder(
          folderName: folderName, filename: filename, content: content);

  /// Search for a file or a folder
  void _searchFile() async {
    Map map = await GoogleDriveRead.searchFile(filename);
    if (map.isEmpty) {
      log("No file was found.");
    } else {
      log("File was found.\n$map");
    }
  }

  /// Download a file to: /storage/emulated/0/Android/data/com.YOUR_ORGANIZE.APP_NAME/files/downloads
  void _downloadFile() async =>
      GoogleDriveRead.downloadFile(filename: filename, apiKey: apiKey);

  /// Read JSON file local
  void _readJsonFile() async {
    Map jsonFileFromDrive =
        await GoogleDriveRead.readJsonFile(filename: filename, apiKey: apiKey);
    log("JSON File: \n$jsonFileFromDrive\n");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home screen"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("sign in"),
              onPressed: () => _signIn(),
            ),
            ElevatedButton(
              child: const Text("sign out"),
              onPressed: () => _signOut(),
            ),
            ElevatedButton(
              child: const Text("create JSON file"),
              onPressed: () => _createJsonFile(),
            ),
            ElevatedButton(
              child: const Text("create folder"),
              onPressed: () => _createFolder(),
            ),
            ElevatedButton(
              child: const Text("create folder with description"),
              onPressed: () => _createFolderWithDescription(),
            ),
            ElevatedButton(
              child: const Text("update JSON file"),
              onPressed: () => _updateJsonFile(),
            ),
            ElevatedButton(
              child: const Text("create JSON file in folder"),
              onPressed: () => _createJsonFileInFolder(),
            ),
            ElevatedButton(
              child: const Text("search file or folder"),
              onPressed: () => _searchFile(),
            ),
            ElevatedButton(
              child: const Text("download JSON file"),
              onPressed: () => _downloadFile(),
            ),
            ElevatedButton(
              child: const Text("read JSON file"),
              onPressed: () => _readJsonFile(),
            ),
          ],
        ),
      ),
    );
  }
}
