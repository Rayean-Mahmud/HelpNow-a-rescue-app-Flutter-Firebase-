import 'package:flutter/cupertino.dart';

// Integrating webview_flutter package for web views
import 'package:webview_flutter/webview_flutter.dart';

class SafeWebView extends StatelessWidget {
  final String? url;
  // Using WebView widget
  SafeWebView({this.url});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WebView(
        initialUrl: url,
      ),
    );
  }
}
