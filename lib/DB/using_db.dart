import 'package:flutter/material.dart';

class UsingDB extends StatefulWidget {
  UsingDB({Key? key}) : super(key: key);

  @override
  _UsingDBState createState() => _UsingDBState();
}

class _UsingDBState extends State<UsingDB> {
  @override
  Widget build(BuildContext context) {
    return Container(
       child: Expanded(child: Center(child: Text('Hola'),)),
    );
  }
}