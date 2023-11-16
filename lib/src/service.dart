import 'dart:developer';
import 'package:html/parser.dart' show parse;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';

/// The "DriveApi.driveFileScope" is the same as "https://www.googleapis.com/auth/drive.file"
final GoogleSignIn googleSignIn = GoogleSignIn.standard(scopes: [DriveApi.driveFileScope]);
GoogleSignInAccount? account;
String textFromHTML({required String output}) => parse(output).body?.text ?? "";
const String filesEndpoint = "https://www.googleapis.com/drive/v3/files";

void info({required String text}) {
  var lineNumber = StackTrace.current.toString().split("\n")[1];
  var path = lineNumber.toString().split("(")[1].split(")")[0];
  int width = 0;
  int textLength = text.length;
  int pathLength = path.length;
  String space = "";
  bool top = false;
  if (textLength < pathLength) {
    width = pathLength;
    space = List.filled(pathLength - textLength, " ").join();
    top = true;
  } else {
    width = textLength;
    space = List.filled(textLength - pathLength, " ").join();
    top = false;
  }
  String line = List.filled(width + 2, "\u2550").join();
  log("\n\u2554$line\u2557"
      "\n\u2551 $text ${top ? space : ""}\u2551"
      "\n\u2551 $path ${!top ? space : ""}\u2551"
      "\n\u255a$line\u255d\n", name: "INFO");
}
