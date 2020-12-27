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
    return SafeArea(
      child: Container(
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

  Widget linkifiedDescription({
    @required int index,
    @required int column,
  }) {
    String link = extractLink(
      FittedText(
        widget._filteredResults,
        row: index,
        column: column,
      ).fittedTextText(),
    );
    return link == null &&
            FittedText(
              widget._filteredResults,
              row: index,
            ).checkIsEmpty(
              start: column,
              end: column + 1,
            )
        ? Container()
        : Padding(
            padding: EdgeInsets.symmetric(
              vertical: SPACING / 2,
            ),
            child: link == null ||
                    FittedText(
                      widget._filteredResults,
                      row: 0,
                    ).checkIsEmpty(
                      start: column,
                      end: column + 1,
                    )
                ? FittedText(
                    widget._filteredResults,
                    row: index,
                    column: column,
                    infiniteLines: true,
                  )
                : InkWell(
                    onTap: () async {
                      await TryCatch.open(context, link);
                    },
                    child: Ink(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: SPACING / 2,
                        horizontal: SPACING,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Center(
                        child: FittedText(
                          widget._filteredResults,
                          row: 0,
                          column: column,
                          fontWeight: FontWeight.w900,
                          textAlign: TextAlign.center,
                          textColor: Colors.white,
                          includeTooltipLabel: false,
                        ),
                      ),
                    ),
                  ),
          );
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
                          linkifiedDescription(
                            index: index,
                            column: 1,
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
                          linkifiedDescription(
                            index: index,
                            column: 2,
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
