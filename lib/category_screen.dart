import 'package:flutter/material.dart';
import 'package:flutterudacityapp/category.dart';
import 'package:flutterudacityapp/unit.dart';

const _backgroundColor = Color.fromRGBO(0, 40, 140, 30);

class CategoryRoute extends StatelessWidget {

  const CategoryRoute();

  static const _categoryNames = <String>[
    'Length',
    'Area',
    'Volume',
    'Mass',
    'Time',
    'Digital Storage',
    'Energy',
    'Currency',
  ];

  static const _baseColors = <Color>[
    Colors.teal,
    Colors.orange,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.yellow,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.red,
  ];

  List<Unit> _retrieveUnitList(String categoryName) {
    return List.generate(10, (int i) {
      i += 1;
      return Unit(name: "$categoryName Unit $i", conversion: i.toDouble());
    });
  }
  
  Widget _categoryWidgets(List<Widget> categoriesList) {
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) => categoriesList[index],
      itemCount: categoriesList.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = <Category>[];

    for(var i = 0; i < _categoryNames.length; i++) {
      categories.add(Category(
        name: _categoryNames[i],
        color: _baseColors[i],
        categoryHeight: 100.0,
        iconLocation: Icons.access_alarm,
        units: _retrieveUnitList(_categoryNames[i]),
      ));
    }

    final listView = Container(
      color: _backgroundColor,
      padding: EdgeInsets.symmetric(horizontal : 8.0),
      child: _categoryWidgets(categories),
    );

    final appBar = AppBar(
      elevation: 0.0,
      backgroundColor: _backgroundColor,
      title: Text('Unit Converter',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26.0
        ),
      ),
      centerTitle: true,
    );

    return Scaffold(
      appBar: appBar,
      body: listView,
    );
  }
}