import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List _todoList = [];
  TextEditingController _taskController = TextEditingController();
  Map<String, dynamic> _lastRemoved = {};
  int _lastRemovedPos = 0;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _todoList = jsonDecode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title:
              const Text('TO-DO List', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      decoration: const InputDecoration(
                          hintText: 'Nova Tarefa',
                          labelText: 'Nova Tarefa',
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _addTask,
                    child: const Text('ADD',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 10.0),
                    itemCount: _todoList.length,
                    itemBuilder: buildItem,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        onChanged: (value) {
          setState(() {
            _todoList[index]["ok"] = value;
            // _saveFile(jsonEncode(_todoList));
          });
        },
        activeColor: Colors.blueAccent,
        checkColor: Colors.white,
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.info_outline,
              color: Colors.white),
          backgroundColor: Colors.blueAccent,
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = _todoList[index];
          _lastRemovedPos = index;
          _todoList.removeAt(index);
          _saveData(jsonEncode(_todoList));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 2),
            content: Text('Tarefa \"${_lastRemoved["title"]}\"Removida'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData(jsonEncode(_todoList));
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      Map<String, dynamic> newTask = {
        "title": _taskController.text,
        "ok": false
      };
      setState(() {
        _todoList.add(newTask);
        _taskController.clear();
      });
      _saveData(jsonEncode(_todoList));
    }
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData(String text) async {
    String data = jsonEncode(_todoList);
    final file = await _getFile();
    return file.writeAsString(text);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort(
        (a, b) {
          if (a["ok"] && !b["ok"])
            return 1;
          else if (!a["ok"] && b["ok"])
            return -1;
          else
            return 0;
        },
      );
      _saveData(jsonEncode(_todoList));
    });
  }
}
