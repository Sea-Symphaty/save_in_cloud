import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Class for reading and downloading the JSON file in Google Drive.
class GoogleDriveRead {
  /// The "DriveApi.driveFileScope" is the same as "https://www.googleapis.com/auth/drive.file"
  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.standard(scopes: [drive.DriveApi.driveFileScope]);
  static GoogleSignInAccount? _account;

  static Future _signIn() async {
    _account ??= await _googleSignIn.signIn();
    return;
  }

  /// The searching method is for searching and extracting the information from the searched file.
  static Future<Map> searchFile(String filename) async {
    await _signIn();

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
      Map fileInfo = {};

      /// If the data is found successfully, then it will search for the entered file and returns the information.
      for (Map value in filesList) {
        if (value["name"].split(".").first == filename) {
          fileInfo = value;
          break;
        }
      }

      return fileInfo;
    } else {
      log("Error in _searchFileId(): ${response.body}");
      return {};
    }
  }

  /// Downloading the file to this path: /storage/emulated/0/Android/data/com.YOUR_ORGANIZE.APP_NAME/files/downloads
  static Future<void> downloadFile(
      {required String filename, required String apiKey}) async {
    try {
      await _signIn();

      /// First, the information of the file is searched and added to the URL.
      Map fileInfo = await searchFile(filename);
      String fileMimeType = fileInfo["mimeType"];
      String fileId = fileInfo["id"];
      String fileName = fileInfo["name"];
      String url =
          "https://www.googleapis.com/drive/v3/files/$fileId?alt=media&mimeType=$fileMimeType&key=$apiKey HTTP/1.1";

      Map<String, String> authHeaders = await _account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      http.Response response = await authClient.get(Uri.parse(url));

      /// If the content of the JSON file is available, the path for the file is created.
      Directory? directory = (await getExternalStorageDirectories(
              type: StorageDirectory.downloads))
          ?.first;
      String localPath = directory!.path;
      File localFile =
          File("$localPath/$fileName.${fileMimeType.split("/").last}");

      if (await localFile.exists()) {
        /// If the file already exists, then a number in brackets is added after the name.
        int version = 1;
        bool exists = true;
        while (exists) {
          localFile = File(
              "$localPath/$fileName ($version).${fileMimeType.split("/").last}");
          version++;
          if (!(await localFile.exists())) {
            exists = false;
          }
        }
      }

      /// The JSON file is downloaded to the directory.
      await localFile.writeAsString(response.body);

      log("File downloaded successfully.");
    } on Exception catch (error) {
      log("Error in downloadFile(): \n$error\n");
    }
  }

  /// Read the JSON file and outputs the content as Map<String, dynamic>.
  static Future<Map<String, dynamic>> readJsonFile(
      {required String filename, required String apiKey}) async {
    try {
      await _signIn();

      /// First, the information of the file is searched and added to the URL.
      Map fileInfo = await searchFile(filename);
      String fileMimeType = fileInfo["mimeType"];
      String fileId = fileInfo["id"];
      String url =
          "https://www.googleapis.com/drive/v3/files/$fileId?alt=media&mimeType=$fileMimeType&key=$apiKey HTTP/1.1";

      Map<String, String> authHeaders = await _account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      http.Response response = await authClient.get(Uri.parse(url));

      /// If the content of the file is available, then the content of the file will be returned.
      return json.decode(response.body);
    } on Exception catch (error) {
      log("Error in readJsonFile(): \n$error\n");
      return {};
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
