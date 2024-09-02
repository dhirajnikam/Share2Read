import 'package:flutter/material.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];
  String? _sharedUrl;

  @override
  void initState() {
    super.initState();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);

        // Check if the shared content is a URL
        _sharedUrl = _sharedFiles.isNotEmpty
            ? _extractUrl(_sharedFiles.map((f) => f.toMap()).toString())
            : null;

        print(_sharedFiles.map((f) => f.toMap()));
      });
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);

        // Check if the shared content is a URL
        _sharedUrl = _sharedFiles.isNotEmpty
            ? _extractUrl(_sharedFiles.map((f) => f.toMap()).toString())
            : null;

        print(_sharedFiles.map((f) => f.toMap()));

        // Tell the library that we are done processing the intent.
        ReceiveSharingIntent.instance.reset();
      });
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  String? _extractUrl(String? text) {
    if (text != null && text.isNotEmpty) {
      // Regular expression to match Medium URLs
      final urlRegExp = RegExp(
        r'(https?:\/\/medium\.com\/[^\s,}]+)', // Match only Medium URLs
        caseSensitive: false,
        multiLine: false,
      );
      final match = urlRegExp.firstMatch(text);
      print(match?.group(0));
      return match?.group(0);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const textStyleBold = TextStyle(fontWeight: FontWeight.bold);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Share2Read'),
        ),
        body: _sharedUrl != null
            ? WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(
                      Uri.parse('https://www.freedium.cfd/$_sharedUrl')),
                // initialUrl: 'https://www.freedium.cfd/?url=$_sharedUrl',
                // javascriptMode: JavascriptMode.unrestricted,
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Shared files:", style: textStyleBold),
                    Text(_extractUrl(
                            _sharedFiles.map((f) => f.toMap()).toString()) ??
                        ""),
                  ],
                ),
              ),
      ),
    );
  }
}
