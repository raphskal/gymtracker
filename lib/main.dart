import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() {
  runApp(GymProgressApp());
}

class GymProgressApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymProgress+',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ExerciseScreen(),
    );
  }
}

class ExerciseScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Tracker'),
      ),
      body: ExerciseList(),
    );
  }
}

class ExerciseList extends StatefulWidget {
  @override
  _ExerciseListState createState() => _ExerciseListState();
}

class _ExerciseListState extends State<ExerciseList> {
  List<String> exercises = ['Squats', 'Bench Press', 'Deadlifts'];
  TextEditingController customExerciseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: exercises.length + 1,
      itemBuilder: (context, index) {
        if (index == exercises.length) {
          return ListTile(
            title: TextField(
              controller: customExerciseController,
              decoration: InputDecoration(
                hintText: 'Add Custom Exercise',
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  String customExercise = customExerciseController.text.trim();
                  if (customExercise.isNotEmpty && !exercises.contains(customExercise)) {
                    exercises.add(customExercise);
                    customExerciseController.clear();
                  }
                });
              },
            ),
          );
        } else {
          return ListTile(
            title: Text(exercises[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(exercise: exercises[index]),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class ExerciseDetailScreen extends StatefulWidget {
  final String exercise;

  ExerciseDetailScreen({required this.exercise});

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  List<double> weights = [];
  List<int> reps = [];
  int sets = 3;
  List<double> weightHistory = [];
  List<int> repsHistory = [];
  List<DateTime> dates = [];

  TextEditingController weightController = TextEditingController();
  TextEditingController repsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  // Load progress data from SharedPreferences
  void _loadProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      List<String>? weightsString = prefs.getStringList('${widget.exercise}_weights');
      List<String>? repsString = prefs.getStringList('${widget.exercise}_reps');
      List<String>? datesString = prefs.getStringList('${widget.exercise}_dates');

      weights = weightsString?.map((weight) => double.parse(weight)).toList() ?? [];
      reps = repsString?.map((rep) => int.parse(rep)).toList() ?? [];
      dates = datesString?.map((date) => DateTime.parse(date)).toList() ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Set:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightController,
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // You can add validation if necessary
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: repsController,
                    decoration: InputDecoration(
                      labelText: 'Reps',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // You can add validation if necessary
                    },
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      double newWeight = double.tryParse(weightController.text.trim()) ?? 0.0;
                      int newReps = int.tryParse(repsController.text.trim()) ?? 0;
                      if (newWeight > 0 && newReps > 0) {
                        weights.add(newWeight);
                        reps.add(newReps);
                        weightHistory.add(newWeight);
                        repsHistory.add(newReps);
                        dates.add(DateTime.now());
                        weightController.clear();
                        repsController.clear();
                        _saveProgress();
                      }
                    });
                  },
                  child: Text('Add'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Sets:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              itemCount: weights.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                      'Set ${index + 1}: ${weights[index]} kg - ${reps[index]} reps - ${dates[index].toString().substring(0, 10)}'),
                );
              },
            ),
            SizedBox(height: 16),
            Text(
              'Analytics:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Best One-Rep Max per Day:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Container(
                height: 300,
                padding: EdgeInsets.all(8),
                child: _buildChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Save progress data to SharedPreferences
  void _saveProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('${widget.exercise}_weights', weights.map((weight) => weight.toString()).toList());
    await prefs.setStringList('${widget.exercise}_reps', reps.map((rep) => rep.toString()).toList());
    await prefs.setStringList(
        '${widget.exercise}_dates', dates.map((date) => date.toIso8601String()).toList());
  }

  // Function to build a line chart of progress
  Widget _buildChart() {
    List<charts.Series<ProgressData, DateTime>> series = [
      charts.Series(
        id: 'Progress',
        data: _generateData(),
        domainFn: (ProgressData data, _) => data.date,
        measureFn: (ProgressData data, _) => data.oneRepMax,
      ),
    ];

    return charts.TimeSeriesChart(
      series,
      animate: true,
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }

  // Function to generate data for the chart
  List<ProgressData> _generateData() {
    Map<DateTime, double> maxOneRepMaxPerDay = {};

    for (int i = 0; i < dates.length; i++) {
      DateTime currentDate = dates[i];
      double currentOneRepMax = weights[i] * (1 + (reps[i] / 30));
      if (!maxOneRepMaxPerDay.containsKey(currentDate) ||
          maxOneRepMaxPerDay[currentDate]! < currentOneRepMax) {
        maxOneRepMaxPerDay[currentDate] = currentOneRepMax;
      }
    }

    List<ProgressData> data = [];
    maxOneRepMaxPerDay.forEach((date, oneRepMax) {
      data.add(ProgressData(date: date, oneRepMax: oneRepMax));
    });

    return data;
  }
}

// Data model for progress
class ProgressData {
  final DateTime date;
  final double oneRepMax;

  ProgressData({required this.date, required this.oneRepMax});
}