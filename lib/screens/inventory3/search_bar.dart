import 'package:flutter/material.dart';

class SearchBar extends StatefulWidget {
  final int _flex;
  final String _prefix;
  final String _initial;
  final bool _hasDropdown;

  SearchBar(this._flex, this._prefix, this._initial, this._hasDropdown);

  @override
  SearchBarState createState() => SearchBarState();
}

class SearchBarState extends State<SearchBar> {

  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  static OverlayEntry _overlayEntry;
  static bool overlayIsRemoved = true;
  static bool focusIsThrown = false;
  List<String> items = [];
  String filter;

  @override
  void initState() {
    super.initState();
    textController.text = widget._initial;
    items.add("Apple");
    items.add("Bananas");
    items.add("Milk");
    items.add("Water");

    if (widget._hasDropdown) {
      textController.addListener(_textListener);
      focusNode.addListener(_textListener);
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void _textListener() {
    setState(() {
      filter = textController.text.toLowerCase().replaceAll(' ', '');
    });
    if (focusNode.hasFocus) {
      if (!overlayIsRemoved) {
        removeOverlay();
      }
      if (filter.isNotEmpty) {
        insertOverlay();
      }
      focusIsThrown = false;
    } else if (!overlayIsRemoved && !focusIsThrown) {
      removeOverlay();
    }
  }

  void _throwFocus() {
    FocusScopeNode currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild.unfocus();
    }
    focusIsThrown = true;
  }

  void insertOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry);
    overlayIsRemoved = false;
  }

  static void removeOverlay() {
    _overlayEntry.remove();
    overlayIsRemoved = true;
    focusIsThrown = false;
  }

  OverlayEntry _createOverlayEntry() {

    RenderBox renderBox = context.findRenderObject();
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5.0,
        bottom: 10.0,
        width: size.width,
        child: Material(
          elevation: 4.0,
          child: NotificationListener(
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return items[index].toLowerCase().contains(filter) ? Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                      )
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      textController.text = items[index];
                      removeOverlay();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(7.0),
                      child: Text(
                        items[index],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ) : Container();
              },
            ),
            onNotification: (notificationInfo) {
              if (notificationInfo is ScrollStartNotification) {
                _throwFocus();
              }
              return true;
            },
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: widget._flex,
      child: TextFormField(
        focusNode: focusNode,
        controller: textController,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.all(15.0),
            child: Text('${widget._prefix}: '),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          contentPadding: EdgeInsets.all(10.0),
        ),
      ),
    );
  }
}
