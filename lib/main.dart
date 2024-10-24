import 'package:flutter/material.dart';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  List<Fish> fishList = [];
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..addListener(() {
        setState(() {
          for (var fish in fishList) {
            fish.updatePosition();
          }
        });
      });
    _controller!.repeat();
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  void _addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  void _saveSettings() async {
    final db = await openDatabase(join(await getDatabasesPath(), 'aquarium.db'));
    await db.insert('settings', {
      'fishCount': fishList.length,
      'speed': selectedSpeed,
      'color': selectedColor.value,
    });
  }

  void _changeSpeed(double newSpeed) {
    setState(() {
      selectedSpeed = newSpeed;
    });
  }

  void _checkForCollision(Fish fish1, Fish fish2) {
    if ((fish1.position.dx - fish2.position.dx).abs() < 20 &&
        (fish1.position.dy - fish2.position.dy).abs() < 20) {
      fish1.changeDirection();
      fish2.changeDirection();
      setState(() {
        fish1.color = Random().nextBool() ? Colors.blue : Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Virtual Aquarium')),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Stack(children: fishList.map((fish) => fish.buildFish()).toList()),
          ),
          Row(
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              ElevatedButton(onPressed: _saveSettings, child: Text('Save Settings')),
            ],
          ),
          Row(
            children: [
              Text('Speed:'),
              Slider(value: selectedSpeed, min: 0.1, max: 2.0, onChanged: _changeSpeed),
            ],
          ),
          Row(
            children: [
              Text('Color:'),
              DropdownButton<Color>(
                value: selectedColor,
                items: [Colors.red, Colors.blue, Colors.green]
                    .map((color) => DropdownMenuItem(value: color, child: Container(color: color, width: 24, height: 24)))
                    .toList(),
                onChanged: (color) => setState(() => selectedColor = color!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Fish {
  Color color;
  final double speed;
  Offset position = Offset(0, 0);
  Random random = Random();
  double dx = 1;
  double dy = 1;
  final double fishSize = 20;
  final double containerWidth = 300;
  final double containerHeight = 300;

  Fish({required this.color, required this.speed}) {
    dx = random.nextDouble() * 2 - 1;
    dy = random.nextDouble() * 2 - 1;
  }

  void updatePosition() {
    double newX = position.dx + dx * speed;
    double newY = position.dy + dy * speed;

    if (newX < 0 || newX + fishSize > containerWidth) {
      dx = -dx;
      newX = position.dx + dx * speed;
    }

    if (newY < 0 || newY + fishSize > containerHeight) {
      dy = -dy;
      newY = position.dy + dy * speed;
    }

    position = Offset(newX, newY);
  }

  void changeDirection() {
    dx = -dx;
    dy = -dy;
  }

  Widget buildFish() {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Container(
        width: fishSize,
        height: fishSize,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
