import 'dart:convert';
import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart';

class GoogleDriveWrite {

  static final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [DriveApi.driveFileScope]);
  static GoogleSignInAccount? _account;

  static Future<void> signOut() async {
    _googleSignIn.disconnect();
    _account = null;
  }

  static Future signIn() async {
    _account ??= await _googleSignIn.signIn();
    return;
  }

  static Future<String?> _accessToken() async {
    GoogleSignInAuthentication authentication = await _account!.authentication;
    return authentication.accessToken;
  }

  static Future<void> createJsonFile({required String filename, required Map content}) async {
    await signIn();
    if (_account != null) {
      String createUrl = "https://www.googleapis.com/drive/v3/files";
      Map fileData = {"name" : "$filename.json"};

      http.Response createResponse = await http.post(
          Uri.parse(createUrl),
          headers: {
            "Content-Type" : "application/json; charset=UTF-8",
            "Authorization": "Bearer ${await _accessToken()}"
          },
          body: json.encode(fileData)
      );

      if (createResponse.statusCode == 200) {
        Map responseBody = json.decode(createResponse.body);
        String fileId = responseBody["id"];
        String uploadUrl = "https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media";

        http.Response uploadResponse = await http.patch(
            Uri.parse(uploadUrl),
            headers: {
              "Authorization": "Bearer ${await _accessToken()}"
            },
            body: json.encode(content)
        );

        if (uploadResponse.statusCode == 200) {
          log("File created successfully.");
        } else {
          log("Error uploading file.");
        }
      } else {
        log("Error while creating the empty file.");
      }

    } else {
      log("The registration was rejected by the user.");
    }
  }

  static Future<void> createFolder({required String folderName, String? description}) async {
    try {
      await signIn();
      Map<String, String> authHeaders = await _account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      DriveApi driveApi = DriveApi(authClient);
      File file = File(
          name: folderName,
          mimeType: "application/vnd.google-apps.folder",
          description: description
      );
      await driveApi.files.create(file);
      log("Folder created successfully.");
    } on Exception catch(error) {
      log("Error: $error");
    }
  }

  static Future<String> _searchFileId(String filename) async {
    Map<String, String> headers = await _account!.authHeaders;
    http.Response response = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files"),
        headers: headers
    );

    if (response.statusCode == 200) {
      List filesList = json.decode(response.body)["files"];
      String fileId = "";

      for (Map value in filesList) {
        if (value["name"] == filename) {
          fileId = value["id"];
          break;
        }
      }

      return fileId;
    } else {
      log("Error: ${response.body}");
      return "";
    }
  }

  static Future<void> updateJsonFile({required String filename, required Map content, String? newFilename}) async {
    await signIn();

    String fileId = await _searchFileId(filename);

    if (fileId.isEmpty) {
      log("File not found.");
      return;
    }

    http.Response updateFile = await http.patch(
        Uri.parse("https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media"),
        headers: {
          "Authorization": "Bearer ${await _accessToken()}"
        },
        body: json.encode(content)
    );

    if (updateFile.statusCode == 200) {
      log("File created successfully.");
    } else {
      log("File create failed: ${updateFile.body}");
    }
  }

  static Future<void> createJsonFileInFolder(
      {required String folderName, required String filename, required Map content}) async {
    await signIn();

    String folderId = await _searchFileId(folderName);
    if (folderId.isEmpty) {
      log("Folder not found.");
      return;
    }
    http.Response updateFile = await http.post(
        Uri.parse("https://www.googleapis.com/upload/drive/v3/files"),
        headers: {
          "Content-Type" : "application/json; charset=UTF-8",
          "Authorization" : "Bearer ${await _accessToken()}",
        },
        body: json.encode(content)
    );

    var fileId = json.decode(updateFile.body)["id"];

    Map<String, String> authHeaders = await _account!.authHeaders;
    _AuthClient authClient = _AuthClient(authHeaders);
    DriveApi driveApi = DriveApi(authClient);
    File file = File(
        name: filename,
        mimeType: "application/json; charset=UTF-8"
    );
    await driveApi.files.update(file, fileId, addParents: folderId);
  }
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _client.send(request..headers.addAll(_headers));
}