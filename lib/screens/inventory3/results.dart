import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'fitted_text.dart';
import 'quantity_list.dart';
import '../../model/sheet.dart';

class Results extends StatefulWidget {
  final List<Map<String, String>> _filteredResults;
  final AsyncSnapshot<Sheet> _snapshot;

  Results(this._filteredResults, this._snapshot);

  @override
  ResultsState createState() => ResultsState();
}

class ResultsState extends State<Results> {
  ScrollController _scrollController = ScrollController();
  bool _onTop;

  @override
  void initState() {
    super.initState();
    _onTop = true;

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == 0.0) {
        setScrollPosition(true);
      } else {
        setScrollPosition(false);
      }
    });
  }

  void setScrollPosition(bool onTop) {
    if (_onTop != onTop) {
      setState(() {
        _onTop = onTop;
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
              duration: Duration(seconds: 1),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: <Widget>[
          ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: widget._filteredResults.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                      )),
                ),
                padding: EdgeInsets.all(5.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          flex: 3,
                          child: FittedText(
                            widget._filteredResults[index]
                            [widget._snapshot.data.headers[0]]
                                .isEmpty
                                ? 'Unknown model number'
                                : widget._filteredResults[index]
                            [widget._snapshot.data.headers[0]],
                            fontSize: 18.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Flexible(
                          flex: 1,
                          child: FittedText(
                            widget._filteredResults[index]
                            [widget._snapshot.data.headers[1]]
                                .isEmpty
                                ? ''
                                : double.tryParse(widget._filteredResults[index]
                            [widget._snapshot.data.headers[1]]) ==
                                null
                                ? '\$ ?'
                                : '\$' +
                                NumberFormat("#,##0.00", "en_US").format(
                                    double.tryParse(widget._filteredResults[index]
                                    [widget
                                        ._snapshot.data.headers[1]])),
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    QuantityList(
                        index, widget._filteredResults, widget._snapshot.data.headers),
                  ],
                ),
              );
            },
          ),
          Visibility(
            child: _scrollToTopButton(),
            visible: !_onTop,
          ),
        ],
      ),
    );
  }
}
