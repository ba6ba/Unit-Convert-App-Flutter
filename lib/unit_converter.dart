import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:UnitConverterApp/api.dart';
import 'package:UnitConverterApp/category.dart';
import 'package:UnitConverterApp/unit.dart';

const _padding = EdgeInsets.all(16.0);

class UnitConverter extends StatefulWidget {
  final Category category;

  const UnitConverter({@required this.category}) : assert(category != null);

  @override
  _UnitConverterState createState() => _UnitConverterState();
}

class _UnitConverterState extends State<UnitConverter> {
  Unit _fromValue;
  Unit _toValue;
  double _inputValue;
  String _outputValue = '';
  List<DropdownMenuItem> _dropDownMenuItems = List();
  bool _showValidationError = false;
  final _inputKey = GlobalKey(debugLabel: 'InputText');
  bool _showErrorUI = false;

  @override
  void initState() {
    super.initState();
    _createDropDownMenuItems();
    _setDefaults();
  }

  @override
  void didUpdateWidget(UnitConverter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.category != widget.category) {
      _createDropDownMenuItems();
      _setDefaults();
    }
  }

  void _createDropDownMenuItems() {
    var newItems = <DropdownMenuItem>[];
    for (var unit in widget.category.units) {
      newItems.add(DropdownMenuItem(
        value: unit.name,
        child: Container(
          child: Text(
            unit.name,
            softWrap: true,
          ),
        ),
      ));
    }
    setState(() {
      _dropDownMenuItems = newItems;
    });
  }

  void _setDefaults() {
    setState(() {
      _fromValue = widget.category.units[0];
      _toValue = widget.category.units[1];
    });
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  /// Clean up conversion; trim trailing zeros, e.g. 5.500 -> 5.5, 10.0 -> 10
  String format(double conversion) {
    var outputNum = conversion.toStringAsPrecision(7);
    if (outputNum.contains('.') && outputNum.endsWith('0')) {
      var i = outputNum.length - 1;
      while (outputNum[i] == '0') {
        i -= 1;
      }
      outputNum = outputNum.substring(0, i + 1);
    }
    if (outputNum.endsWith('.')) {
      return outputNum.substring(0, outputNum.length - 1);
    }
    return outputNum;
  }

  Future<void> _updateConversion() async{
    // Our API has a handy convert function, so we can use that for
    // the Currency [Category]
    if(widget.category.name == apiCategory['name']) {
      final api = Api();
      final conversion = await api.convert(apiCategory['route'], _inputValue.toString(),
          _fromValue.name, _toValue.name);
      if(conversion == null) {
        setState(() {
          _showErrorUI = true;
        });
      }
      else {
        setState(() {
          _showErrorUI = false;
          _outputValue = format(conversion);
        });
      }
    }
    else {
      setState(() {
        _outputValue =
            format(_inputValue * (_toValue.conversion / _fromValue.conversion));
      });
    }
  }

  void _updateInputValue(String input) {
    setState(() {
      if (input == null || input.isEmpty) {
        _outputValue = '';
      } else {
        try {
          final inputInDouble = double.parse(input);
          _showValidationError = false;
          _inputValue = inputInDouble;
          _updateConversion();
        } on Exception catch (e) {
          print('Error: $e');
          _showValidationError = true;
        }
      }
    });
  }

  Unit _getUnit(String unitName) {
    return widget.category.units.firstWhere((Unit unit) {
      return unit.name == unitName;
    }, orElse: null);
  }

  void _updateFromConversion(dynamic unitName) {
    setState(() {
      _fromValue = _getUnit(unitName);
    });
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  void _updateToConversion(dynamic unitName) {
    setState(() {
      _toValue = _getUnit(unitName);
    });
    if (_inputValue != null) {
      _updateConversion();
    }
  }

  Widget _createDropDown(String currentValue, ValueChanged<dynamic> onChanged) {
    return Container(
      margin: EdgeInsets.only(top: 16.0),
      decoration: BoxDecoration(
        color: widget.category.color['background'],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.black, width: 1.0),
      ),
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.white),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton(
              value: currentValue,
              items: _dropDownMenuItems,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.title,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(widget.category.units == null
        || (widget.category.name == apiCategory['name'] && _showErrorUI)) {
      return showError();
    }

    final converter = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[inputWidget(), arrows(), outputWidget()],
      ),
    );

    return Padding(
      padding: _padding,
      child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          if (Orientation.portrait == orientation) {
            return converter;
          } else {
            return Center(
              child: Container(
                width: 450.0,
                child: converter,
              ),
            );
          }
        },
      ),
    );
  }

  Widget showError() {
    return SingleChildScrollView(
      child: Container(
        margin: _padding,
        padding: _padding,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.white
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              child: Icon(
                Icons.error_outline,
                size: 80.0,
                color: Colors.red,
              ),
              padding: _padding,
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Text(
                "Oh no! Something went wrong!",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.subhead.apply(
                    color: Colors.red,
                    fontFamily: 'DroidSans-Bold'
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget inputWidget() {
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: _inputKey,
            style: Theme.of(context).textTheme.headline.apply(
                color: Colors.black
            ),
            decoration: InputDecoration(
                labelStyle: Theme.of(context).textTheme.title,
                errorText: _showValidationError ? 'Invalid number entered' : null,
                labelText: 'Input',
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.black,
                        width: 1.0
                    ),
                    borderRadius: BorderRadius.circular(16.0)
                ),
                focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.red,
                        width: 1.0
                    ),
                    borderRadius: BorderRadius.circular(16.0)
                ),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.0),
                    borderRadius: BorderRadius.circular(16.0))),
            keyboardType: TextInputType.number,
            onChanged: _updateInputValue,
          ),
          _createDropDown(_fromValue.name, _updateFromConversion)
        ],
      ),
    );
  }

  Widget arrows() {
    return RotatedBox(
      quarterTurns: 1,
      child: Icon(
        Icons.compare_arrows,
        size: 30.0,
        color: Colors.black,
      ),
    );
  }

  Widget outputWidget() {
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InputDecorator(
            child: Text(
              _outputValue,
              style: Theme.of(context).textTheme.headline.apply(
                  color: Colors.black
              ),
            ),
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 1.0, color: Colors.black),
                  borderRadius: BorderRadius.circular(16.0)),
              labelText: 'Output',
              labelStyle: Theme.of(context).textTheme.title.apply(
                  color: Colors.black
              ),
            ),
          ),
          _createDropDown(_toValue.name, _updateToConversion)
        ],
      ),
    );
  }
}
