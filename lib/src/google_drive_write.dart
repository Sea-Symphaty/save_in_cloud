import 'dart:convert';
import 'dart:developer';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart';
import 'service.dart';

/// Class for create, update JSON file and create folder in Google Drive.
class GoogleDriveWrite {
  static Future<void> signOut() async {
    googleSignIn.disconnect();
    account = null;
  }

  static Future<bool> signIn() async {
    account ??= await googleSignIn.signIn();
    return googleSignIn.isSignedIn();
  }

  /// Extract the accessToken from the user.
  static Future<String?> _accessToken() async {
    GoogleSignInAuthentication authentication = await account!.authentication;
    return authentication.accessToken;
  }

  /// Create a new JSON file in Google Drive.
  /// The output value is an INT so that the error can be determined more precisely when it occurs.
  ///
  /// Error code:
  ///
  /// * 0: File created successfully.
  /// * 1: The user hasn't logged in.
  /// * 2: Error while creating the empty file.
  /// * 3: Error uploading file.
  static Future<int?> createJsonFile(
      {required String filename, required Map content}) async {
    if (await signIn()) {
      /// Creates an empty JSON file with the accessToken from the user.

      String? accessToken = await _accessToken();
      Map fileData = {"name": "$filename.json"};

      http.Response createResponse = await http.post(Uri.parse(filesEndpoint),
          headers: {
            "Content-Type": "application/json; charset=UTF-8",
            "Authorization": "Bearer $accessToken"
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
              "Authorization": "Bearer $accessToken"
            },
            body: json.encode(content));

        if (uploadResponse.statusCode == 200) {
          log("File created successfully.", name: "Create JSON File");
          return 0;
        } else {
          info(text: "Error uploading file.");
          log(textFromHTML(output: uploadResponse.body),
              name: "Create JSON File");
          return 3;
        }
      } else {
        info(text: "Error while creating the empty file.");
        log(textFromHTML(output: createResponse.body),
            name: "Create JSON File");
        return 2;
      }
    } else {
      info(text: "The user hasn't logged in. GoogleSignInAccount: $account");
      return 1;
    }
  }

  /// Create a new folder in Google Drive.
  static Future<bool> createFolder(
      {required String folderName, String? description}) async {
    if (await signIn()) {
      Map<String, String> authHeaders = await account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      DriveApi driveApi = DriveApi(authClient);
      File file = File(
          name: folderName,
          mimeType: "application/vnd.google-apps.folder",
          description: description);

      await driveApi.files.create(file);

      log("Folder created successfully.", name: "Create Folder");
      return true;
    } else {
      info(text: "The user hasn't logged in. GoogleSignInAccount: $account");
      return false;
    }
  }

  /// The searching method is for updating or creating in folder.
  static Future<String?> _searchFileId(String filename) async {
    /// The first thing to do is to create a list of files in Google Drive.
    /// The information of the data looks like this:
    /// {
    ///   "kind": "drive#file",
    ///   "mimeType": "application/json",
    ///   "id": "COMBINATION_OF_NUMBERS_AND_LETTERS",
    ///   "name": "file.json"
    /// }
    Map<String, String> headers = await account!.authHeaders;
    http.Response response =
        await http.get(Uri.parse(filesEndpoint), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> filesList = json.decode(response.body)["files"];
      String fileId = "";

      /// If the data is found successfully, then it will search for the entered file and returns the id.
      for (Map value in filesList) {
        String nameWithoutExtension = value["name"].split(".").first;
        if (nameWithoutExtension == filename) {
          fileId = value["id"];
          break;
        }
      }

      if (fileId.isEmpty) {
        return "File was not found";
      }

      return fileId;
    } else {
      info(text: "Error in _searchFieldId()");
      log(response.body, name: "_searchFieldId");
      return response.body;
    }
  }

  /// Updates an existing JSON file.
  /// The output value is an INT so that the error can be determined more precisely when it occurs.
  ///
  /// For error codes 2 and 4, the error code is displayed in the console.
  /// [Error code guide](https://developers.google.com/drive/api/guides/handle-errors?hl=en#status-codes)
  ///
  /// Error code:
  ///
  /// * 0: File updated successfully.
  /// * 1: The user hasn't logged in.
  /// * 2: Errors in connection with HTTP.
  /// * 3: File was not found.
  /// * 4: File creation failed.
  static Future<int?> updateJsonFile(
      {required String filename, required Map content}) async {
    if (await signIn()) {
      String? fileId = await _searchFileId(filename);

      if (fileId!.length >= 200) {
        return 2;
      } else if (fileId == "File was not found") {
        return 3;
      }

      http.Response updateFile = await http.patch(
          Uri.parse(
              "https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media"),
          headers: {"Authorization": "Bearer ${await _accessToken()}"},
          body: json.encode(content));

      if (updateFile.statusCode == 200) {
        log("File updated successfully.", name: "Update JSON file");
        return 0;
      } else {
        info(text: "File creation failed.");
        log("${json.decode(updateFile.body)}", name: "Update JSON File");
        return 4;
      }
    } else {
      info(text: "The user hasn't logged in.");
      return 1;
    }
  }

  /// Creates a new JSON file and moves it to an existing folder.
  /// The output value is an INT so that the error can be determined more precisely when it occurs.
  ///
  /// For error code 2, the error code is displayed in the console.
  /// [Error code guide](https://developers.google.com/drive/api/guides/handle-errors?hl=en#status-codes)
  ///
  /// Error code:
  ///
  /// * 0: File created successfully.
  /// * 1: The user hasn't logged in.
  /// * 2: Errors in connection with HTTP.
  static Future<int> createJsonFileInFolder(
      {required String folderName,
      required String filename,
      required Map content}) async {
    if (await signIn()) {
      String? folderId = await _searchFileId(folderName);

      if (folderId!.length >= 200) {
        return 2;
      } else if (folderId == "File was not found") {
        await createFolder(folderName: folderName);
        folderId = await _searchFileId(folderName);
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
      Map<String, String> authHeaders = await account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      DriveApi driveApi = DriveApi(authClient);
      File file = File(
          name: "$filename.json", mimeType: "application/json; charset=UTF-8");

      await driveApi.files.update(file, fileId, addParents: folderId);

      log("File created in folder successfully.",
          name: "Create JSON File in Folder");
      return 0;
    } else {
      info(text: "The user hasn't logged in.");
      return 1;
    }
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
