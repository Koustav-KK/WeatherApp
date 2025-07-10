import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weather_app/bloc/weather_bloc_bloc.dart';
import 'package:weather_app/screens/home_screen.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FutureBuilder(
            future: _determinePosition(),
            builder: (context, snap) {
              if (snap.hasData) {
                print('Position data received: ${snap.data}');
                return BlocProvider<WeatherBlocBloc>(
                  create: (context) => WeatherBlocBloc()
                    ..add(FetchWeather(snap.data as Position)),
                  child: const HomeScreen(),
                );
              } else if (snap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: ${snap.error}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final position = await _determinePosition();
                          if (position != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BlocProvider<WeatherBlocBloc>(
                                  create: (context) => WeatherBlocBloc()
                                    ..add(FetchWeather(position)),
                                  child: const HomeScreen(),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            }));
  }
}

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Location services disabled');
    return Future.error('Please enable location services.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    print('Requesting location permission');
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error(
          'Location permissions were denied. Please enable them in settings.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Permissions denied forever');
    return Future.error(
        'Location permissions are permanently denied. Please enable them in settings.');
  }

  try {
    Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low)
        .timeout(Duration(seconds: 10));
    print('Position acquired: $position');
    return position;
  } catch (e) {
    print('Location fetch error: $e');
    return Future.error('Failed to get location: $e');
  }
}
