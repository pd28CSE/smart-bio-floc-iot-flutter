import 'package:flutter/material.dart';

import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:gauge_indicator/gauge_indicator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartBioFlocApp());
}

class SmartBioFlocApp extends StatelessWidget {
  const SmartBioFlocApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bio Floc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 58, 154, 183),
        ),
        // useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Smart Bio-floc'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final FirebaseDatabase realTimeDatabase;
  @override
  void initState() {
    realTimeDatabase = FirebaseDatabase.instance;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Center(
        child: RealTimeDataBuilder(realTimeDatabase: realTimeDatabase),
      ),
    );
  }
}

class RealTimeDataBuilder extends StatelessWidget {
  const RealTimeDataBuilder({
    super.key,
    required this.realTimeDatabase,
  });

  final FirebaseDatabase realTimeDatabase;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: realTimeDatabase.ref('users').onValue,
      builder: (
        BuildContext context,
        AsyncSnapshot<DatabaseEvent> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Transform.scale(
            scale: 2,
            child: const CircularProgressIndicator(),
          );
        } else if (snapshot.hasData == false) {
          return const Text('No data available.');
        } else if (snapshot.hasData == true) {
          final Map<dynamic, dynamic> data =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          return ListView(
            padding: const EdgeInsets.only(top: 10),
            children: <Widget>[
              _buildTemperatureMeter(
                  double.parse('${data['BUBT']['temperature']}')),
              const SizedBox(height: 20),
              pHBuildMeter(data['BUBT']['ph']),
              const SizedBox(height: 20),
              _buildWaterLevelMeter(
                  waterLevel: double.parse('${data['BUBT']['waterLevel']}')),
              const SizedBox(height: 20),
              _buildTDSMeter(double.parse(data['BUBT']['tds'].toString())),
            ],
          );
        }
        return const Text('Some thing is wrong!');
      },
    );
  }

  AnimatedRadialGauge _buildWaterLevelMeter({required double waterLevel}) {
    return AnimatedRadialGauge(
      duration: const Duration(seconds: 1),
      curve: Curves.decelerate,
      radius: 77,
      value: waterLevel,
      axis: const GaugeAxis(
        min: 0,
        max: 10,
        degrees: 360,
        style: GaugeAxisStyle(
          thickness: 15,
          background: Color(0xFFDFE2EC),
          segmentSpacing: 4,
        ),
        progressBar: GaugeProgressBar.basic(
          color: Color.fromARGB(255, 175, 189, 243),
          gradient: GaugeAxisGradient(
            colors: [
              Color.fromARGB(255, 170, 184, 241),
              Color.fromARGB(255, 87, 117, 235),
            ],
          ),
          placement: GaugeProgressPlacement.inside,
        ),
        segments: [
          GaugeSegment(
            from: 00,
            to: 100,
            color: Colors.white30,
            cornerRadius: Radius.zero,
          ),
        ],
      ),
      builder: (BuildContext cntxt, Widget? child, double value) {
        return Center(
          child: Text(
            'Water Level: ${(value * 10).toInt()}%',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  AnimatedRadialGauge _buildTemperatureMeter(double temperature) {
    return AnimatedRadialGauge(
      duration: const Duration(seconds: 1),
      curve: Curves.elasticOut,
      radius: 77,
      value: temperature,
      axis: GaugeAxis(
        min: 0,
        max: 100,
        degrees: 360,
        style: const GaugeAxisStyle(
          thickness: 15,
          background: Color(0xFFDFE2EC),
          segmentSpacing: 4,
        ),
        progressBar: GaugeProgressBar.rounded(
          gradient: GaugeAxisGradient(
            colors: <Color>[
              Colors.green.withOpacity(0.6),
              Colors.red,
              Colors.red,
            ],
            colorStops: const <double>[0.2, 0.6, 1],
            tileMode: TileMode.clamp,
          ),
          // color: Color.fromARGB(255, 133, 152, 228),
          placement: GaugeProgressPlacement.inside,
        ),
        segments: [
          GaugeSegment(
            from: 00,
            to: 100,
            // color: Colors.red.withOpacity(0.4),
            gradient: GaugeAxisGradient(
              colors: <Color>[
                Colors.green.withOpacity(0.6),
                Colors.red,
                Colors.red,
              ],
              colorStops: const <double>[0.2, 0.6, 1],
              tileMode: TileMode.clamp,
            ),
            cornerRadius: Radius.zero,
          ),
        ],
      ),
      builder: (BuildContext cntxt, Widget? child, double value) {
        return Center(
          child: Text(
            'Temperature: ${value.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget pHBuildMeter(double pHValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Transform.rotate(
          angle: -pi / 2,
          child: Image.network(
            'https://3.bp.blogspot.com/-6RP0IK53gus/XEilT9Wf8YI/AAAAAAAAH3M/2JCg40CzIPclNJRe0R_7e6fbqBk3srh3gCLcBGAs/s280/pH-scale.jpg',
            width: 180,
          ),
        ),
        AnimatedRadialGauge(
          duration: const Duration(seconds: 1),
          curve: Curves.elasticOut,
          radius: 60,
          value: pHValue,
          axis: GaugeAxis(
            min: 0,
            max: 14,
            degrees: 360,
            style: const GaugeAxisStyle(
              thickness: 15,
              background: Color(0xFFDFE2EC),
              segmentSpacing: 1,
              cornerRadius: Radius.zero,
            ),
            progressBar: const GaugeProgressBar.basic(
              color: Color.fromARGB(255, 133, 152, 228),
              placement: GaugeProgressPlacement.inside,
            ),
            segments: [
              const GaugeSegment(
                from: 0,
                to: 2,
                color: Colors.red,
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 2,
                to: 3,
                color: Colors.red.withOpacity(0.6),
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 3,
                to: 4,
                color: Colors.red.withOpacity(0.3),
                cornerRadius: Radius.zero,
              ),
              const GaugeSegment(
                from: 4,
                to: 5,
                color: Colors.yellow,
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 5,
                to: 6,
                color: Colors.yellow.withOpacity(0.7),
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 6,
                to: 7,
                color: Colors.yellow.withOpacity(0.5),
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 7,
                to: 8,
                color: Colors.yellow.withOpacity(0.3),
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 8,
                to: 9,
                color: Colors.blue.withOpacity(0.2),
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 9,
                to: 10,
                color: Colors.blue.withOpacity(0.5),
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 10,
                to: 11,
                color: Colors.blue.withOpacity(0.7),
                cornerRadius: Radius.zero,
              ),
              const GaugeSegment(
                from: 11,
                to: 12,
                color: Colors.blue,
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 12,
                to: 13,
                color: Colors.purple.withOpacity(0.5),
                cornerRadius: Radius.zero,
              ),
              const GaugeSegment(
                from: 13,
                to: 14,
                color: Colors.purple,
                cornerRadius: Radius.zero,
              ),
            ],
          ),
          builder: (BuildContext cntxt, Widget? child, double value) {
            final String tooltip = pHCondition(value);
            return Center(
              child: Tooltip(
                message: tooltip,
                child: Text(
                  'PH: ${value.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 20),
        Text(
          pHCondition(pHValue),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTDSMeter(double tdsValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          height: 80,
          width: 150,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    color: Colors.red.withOpacity(0.4),
                    height: 10,
                    width: 10,
                  ),
                  const SizedBox(width: 10),
                  const Text('Not good for drinking'),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    color: Colors.green,
                    height: 10,
                    width: 10,
                  ),
                  const SizedBox(width: 10),
                  const Text('Excellent for drinking'),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    color: Colors.green.withOpacity(0.6),
                    height: 10,
                    width: 10,
                  ),
                  const SizedBox(width: 10),
                  const Text('Good'),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    color: Colors.green.withOpacity(0.2),
                    height: 10,
                    width: 10,
                  ),
                  const SizedBox(width: 10),
                  const Text('Fair'),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    color: Colors.red,
                    height: 10,
                    width: 10,
                  ),
                  const SizedBox(width: 10),
                  const Text('Not good for drinking'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        AnimatedRadialGauge(
          duration: const Duration(seconds: 1),
          curve: Curves.elasticOut,
          radius: 60,
          value: tdsValue,
          axis: GaugeAxis(
            min: 0,
            max: 500,
            degrees: 360,
            style: const GaugeAxisStyle(
              thickness: 15,
              background: Color(0xFFDFE2EC),
              segmentSpacing: 4,
            ),
            progressBar: const GaugeProgressBar.rounded(
              color: Color.fromARGB(255, 133, 152, 228),
              placement: GaugeProgressPlacement.inside,
            ),
            segments: [
              GaugeSegment(
                from: 00,
                to: 50,
                color: Colors.red.withOpacity(0.4),
                cornerRadius: Radius.zero,
              ),
              const GaugeSegment(
                from: 50,
                to: 150,
                color: Colors.green,
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 150,
                to: 250,
                color: Colors.green.withOpacity(0.6),
                cornerRadius: Radius.zero,
              ),
              GaugeSegment(
                from: 250,
                to: 300,
                color: Colors.green.withOpacity(0.2),
                cornerRadius: Radius.zero,
              ),
              const GaugeSegment(
                from: 300,
                to: 500,
                color: Colors.red,
                cornerRadius: Radius.zero,
              ),
            ],
          ),
          builder: (BuildContext cntxt, Widget? child, double value) {
            // final String tooltip = getTDSWaterCondition(value);
            return Center(
              child: Text(
                'TDS: ${value.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: Text(
            getTDSWaterCondition(tdsValue),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        )
      ],
    );
  }

  String getTDSWaterCondition(double value) {
    if (value < 50) {
      return 'Not good for drinking';
    } else if (value < 150) {
      return 'Excellent for drinking';
    } else if (value < 250) {
      return 'Good';
    } else if (value < 300) {
      return 'Fair';
    } else {
      return 'Not good for drinking';
    }
  }

  String pHCondition(double value) {
    if (value < 7) {
      return 'Acidic';
    } else if (value < 8) {
      return 'Neutral';
    } else {
      return 'Alkaline';
    }
  }
}
