import 'dart:io';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:linkify/linkify.dart';
import 'package:lotus_led_inventory/screens/inventory/download.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/try_catch.dart';
import '../../model/shared_prefs.dart';
import 'fitted_text.dart';
import 'quantity_list.dart';
import 'result.dart';

enum LinkOption {
  download,
  launch,
}

class Results extends StatefulWidget {
  final List<List<dynamic>> _filteredResults;

  Results(this._filteredResults);

  @override
  _ResultsState createState() => _ResultsState();
}

class _ResultsState extends State<Results>
    with AutomaticKeepAliveClientMixin<Results> {
  ScrollController _scrollController = ScrollController();
  bool _isScrollingDown;
  bool _isSelected;

  static const double SPACING = 7.0;

  @override
  void initState() {
    super.initState();
    _isScrollingDown = true;
    _isSelected = false;

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse ||
          _scrollController.position.pixels == 0.0) {
        setScrollDirection(true);
      } else {
        setScrollDirection(false);
      }
    });
  }

  void setScrollDirection(bool isScrollingDown) {
    if (_isScrollingDown != isScrollingDown) {
      setState(() {
        _isScrollingDown = isScrollingDown;
      });
    }
  }

  Widget _scrollToTopButton() {
    return Container(
      padding: EdgeInsets.all(5.0),
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: MaterialButton(
          onPressed: () {
            _scrollController.animateTo(
              0.0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          color: Colors.grey[300],
          textColor: Colors.black,
          child: Icon(
            Icons.arrow_upward,
            size: 24,
          ),
          padding: EdgeInsets.all(10.0),
          shape: CircleBorder(),
        ),
      ),
    );
  }

  String extractLink(String input) {
    List<LinkifyElement> elements = linkify(input.trim());
    String elink;

    for (var e in elements) {
      if (e is LinkableElement && elink == null) {
        elink = e.url;
      } else {
        return null;
      }
    }
    return elink;
  }

  Future<void> _activateLink(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final linkOption = prefs.getString(SharedPrefs.LINK_OPTION);

    switch (linkOption == null
        ? await showDialog<LinkOption>(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: Text(url),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.file_download),
                          title: Text(EnumToString.convertToString(
                            LinkOption.download,
                            camelCase: true,
                          )),
                          onTap: () {
                            Navigator.pop(context, LinkOption.download);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.launch),
                          title: Text(EnumToString.convertToString(
                            LinkOption.launch,
                            camelCase: true,
                          )),
                          onTap: () {
                            Navigator.pop(context, LinkOption.launch);
                          },
                        ),
                        Divider(),
                        CheckboxListTile(
                          value: _isSelected,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool newValue) {
                            setState(() {
                              _isSelected = newValue;
                            });
                          },
                          title: Text(
                            'Remember this choice '
                            'for all links in the "Home" screen',
                          ),
                        ),
                        Divider(),
                        Text(
                          'You can clear default settings '
                          'by using the "Clear defaults" button '
                          'in the "Settings" screen',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        : EnumToString.fromString(
            LinkOption.values,
            linkOption,
          )) {
      case LinkOption.download:
        if (_isSelected && linkOption == null) {
          await prefs.setString(
            SharedPrefs.LINK_OPTION,
            EnumToString.convertToString(LinkOption.download),
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(title: 'Downloader')),
        );
        break;
      case LinkOption.launch:
        if (_isSelected && linkOption == null) {
          await prefs.setString(
            SharedPrefs.LINK_OPTION,
            EnumToString.convertToString(LinkOption.launch),
          );
        }
        await TryCatch.open(context, url);
        break;
    }
  }

  Future<void> _download(String url) async {
    final _permissionReady = await _checkPermission();

    if (_permissionReady) {
      final _localPath =
          (await _findLocalPath()) + Platform.pathSeparator + 'Download';

      final savedDir = Directory(_localPath);
      bool hasExisted = await savedDir.exists();
      if (!hasExisted) {
        savedDir.create();
      }

      await FlutterDownloader.enqueue(
        url: url,
        savedDir: _localPath,
        showNotification: true,
        openFileFromNotification: true,
      );
    }
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<String> _findLocalPath() async {
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Colors.grey[200],
      child: Stack(
        children: <Widget>[
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: widget._filteredResults.length,
            itemBuilder: (context, index) {
              index += 1;
              if (index == widget._filteredResults.length) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 35.0),
                  child: Center(
                    child: Text(
                      'End of List',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                      ),
                    ),
                  ),
                );
              } else {
                bool cellsAreEmpty = FittedText(
                  widget._filteredResults,
                  row: index,
                ).checkIsEmpty();
                bool cell0IsEmpty = FittedText(
                  widget._filteredResults,
                  row: index,
                ).checkIsEmpty(
                  end: 1,
                );
                bool cell1IsEmpty = FittedText(
                  widget._filteredResults,
                  row: index,
                ).checkIsEmpty(
                  start: 1,
                  end: 2,
                );
                bool cell1HeaderIsEmpty = FittedText(
                  widget._filteredResults,
                  row: 0,
                ).checkIsEmpty(
                  start: 1,
                  end: 2,
                );
                bool cell2IsEmpty = FittedText(
                  widget._filteredResults,
                  row: index,
                ).checkIsEmpty(
                  start: 2,
                  end: 3,
                );
                bool cell3IsEmpty = FittedText(
                  widget._filteredResults,
                  row: index,
                ).checkIsEmpty(
                  start: 3,
                  end: 4,
                );
                bool cellsRestAreEmpty = FittedText(
                  widget._filteredResults,
                  row: index,
                ).checkIsEmpty(
                  start: 4,
                );
                String link = extractLink(
                  FittedText(
                    widget._filteredResults,
                    row: index,
                    column: 1,
                  ).fittedTextText(),
                );

                return InkWell(
                  onTap: () {
                    if (!cellsAreEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Result(
                            index,
                            widget._filteredResults,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 3.0,
                    shadowColor: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: SPACING / 2,
                        horizontal: SPACING,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          cell0IsEmpty && cell3IsEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: SPACING / 2,
                                  ),
                                  child: cell3IsEmpty
                                      ? FittedText(
                                          widget._filteredResults,
                                          row: index,
                                          column: 0,
                                          fontSize: 18.0,
                                          textAlign: TextAlign.left,
                                          fontWeight: FontWeight.w900,
                                        )
                                      : cell0IsEmpty
                                          ? FittedText(
                                              widget._filteredResults,
                                              row: index,
                                              column: 3,
                                              fontSize: 18.0,
                                              textAlign: TextAlign.right,
                                              fontWeight: FontWeight.w700,
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                Expanded(
                                                  child: FittedText(
                                                    widget._filteredResults,
                                                    row: index,
                                                    column: 0,
                                                    fontSize: 18.0,
                                                    textAlign: TextAlign.left,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                SizedBox(width: 10.0),
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.6,
                                                  ),
                                                  child: FittedText(
                                                    widget._filteredResults,
                                                    row: index,
                                                    column: 3,
                                                    fontSize: 18.0,
                                                    textAlign: TextAlign.right,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                ),
                          cell2IsEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: SPACING / 2,
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: FittedText(
                                            widget._filteredResults,
                                            row: index,
                                            column: 2,
                                          ).fittedTextText(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          cellsRestAreEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: SPACING / 2,
                                  ),
                                  child: QuantityList(
                                    index,
                                    widget._filteredResults,
                                  ),
                                ),
                          link == null && cell1IsEmpty
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: SPACING / 2,
                                  ),
                                  child: link == null || cell1HeaderIsEmpty
                                      ? RichText(
                                          text: TextSpan(
                                            style: DefaultTextStyle.of(context)
                                                .style,
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: FittedText(
                                                  widget._filteredResults,
                                                  row: index,
                                                  column: 1,
                                                ).fittedTextText(),
                                              ),
                                            ],
                                          ),
                                        )
                                      : InkWell(
                                          onTap: () async {
                                            await _activateLink(link);
                                          },
                                          child: Ink(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              vertical: SPACING / 2,
                                              horizontal: SPACING,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            child: Center(
                                              child: Tooltip(
                                                message: FittedText(
                                                  widget._filteredResults,
                                                  row: 0,
                                                  column: 1,
                                                ).fittedTextText(),
                                                child: Text(
                                                  FittedText(
                                                    widget._filteredResults,
                                                    row: 0,
                                                    column: 1,
                                                  ).fittedTextText(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          Visibility(
            child: _scrollToTopButton(),
            visible: !_isScrollingDown,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
