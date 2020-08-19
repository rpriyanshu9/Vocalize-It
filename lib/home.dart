import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pdf_text/pdf_text.dart';
import 'package:vocalize_it/loading.dart';
import 'package:vocalize_it/player_widget.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  PDFDoc _pdfDoc;
  int indexX = 0;
  bool loading = false;
  String text = "";
  String fileName = "";
  var voices = [
    'English (Australia)-FEMALE',
    'English (India)-FEMALE',
    'English (India)-MALE',
    'English (UK)-MALE',
    'English (US)-FEMALE'
  ];
  var _currentItemSelected = '';

  @override
  void initState() {
    super.initState();
    _currentItemSelected = voices[0];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Vocalize It'),
          ),
          body: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: ListView(
              children: <Widget>[
                RaisedButton(
                  elevation: 5.0,
                  child: Text(
                    "Pick PDF document",
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blueAccent,
                  onPressed: () {
                    setState(() => loading = true);
                    _pickPDFText();
                  },
                  padding: EdgeInsets.all(5),
                ),
                Padding(
                  child: Column(
                    children: <Widget>[
                      _pdfDoc == null
                          ? Text("Pick pdf file and wait for it to load",
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,)
                          : Text(
                              "PDF document loaded, ${_pdfDoc.length} page(s)",
                              style: TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            ),loading ? Padding(padding: EdgeInsets.only(top: 20.0),
                            child: Loading(),) : Text(""),
                    ],
                  ),
                  padding: EdgeInsets.all(15),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Choose voice:",
                        style: TextStyle(
                            fontSize: 17.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    DropdownButton<String>(
                      items: voices.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: _currentItemSelected,
                      onChanged: (String newValue) {
                        setState(() {
                          _currentItemSelected = newValue;
                          indexX = voices.indexOf(newValue);
                        });
                      },
                    ),
                  ],
                ),
                Padding(padding: EdgeInsets.only(top: 15.0)),
                myPlayerWidget(text, indexX),
                Container(
                  padding: EdgeInsets.only(top: 15.0),
                  child: (text != "")
                      ? Text(
                          text,
                          style: TextStyle(color: Colors.black, fontSize: 20.0),
                        )
                      : Text(""),
                )
              ],
            ),
          )),
    );
  }

  Future _pickPDFText() async {
    File file = await FilePicker.getFile();
    _pdfDoc = await PDFDoc.fromFile(file);
    if (_pdfDoc == null) {
      return;
    }
    String text2 = await _pdfDoc.text;
    String fileName2 = file.path.split('/').last;

    setState(() {
      loading=false;
      text = text2;
      fileName = fileName2;
    });
  }

  Widget myPlayerWidget(String myText, int idx) {
    if (text != "") {
      return PlayerWidget(
        text: myText,
        index: idx,
        fileName: fileName,
      );
    } else {
      return Text("");
    }
  }
}