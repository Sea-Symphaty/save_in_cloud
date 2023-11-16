# Overview
[![GitHub](https://img.shields.io/badge/GitHub-save_in_cloud-gre.svg?logo=github&color=2ea44f)](https://github.com/Sea-Symphaty/save_in_cloud) [![Pub](https://img.shields.io/pub/v/save_in_cloud.svg?logo=dart&color=2ea44f)](https://pub.dev/packages/save_in_cloud)

With this package you can read, download, create, edit and search JSON files from Google Drive. You can also create folders and save the files into them.

## Table of Contents

1. [Before use](#before-use)
    1. [Project](#project)
    2. [Activate API](#activate-api)
    3. [OAuth 2.0](#oauth-20)
    4. [API Key](#api-key)
2. [Additional information](#additional-information)
3. [Example](#example)
4. [Version 2.0.0](#version-200)

# Before use

### Project
1. First log in or register at <https://console.cloud.google.com>.
2. Create or select a project.

### Activate API
1. Click on the Navigation menu in the upper left corner.
2. Go to "APIs & Services" > "Library" and select or search for "Google Drive API" and enable it.

### OAuth 2.0
1. Select "APIs and Services" from the Navigation menu and then click on "Credentials".
2. Click on "+ CREATE CREDENTIALS" at the top and then select "OAuth client ID".
3. Click on "CONFIGURE CONSENT SCREEN".
4. Select User Type "External" and click on "CREATE".
5. Where there is a red star, fill in the fields and click on "SAVE AND CONTINUE".
6. Click on "ADD OR REMOVE SCOPES" and manually insert: ``https://www.googleapis.com/auth/drive.file``, click on "ADD TO TABLE" and then on "UPDATE". After that click on "SAVE AND CONTINUE".
7. Add test users who will use the app. After adding go to "SAVE AND CONTINUE".
8. If all data is correct, then "BACK TO THE DASHBOARD".
9. Again select "Credentials" and at the top click on "+ CREATE CREDENTIALS" "OAuth Client ID".
10. Under "Application type" select the appropriate operating system (in this example it is Android).
11. At Name select the name for the Console, at Package name enter your Package name for example "com.example.app" and finally enter the SHA1. Here is a good explanation <https://stackoverflow.com/questions/51845559/generate-sha-1-for-flutter-react-native-android-native-app>.
12. Finally click on "CREATE".

### API Key
1. Click on "+ CREATE CREDENTIALS" at the top and then select "API key".
2. When the API Key is created, you can copy it and close the window.
3. In the list "API Keys" click on the appropriate key to see the information.
4. Under "API restrictions" select "Restrict key".
5. At "Select APIs" select "Google Drive API" and confirm with "OK
6. Then click "SAVE"

The generated API Key is required in the package.

# Additional information
In this package the following packages were used:

* google_sign_in
* googleapis
* http
* path_provider

# Example:

```dart
Map content = {
  "Map" : {},
  "String" : "string",
  "int" : 0,
  "bool" : true,
  "List" : []
};
Map newContent = {
  "Map" : {},
  "String" : "string",
  "int" : 0,
  "bool" : true,
  "List" : [
    "updated"
  ]
};
String filename = "file";
String apiKey = "YOUR_API_KEY";// todo: insert the API key here

/// Create a JSON file
void _createJsonFile() async {
  int? createJsonFileCode = await GoogleDriveWrite.createJsonFile(filename: filename, content: content);

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

/// Updating an existing file
void _updateJsonFile() async {
  int? updateJsonFileCode = await GoogleDriveWrite.updateJsonFile(filename: filename, content: newContent);

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

/// Read JSON file local
void _readJsonFile() async {
  Map? readJsonFileMap = await GoogleDriveRead.readJsonFile(filename: filename, apiKey: apiKey);

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
            child: const Text("create JSON file"),
            onPressed: () => _createJsonFile(),
          ),
          ElevatedButton(
            child: const Text("update JSON file"),
            onPressed: () => _updateJsonFile(),
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
```

# Version 2.0.0
In the latest version, the outputs are data types. Previously they were only void methods. The new data types are available in Example.