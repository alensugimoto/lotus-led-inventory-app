import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:linkify/linkify.dart';

import '../../model/try_catch.dart';
import 'fitted_text.dart';
import 'quantity_list.dart';
import 'result.dart';

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

  static const double SPACING = 7.0;

  @override
  void initState() {
    super.initState();
    _isScrollingDown = true;

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
    var elements = linkify(input,
        options: LinkifyOptions(
          humanize: false,
        ));
    for (var e in elements) {
      if (e is LinkableElement) {
        return e.url;
      }
    }
    return null;
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
                String link = cell1IsEmpty
                    ? null
                    : extractLink(
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
                          cell1IsEmpty || link == null
                              ? Container()
                              : Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: SPACING / 2,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    height: 30.0,
                                    padding: EdgeInsets.symmetric(
                                      vertical: SPACING / 2,
                                      horizontal: SPACING,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),
                                    child: Center(
                                      child: Tooltip(
                                        message: "SPEC SHEET",
                                        child: Text(
                                          "SPEC SHEET",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
