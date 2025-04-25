import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

const String DEVICE_NAME = "StickBugsBLE";
const String SERVICE_UUID = "19b10000-e8f2-537e-4f6c-d104768a1214";
const String CHARACTERISTIC_UUID = "19b10001-e8f2-537e-4f6c-d104768a1214";
// Add new constant for temperature characteristic
const String TEMP_CHARACTERISTIC_UUID = "19b10002-e8f2-537e-4f6c-d104768a1214";

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'StickBug BLE Monitor',
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String humidityText = "Not connected";
  String temperatureText = "Not connected";  // Add this line
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    _initBLE();
  }

  Future<void> _initBLE() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name == DEVICE_NAME) {
          FlutterBluePlus.stopScan();
          await _connectToDevice(r.device);
          break;
        }
      }
    });
  }

  // ... keep other methods unchanged until _connectToDevice

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
    } catch (e) {
      // already connected
    }

    setState(() {
      connectedDevice = device;
    });

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == SERVICE_UUID) {
        for (var char in service.characteristics) {
          var charUuid = char.uuid.toString().toLowerCase();
          if (charUuid == CHARACTERISTIC_UUID) {
            // Initial humidity read
            var value = await char.read();
            _updateHumidity(value);

            // Subscribe to humidity updates
            await char.setNotifyValue(true);
            char.lastValueStream.listen((value) {
              _updateHumidity(value);
            });
          } else if (charUuid == TEMP_CHARACTERISTIC_UUID) {
            // Initial temperature read
            var value = await char.read();
            _updateTemperature(value);

            // Subscribe to temperature updates
            await char.setNotifyValue(true);
            char.lastValueStream.listen((value) {
              _updateTemperature(value);
            });
          }
        }
      }
    }
  }

  // Add new method for temperature updates
  void _updateTemperature(List<int> value) {
    if (value.length >= 4) {
      final byteData = ByteData.sublistView(Uint8List.fromList(value));
      double temperature = byteData.getFloat32(0, Endian.little);

      setState(() {
        temperatureText = "${temperature.toStringAsFixed(1)} °C";
      });
    } else {
      setState(() {
        temperatureText = "Invalid data";
      });
    }
  }

  void _updateHumidity(List<int> value) {
    if (value.length >= 4) {
      final byteData = ByteData.sublistView(Uint8List.fromList(value));
      double humidity = byteData.getFloat32(0, Endian.little);

      setState(() {
        humidityText = "${humidity.toStringAsFixed(1)} % RH";
      });
    } else {
      setState(() {
        humidityText = "Invalid data";
      });
    }
  }

  @override
  void dispose() {
    connectedDevice?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StickBug BLE Monitor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(humidityText, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 20),
            Text(temperatureText, style: const TextStyle(fontSize: 28)),  // Add this line
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (connectedDevice == null) {
                  _initBLE();
                } else {
                  connectedDevice!.disconnect();
                  setState(() {
                    humidityText = "Disconnected";
                    temperatureText = "Disconnected";  // Add this line
                    connectedDevice = null;
                  });
                }
              },
              child: Text(connectedDevice == null ? "Connect" : "Disconnect"),
            ),
          ],
        ),
      ),
    );
  }
}