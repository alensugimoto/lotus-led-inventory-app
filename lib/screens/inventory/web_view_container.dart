import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:webview_flutter/webview_flutter.dart' as js;

class WebViewContainer extends StatefulWidget {
  final bool isPicker;
  final String url;
  final String evaluatedJavascript;
  final List<JavascriptChannel> javascriptChannels;

  WebViewContainer({
    @required this.url,
    @required this.isPicker,
    this.evaluatedJavascript,
    this.javascriptChannels,
  });

  @override
  _WebViewContainerState createState() => _WebViewContainerState(this.url);
}

class _WebViewContainerState extends State<WebViewContainer> {
  //WebViewController _controller;
  String _url;
  int position;

  _WebViewContainerState(this._url);

  @override
  void initState() {
    super.initState();
    position = 1;
  }

  startLoading(String url) {
    if (position == 0) {
      setState(() => position = 1);
    }
  }

  doneLoading(String url) async {
    if (widget.isPicker && url == _url) {
      //await _controller.evaluateJavascript(widget.evaluatedJavascript);
    }
    if (position == 1) {
      setState(() => position = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      url: _url,
      withJavascript: true,
      userAgent: 'random',
      javascriptChannels: widget.javascriptChannels.toSet(),
    );
    return Scaffold(
      appBar: AppBar(),
      body: IndexedStack(
        index: position,
        children: [
          Column(
            children: [
              Expanded(
                // child: WebView(
                //   initialUrl: _url,
                //   userAgent: 'random',
                //   javascriptMode: JavascriptMode.unrestricted,
                //   onWebViewCreated: (WebViewController webViewController) {
                //     _controller = webViewController;
                //   },
                //   javascriptChannels: widget.isPicker
                //       ? widget.javascriptChannels.toSet()
                //       : null,
                //   onPageStarted: startLoading,
                //   onPageFinished: doneLoading,
                // ),
              ),
            ],
          ),
          Center(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
