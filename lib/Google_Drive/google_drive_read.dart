import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GoogleDriveRead {

  static final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: [drive.DriveApi.driveFileScope]);
  static GoogleSignInAccount? _account;

  static Future _signIn() async {
    _account ??= await _googleSignIn.signIn();
    return;
  }

  static Future<Map> _searchFileId(String filename) async {
    Map<String, String> headers = await _account!.authHeaders;
    http.Response response = await http.get(
        Uri.parse("https://www.googleapis.com/drive/v3/files"),
        headers: headers
    );

    if (response.statusCode == 200) {
      List filesList = json.decode(response.body)["files"];
      Map fileInfo = {};

      for (Map value in filesList) {
        if (value["name"] == filename) {
          fileInfo = value;
          break;
        }
      }

      return fileInfo;
    } else {
      log("Error: ${response.body}");
      return {};
    }
  }

  static Future<void> downloadFile({required String filename, required String apiKey}) async {
    try {
      await _signIn();
      Map fileInfo = await _searchFileId(filename);
      String fileMimeType = fileInfo["mimeType"];
      String fileId = fileInfo["id"];
      String fileName = fileInfo["name"];
      String url =
          "https://www.googleapis.com/drive/v3/files/$fileId?alt=media&mimeType=$fileMimeType&key=$apiKey HTTP/1.1";

      Map<String, String> authHeaders = await _account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      http.Response response = await authClient.get(
          Uri.parse(url)
      );

      Directory? directory = (await getExternalStorageDirectories(type: StorageDirectory.downloads))?.first;
      String localPath = directory!.path;
      File localFile = await File(
          "$localPath/$fileName.${fileMimeType.split("/").last}")
          .create(exclusive: true);

      if (await localFile.exists()) {
        int version = 1;
        bool exists = true;
        while (exists) {
          localFile = File("$localPath/$fileName ($version).${fileMimeType.split("/").last}");
          version++;
          if (!(await localFile.exists())) {
            exists = false;
          }
        }
      }

      await localFile.writeAsString(response.body);
      log("File downloaded successfully.");
    } on Exception catch(error) {
      log("downloadFile() Error: \n$error\n");
    }
  }

  static Future<Map> readJsonFile({required String filename, required String apiKey}) async {
    try {
      await _signIn();
      Map fileInfo = await _searchFileId(filename);
      String fileMimeType = fileInfo["mimeType"];
      String fileId = fileInfo["id"];
      String url = "https://www.googleapis.com/drive/v3/files/$fileId?alt=media&mimeType=$fileMimeType&key=$apiKey HTTP/1.1";

      Map<String, String> authHeaders = await _account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      http.Response response = await authClient.get(
          Uri.parse(url)
      );

      return json.decode(response.body);
    } on Exception catch(error) {
      log("readJsonFile() Error: \n$error\n");
      return {};
    }
  }
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _AuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _client.send(request..headers.addAll(_headers));
}