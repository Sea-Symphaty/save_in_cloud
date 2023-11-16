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
  void _signIn() async {
    bool signIn = await GoogleDriveWrite.signIn();

    if (signIn) {
      log("User has logged in", name: "Sign in");
    } else {
      log("User has not logged in", name: "Sign in");
    }
  }

  /// Sign out
  void _signOut() async {
    await GoogleDriveWrite.signOut();
    log("User has logged out", name: "Sign out");
  }

  /// Create a JSON file
  void _createJsonFile() async {
    int? createJsonFileCode = await GoogleDriveWrite.createJsonFile(
        filename: filename, content: content);

    if (createJsonFileCode == 1) {
      log("User has not logged in", name: "_createJsonFile()");
    } else if (createJsonFileCode == 2) {
      log("Error while creating the empty file.", name: "_createJsonFile()");
    } else if (createJsonFileCode == 3) {
      log("Error uploading file.", name: "_createJsonFile()");
    } else {
      log("File created successfully.", name: "_createJsonFile()");
    }
  }

  /// Create a folder without description
  void _createFolder() async {
    bool createFolder =
        await GoogleDriveWrite.createFolder(folderName: folderName);

    if (createFolder) {
      log("Folder created successfully.", name: "_createFolder()");
    } else {
      log("The user hasn't logged in.", name: "_createFolder()");
    }
  }

  /// Create a folder with description
  void _createFolderWithDescription() async {
    bool createFolder = await GoogleDriveWrite.createFolder(
        folderName: folderName, description: description);

    if (createFolder) {
      log("Folder created successfully.",
          name: "_createFolderWithDescription()");
    } else {
      log("The user hasn't logged in.", name: "_createFolderWithDescription()");
    }
  }

  /// Updating an existing file
  void _updateJsonFile() async {
    int? updateJsonFileCode = await GoogleDriveWrite.updateJsonFile(
        filename: filename, content: newContent);

    if (updateJsonFileCode == 1) {
      log("The user hasn't logged in.", name: "_updateJsonFile()");
    } else if (updateJsonFileCode == 2) {
      log("Error in connection with HTTP.", name: "_updateJsonFile()");
      log("https://developers.google.com/drive/api/guides/handle-errors?hl=en#status-codes",
          name: "Error code guide");
    } else if (updateJsonFileCode == 3) {
      log("File was not found.", name: "_updateJsonFile()");
    } else if (updateJsonFileCode == 4) {
      log("File creation failed.", name: "_updateJsonFile()");
      log("https://developers.google.com/drive/api/guides/handle-errors?hl=en#status-codes",
          name: "Error code guide");
    } else {
      log("File updated successfully.", name: "_updateJsonFile()");
    }
  }

  /// Create a JSON file in an existing folder
  void _createJsonFileInFolder() async {
    int createJsonFileInFolderCode =
        await GoogleDriveWrite.createJsonFileInFolder(
            folderName: folderName, filename: filename, content: content);

    if (createJsonFileInFolderCode == 1) {
      log("The user hasn't logged in.", name: "_createJsonFileInFolder()");
    } else if (createJsonFileInFolderCode == 2) {
      log("Error in connection with HTTP.", name: "_createJsonFileInFolder()");
      log("https://developers.google.com/drive/api/guides/handle-errors?hl=en#status-codes",
          name: "Error code guide");
    } else {
      log("File created successfully.", name: "_createJsonFileInFolder()");
    }
  }

  /// Search for a file or a folder
  void _searchFile() async {
    Map? searchFileMap = await GoogleDriveRead.searchFile(filename);

    if (searchFileMap == null) {
      log("The user hasn't logged in.", name: "_searchFile()");
    } else if (searchFileMap.isEmpty) {
      log("No file was found.", name: "_searchFile()");
    } else if (searchFileMap.keys.toList().first == "search error") {
      log("Search error: $searchFileMap", name: "_searchFile()");
    } else {
      log("File was found.\n$searchFileMap", name: "_searchFile()");
    }
  }

  /// Download a file to: /storage/emulated/0/Android/data/com.YOUR_ORGANIZE.APP_NAME/files/downloads
  void _downloadFile() async {
    int downloadFileCode =
        await GoogleDriveRead.downloadFile(filename: filename, apiKey: apiKey);

    if (downloadFileCode == 1) {
      log("The user hasn't logged in.", name: "_downloadFile()");
    } else if (downloadFileCode == 2) {
      log("No file was found.", name: "_downloadFile()");
    } else {
      log("File downloaded successfully.", name: "_downloadFile()");
    }
  }

  /// Read JSON file local
  void _readJsonFile() async {
    Map? readJsonFileMap =
        await GoogleDriveRead.readJsonFile(filename: filename, apiKey: apiKey);

    if (readJsonFileMap == null) {
      log("The user hasn't logged in.", name: "_readJsonFile()");
    } else if (readJsonFileMap.isEmpty) {
      log("No file found.", name: "_readJsonFile()");
    } else {
      log("JSON File: \n$readJsonFileMap\n", name: "_readJsonFile()");
    }
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
