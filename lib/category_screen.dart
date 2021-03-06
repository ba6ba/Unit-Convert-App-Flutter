import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:UnitConverterApp/api.dart';
import 'package:UnitConverterApp/backdrop.dart';
import 'package:UnitConverterApp/category.dart';
import 'package:UnitConverterApp/category_tile.dart';
import 'package:UnitConverterApp/unit.dart';
import 'package:UnitConverterApp/unit_converter.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen();

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _categories = <Category>[];
  Category _defaultCategory;
  Category _currentCategory;

  static const _icons = <String>[
    'assets/icons/length.png',
    'assets/icons/area.png',
    'assets/icons/volume.png',
    'assets/icons/mass.png',
    'assets/icons/time.png',
    'assets/icons/digital_storage.png',
    'assets/icons/power.png',
    'assets/icons/currency.png',
  ];

  static const _baseColors = <ColorSwatch>[
    ColorSwatch(0xFF6AB7A8, {
      'highlight': Color(0xFF6AB7A8),
      'splash': Color(0xFF0ABC9B),
      'background': Color(0xFFE0FFF9),
    }),
    ColorSwatch(0xFFFFD28E, {
      'highlight': Color(0xFFFFD28E),
      'splash': Color(0xFFFFA41C),
      'background': Color(0xFFFFF1DB),
    }),
    ColorSwatch(0xFFFFB7DE, {
      'highlight': Color(0xFFFFB7DE),
      'splash': Color(0xFFF94CBF),
      'background': Color(0xFFFFE6DF),
    }),
    ColorSwatch(0xFF8899A8, {
      'highlight': Color(0xFF8899A8),
      'splash': Color(0xFFA9CAE8),
      'background': Color(0xFFBADEFF),
    }),
    ColorSwatch(0xFFEAD37E, {
      'highlight': Color(0xFFEAD37E),
      'splash': Color(0xFFFFE070),
      'background': Color(0xFFFFF1BD),
    }),
    ColorSwatch(0xFF81A56F, {
      'highlight': Color(0xFF81A56F),
      'splash': Color(0xFF7CC159),
      'background': Color(0xFFD6FFC2),
    }),
    ColorSwatch(0xFFD7C0E2, {
      'highlight': Color(0xFFD7C0E2),
      'splash': Color(0xFFCA90E5),
      'background': Color(0xFFD7C0E2),
    }),
    ColorSwatch(0xFFCE9A9A, {
      'highlight': Color(0xFFCE9A9A),
      'splash': Color(0xFFF94D56),
      'background': Color(0xFFE999A3),
      'error': Color(0xFF912D2D),
    }),
  ];

  @override
  Future<Void> didChangeDependencies() async {
    super.didChangeDependencies();
    // We have static unit conversions located in our
    // assets/data/regular_units.json
    if(_categories.isEmpty) {
      await _retrieveLocalCategories();
      await _retrieveApiCategory();
    }
  }
  /// Retrieves a [Category] and its [Unit]s from an API on the web
  Future<List> _retrieveApiCategory() async {
    setState(() {
      _categories.add(getApiCategory(List(0)));
    });

    final api = Api();
    final jsonUnits = await api.getUnits(apiCategory['route']);
    // If the API errors out or we have no internet connection, this category
    // remains in placeholder mode (disabled)
    if(jsonUnits != null) {
      final units = <Unit>[];
      for(var unit in jsonUnits) {
        units.add(Unit.fromJson(unit));
      }
      setState(() {
        _categories.removeLast();
        _categories.add(getApiCategory(units));
      });
    }
  }

  Category getApiCategory(List<Unit> units) {
    return Category(
        name: apiCategory['name'],
        units: units,
        color: _baseColors.last,
        iconLocation: _icons.last,
        categoryHeight: 100.0
    );
  }

  /// Retrieves a list of [Categories] and their [Unit]s
  Future<Void> _retrieveLocalCategories() async {
    // Consider omitting the types for local variables. For more details on Effective
    // Dart Usage, see https://www.dartlang.org/guides/language/effective-dart/usage
    final json = DefaultAssetBundle
        .of(context)
        .loadString('assets/data/regular_units.json');
    final data = JsonDecoder().convert(await json);
    if (data is! Map) {
      throw ('Data retrieved from API is not a Map');
    }
    var categoryIndex = 0;
    data.keys.forEach((key) {
      final List<Unit> units =
      data[key].map<Unit>((dynamic data) => Unit.fromJson(data)).toList();

      var category = Category(
        categoryHeight: 100.0,
        name: key,
        units: units,
        color: _baseColors[categoryIndex],
        iconLocation: _icons[categoryIndex],
      );
      setState(() {
        if (categoryIndex == 0) {
          _defaultCategory = category;
        }
        _categories.add(category);
      });
      categoryIndex += 1;
    });
  }

  /// Function to call when a [Category] is tapped.
  void _onCategoryTap(Category category) {
    setState(() {
      _currentCategory = category;
    });
  }

  Widget _categoryWidgets(Orientation deviceOrientation) {
    if(Orientation.portrait == deviceOrientation) {
      return ListView.separated(
        itemBuilder: (BuildContext context, int index) {
          var category = _categories[index];
          return CategoryTile(
            category: category,
            onTap: category.name == apiCategory['name'] && category.units
                .isEmpty ? null : _onCategoryTap,
          );
        },
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 12,
          );
        },
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        physics: BouncingScrollPhysics(),
        itemCount: _categories.length,
      );
    }
    else {
      return GridView.count(
          crossAxisCount: 2,
        childAspectRatio: 3.0,
        children: _categories.map((Category category) {
            return Container(
              padding: EdgeInsets.all(5.0),
              child: CategoryTile(
                category: category,
                onTap: category.name == apiCategory['name'] && category.units
                    .isEmpty ? null : _onCategoryTap,
              ),
            );
      }).toList(),
        physics: BouncingScrollPhysics(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_categories.isEmpty) {
      return Center(
        child: Container(
          width: 180.0,
          height: 180.0,
          child: CircularProgressIndicator(),
        ),
      );
    }
    assert(debugCheckHasMediaQuery(context));
    final listView = Padding(
      padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 48.0),
      child: _categoryWidgets(MediaQuery.of(context).orientation),
    );
    return Backdrop(
      currentCategory:
          _currentCategory == null ? _defaultCategory : _currentCategory,
      frontPanel: _currentCategory == null
          ? UnitConverter(
              category: _defaultCategory,
            )
          : UnitConverter(
              category: _currentCategory,
            ),
      backPanel: listView,
      frontTitle: Text('Unit Converter'),
      backTitle: Text('Select a category'),
    );
  }
}
