import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewContainer extends StatefulWidget {
  final bool isPicker;
  final String url;
  final String clientId;

  WebViewContainer({
    @required this.url,
    @required this.isPicker,
    this.clientId,
  });

  @override
  _WebViewContainerState createState() => _WebViewContainerState(this.url);
}

class _WebViewContainerState extends State<WebViewContainer> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  String _url;
  bool isLoading;

  _WebViewContainerState(this._url);

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: WebView(
                    initialUrl: _url,
                    userAgent: 'random',
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebViewCreated: (WebViewController webViewController) {
                      _controller.complete(webViewController);
                    },
                    javascriptChannels: <JavascriptChannel>[
                      JavascriptChannel(
                        name: 'Flutter',
                        onMessageReceived: (JavascriptMessage message) {
                          print(message.message);
                        },
                      ),
                    ].toSet(),
                    onPageStarted: (String url) {
                      print('Page started loading: $url');
                    },
                    onPageFinished: (String url) {
                      setState(() => isLoading = false);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
