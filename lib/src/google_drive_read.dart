import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'service.dart';

/// Class for reading and downloading the JSON file in Google Drive.
class GoogleDriveRead {

  static Future<bool> _signIn() async {
    account ??= await googleSignIn.signIn();
    return googleSignIn.isSignedIn();
  }

  /// The searching method is for searching and extracting the information from the searched file.
  static Future<Map?> searchFile(String filename) async {
    if (await _signIn()) {

      /// The first thing to do is to create a list of files in Google Drive.
      /// The information of the data looks like this:
      /// {
      ///   "kind": "drive#file",
      ///   "mimeType": "application/json",
      ///   "id": "COMBINATION_OF_NUMBERS_AND_LETTERS",
      ///   "name": "file.json"
      /// }
      Map<String, String> headers = await account!.authHeaders;
      http.Response response = await http.get(
          Uri.parse(filesEndpoint),
          headers: headers
      );

      if (response.statusCode == 200) {
        List<dynamic> filesList = json.decode(response.body)["files"];
        Map fileInfo = {};

        /// If the data is found successfully, then it will search for the entered file and returns the information.
        for (Map value in filesList) {
          if (value["name"].split(".").first == filename) {
            fileInfo = value;
            break;
          }
        }
        
        log("Search process successful", name: "Search file or folder");
        return fileInfo;
      } else {
        info(text: "Error searching file or folder.");
        log(response.body, name: "Search file or folder");
        return {"search error" : response.body};
      }
    } else {
      info(text: "The user hasn't logged in.");
      return null;
    }
  }

  /// Downloading the file to this path: /storage/emulated/0/Android/data/com.YOUR_ORGANIZE.APP_NAME/files/downloads
  ///
  /// The output value is an INT so that the error can be determined more precisely when it occurs.
  ///
  /// Error code:
  ///
  /// * 0: File downloaded successfully.
  /// * 1: The user hasn't logged in.
  /// * 2: No file was found.
  static Future<int> downloadFile(
      {required String filename, required String apiKey}) async {

    /// First, the information of the file is searched and added to the URL.
    Map? fileInfo = await searchFile(filename);
    if (fileInfo == null) {
      info(text: "The user hasn't logged in.");
      return 1;
    } else if (fileInfo.isEmpty) {
      info(text: "No file was found.");
      return 2;
    } else {
      String fileMimeType = fileInfo["mimeType"];
      String fileId = fileInfo["id"];
      String fileName = fileInfo["name"];
      String url =
        "$filesEndpoint/$fileId?alt=media&mimeType=$fileMimeType&key=$apiKey HTTP/1.1";
      //todo test

      Map<String, String> authHeaders = await account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      http.Response response = await authClient.get(Uri.parse(url));

      /// If the content of the JSON file is available, the path for the file is created.
      Directory? directory = (await getExternalStorageDirectories(type: StorageDirectory.downloads))?.first;
      String localPath = directory!.path;
      File localFile = File("$localPath/$fileName.${fileMimeType.split("/").last}");

      if (await localFile.exists()) {
        /// If the file already exists, then a number in brackets is added after the name.
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

      /// The JSON file is downloaded to the directory.
      await localFile.writeAsString(response.body);

      log("File downloaded successfully.", name: "Download file");
      return 0;
    }
  }

  /// Read the JSON file and outputs the content as Map<String, dynamic>.
  static Future<Map<String, dynamic>?> readJsonFile(
      {required String filename, required String apiKey}) async {
    /// First, the information of the file is searched and added to the URL.
    Map? fileInfo = await searchFile(filename);
    if (fileInfo == null) {
      info(text: "The user hasn't logged in.");
      return null;
    } else if (fileInfo.isEmpty) {
      info(text: "No file found.");
      return {};
    } else {
      String fileMimeType = fileInfo["mimeType"];
      String fileId = fileInfo["id"];
      String url =
        "$filesEndpoint/$fileId?alt=media&mimeType=$fileMimeType&key=$apiKey HTTP/1.1";

      Map<String, String> authHeaders = await account!.authHeaders;
      _AuthClient authClient = _AuthClient(authHeaders);
      http.Response response = await authClient.get(Uri.parse(url));

      /// If the content of the file is available, then the content of the file will be returned.
      log("File read successful.", name: "Read Json File");
      return json.decode(response.body);
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
