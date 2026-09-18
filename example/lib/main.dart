import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import 'demo.dart';
import 'equations.dart';
import 'feature.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Math Demo v0.2.0',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            body: SelectionArea(
              child: Column(
                children: [
                  const Text('Phương trình:'),
                  SelectableMath.tex(
                    r'x^2 + 2x + 1 = 0',
                    selectionText: r'$x^2 + 2x + 1 = 0$',
                  ),
                  const Text('Đây là một phương trình bậc hai.'),
                ],
              ),
            ),
          ),
        ),
      );
}
