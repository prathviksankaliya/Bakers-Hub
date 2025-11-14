import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/show_toast.dart';
import 'notification_service.dart';

class FileDownloaderService {
  Future<void> fileDownloader(String url, String fileName) async {
    try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          Directory? dir;

          if (Platform.isIOS) {
            dir = await getApplicationDocumentsDirectory();
          } else {
            dir = Directory('/storage/emulated/0/Download/eHunt');
            if (!await dir.exists()) {
              await dir.create(recursive: true); // Create folder if it doesn't exist
            }
          }

          String pathData = dir.path;
          String newFileName = getUniqueFileName(pathData, fileName);
          final file = File("$pathData/$newFileName");
          await file.writeAsBytes(response.bodyBytes);

          int bytes = file.lengthSync();
          bool permissionDone = await NotificationService().requestPermissions();
          if (permissionDone) {
            await NotificationService().showManualNotification(
              title: newFileName,
              body: "Download complete • ${formatBytes(bytes, 2)}",
              payload: "$pathData/$newFileName",
            );
          } else {
            ShowToast(msg: "File downloaded successfully");
          }
        } else {
          throw "Please check internet";
        }
    } catch (e) {
      ShowToast(msg: "Something went wrong!");
    }
  }


  /// Helper function to format bytes into KB, MB, GB, etc.
  String formatBytes(int bytes, [int decimals = 2]) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Generate a unique filename if the file already exists
  String getUniqueFileName(String directoryPath, String fileName) {
    String baseName = fileName;
    String extension = "";

    // Extract base name and extension
    if (fileName.contains('.')) {
      int dotIndex = fileName.lastIndexOf('.');
      baseName = fileName.substring(0, dotIndex);
      extension = fileName.substring(dotIndex);
    }

    int count = 1;
    String newFileName = fileName;
    while (File("$directoryPath/$newFileName").existsSync()) {
      newFileName = "$baseName($count)$extension";
      count++;
    }

    return newFileName;
  }
}
