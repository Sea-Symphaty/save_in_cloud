import 'dart:convert';
import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart';

/// Class for create, update JSON file and create folder in Google Drive.
class GoogleDriveWrite {
  /// The "DriveApi.driveFileScope" is the same as "https://www.googleapis.com/auth/drive.file"
  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.standard(scopes: [DriveApi.driveFileScope]);
  static GoogleSignInAccount? _account;

  static Future<void> signOut() async {
    _googleSignIn.disconnect();
    _account = null;
  }

  static Future signIn() async {
    _account ??= await _googleSignIn.signIn();
    return;
  }

  /// Extract the accessToken from the user.
  static Future<String?> _accessToken() async {
    GoogleSignInAuthentication authentication = await _account!.authentication;
    return authentication.accessToken;
  }

  /// Create a new JSON file in Google Drive.
  static Future<void> createJsonFile(
      {required String filename, required Map content}) async {
    await signIn();
    try {
      /// Creates an empty JSON file with the accessToken from the user.
      String createUrl = "https://www.googleapis.com/drive/v3/files";
      Map fileData = {"name": "$filename.json"};

      http.Response createResponse = await http.post(Uri.parse(createUrl),
          headers: {
            "Content-Type": "application/json; charset=UTF-8",
            "Authorization": "Bearer ${await _accessToken()}"
          },
          body: json.encode(fileData));

      if (createResponse.statusCode == 200) {
        /// If the was file created successfully, the content will be added
        Map responseBody = json.decode(createResponse.body);
        String fileId = responseBody["id"];
        String uploadUrl =
            "https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media";

        http.Response uploadResponse = await http.patch(Uri.parse(uploadUrl),
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
              "Authorization": "Bearer ${await _accessToken()}"
            },
            body: json.encode(content));

        if (uploadResponse.statusCode == 200) {
          log("File created successfully.");
        } else {
          log("Error uploading file.");
        }
      } else {
        log("Error while creating the empty file.");
      }
    } on Exception catch (error) {
      log("Error in createJsonFile():\n$error\n");
    }
  }

  /// Create a new folder in Google Drive.
  static Future<void> createFolder(
      {required String folderName, String? description}) async {
    try {
      await signIn();

      Map<String, String> authHeaders = await _account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      DriveApi driveApi = DriveApi(authClient);
      File file = File(
          name: folderName,
          mimeType: "application/vnd.google-apps.folder",
          description: description);
      await driveApi.files.create(file);

      log("Folder created successfully.");
    } on Exception catch (error) {
      log("Error in createFolder(): $error");
    }
  }

  /// The searching method is for updating or creating in folder.
  static Future<String> _searchFileId(String filename) async {
    /// The first thing to do is to create a list of files in Google Drive.
    /// The information of the data looks like this:
    /// {
    ///   "kind": "drive#file",
    ///   "mimeType": "application/json",
    ///   "id": "COMBINATION_OF_NUMBERS_AND_LETTERS",
    ///   "name": "file.json"
    /// }
    Map<String, String> headers = await _account!.authHeaders;
    http.Response response = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files"),
        headers: headers);

    if (response.statusCode == 200) {
      List filesList = json.decode(response.body)["files"];
      String fileId = "";

      /// If the data is found successfully, then it will search for the entered file and returns the id.
      for (Map value in filesList) {
        if (value["name"].split(".").first == filename) {
          fileId = value["id"];
          break;
        }
      }

      return fileId;
    } else {
      log("Error in _searchFileId(): ${response.body}");
      return "";
    }
  }

  /// Updates an existing JSON file.
  static Future<void> updateJsonFile(
      {required String filename, required Map content}) async {
    await signIn();

    String fileId = await _searchFileId(filename);

    if (fileId.isEmpty) {
      log("File not found.");
      return;
    }

    http.Response updateFile = await http.patch(
        Uri.parse(
            "https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media"),
        headers: {"Authorization": "Bearer ${await _accessToken()}"},
        body: json.encode(content));

    if (updateFile.statusCode == 200) {
      log("File updated successfully.");
    } else {
      log("File create failed: ${updateFile.body}");
    }
  }

  /// Creates a new JSON file and moves it to an existing folder.
  static Future<void> createJsonFileInFolder(
      {required String folderName,
      required String filename,
      required Map content}) async {
    await signIn();

    String folderId = await _searchFileId(folderName);
    if (folderId.isEmpty) {
      log("Folder not found.");
      return;
    }

    /// Create a JSON file with the content and the accessToken.
    http.Response updateFile = await http.post(
        Uri.parse("https://www.googleapis.com/upload/drive/v3/files"),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer ${await _accessToken()}",
        },
        body: json.encode(content));

    var fileId = json.decode(updateFile.body)["id"];

    /// The created file is moved to the existing folder.
    Map<String, String> authHeaders = await _account!.authHeaders;
    _AuthClient authClient = _AuthClient(authHeaders);
    DriveApi driveApi = DriveApi(authClient);
    File file = File(
        name: "$filename.json", mimeType: "application/json; charset=UTF-8");
    await driveApi.files.update(file, fileId, addParents: folderId);

    log("File created in folder successfully.");
  }
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request..headers.addAll(_headers));
}
