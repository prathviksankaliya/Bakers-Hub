import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/provider/api_provider.dart';
import '../../services/file_downloader_service.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/show_toast.dart';
import 'dart:developer';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    mediaPlaybackRequiresUserGesture: false,
    domStorageEnabled: true,
    databaseEnabled: true,
    allowsInlineMediaPlayback: true,
    horizontalScrollBarEnabled: false,
    verticalScrollBarEnabled: false,
    supportZoom: false,
    iframeAllowFullscreen: true,
    transparentBackground: true,
  );
  bool showFirstLoader = true;

  String url = "";

  @override
  void dispose() {
    super.dispose();
    webViewController?.dispose();
  }

  @override
  void initState() {
    super.initState();
    NotificationService().initialize(context);
  }

  Future<void> requestCameraPermission() async {
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (await webViewController?.canGoBack() ?? false) {
          await webViewController?.goBack();
        } else {
          showExitDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri("${dotenv.get("BASE_URL", fallback: "")}")),
                initialSettings: settings,
                onWebViewCreated: (controller) async {
                  webViewController = controller;
                },
                onProgressChanged: (controller, progress) {
                  if (progress == 100 && showFirstLoader) {
                    setState(() => showFirstLoader = false);
                  }
                },
                onLoadStop: (controller, url) async {
                  if (showFirstLoader) {
                    setState(() => showFirstLoader = false);
                  }
                },
                onReceivedError: (controller, request, error) {
                  if (showFirstLoader) {
                    setState(() => showFirstLoader = false);
                  }
                },
                onReceivedHttpError: (controller, request, errorResponse) {
                  if (showFirstLoader) {
                    setState(() => showFirstLoader = false);
                  }
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  if (uri.toString().contains("?user_id=")) {
                    String? userId = uri.queryParameters['user_id'];
                    if (userId != null) {
                      await sendFCMToken(userId: userId);
                      await requestCameraPermission();
                    }
                  } else if (uri.toString() == "${dotenv.get("BASE_URL", fallback: "-1")}login") {
                    if (!await Permission.notification.isGranted) {
                      await FirebaseMessaging.instance.requestPermission(sound: true, alert: true, badge: true);
                    }
                    return NavigationActionPolicy.ALLOW;
                  } else if (!["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onPermissionRequest: (controller, permissionRequest) async {
                  if (permissionRequest.resources.contains(PermissionResourceType.CAMERA)) {
                    await requestCameraPermission();
                  }
                },
                onDownloadStartRequest: (controller, downloadStartRequest) async {
                  String downloadUrl = downloadStartRequest.url.toString();
                  ShowToast(msg: "Download started....");
                  String? fileName = downloadStartRequest.url.queryParameters['file_name'];
                  fileName ??= downloadUrl.split("/").last;
                  try {
                    await FileDownloaderService().fileDownloader(downloadUrl, fileName);
                  } catch (e) {
                    ShowToast(msg: "Something went wrong!");
                  }
                },
              ),
              // Loader overlay
              if (showFirstLoader)
                Container(
                  color: Colors.white, // optional: cover background fully
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFd1a16f),)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showExitDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.exit_to_app_rounded),
              SizedBox(width: 16),
              Text("Exit App", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text("Are you sure you want to close the app?"),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel", style: TextStyle(color: Colors.blue, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.white)),
                    onPressed: () {
                      SystemNavigator.pop(animated: true);
                    },
                    child: const Text("Exit", style: TextStyle(color: Colors.red, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> sendFCMToken({required String userId}) async {
    try {
      String fcmToken = await FirebaseService.fetchAndSaveFcmToken() ?? "";
      log("log: FCM Token $fcmToken");
      await ApiProvider().postRequest(endPoint: "user-api/save-device-id-api/", body: {"user_id": userId, "device_id": fcmToken});
    } catch (e) {
      ShowToast(msg: "Something went wrong!");
    }
  }
}
