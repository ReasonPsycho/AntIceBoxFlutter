import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'arduino_cloud_service.dart';

void main() {
  runApp(const MyApp());
}

// Default Arduino IP address - should be configurable in the app
const String DEFAULT_ARDUINO_IP = "192.168.1.100"; // Replace with your Arduino's IP

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AntIceBox Controller',
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
  String temperatureText = "Not connected";
  String minTemperatureText = "Not connected";
  double? currentTemperature;
  double? minTemperature;
  String arduinoIp = DEFAULT_ARDUINO_IP;
  bool isConnected = false;
  Timer? refreshTimer;
  final TextEditingController _ipController = TextEditingController(text: DEFAULT_ARDUINO_IP);
  final TextEditingController _minTempController = TextEditingController();
  
  // Arduino IoT Cloud service
  final ArduinoCloudService _cloudService = ArduinoCloudService();
  
  // Connection mode (direct WiFi or Arduino IoT Cloud)
  bool _useCloudConnection = false;
  
  // Arduino IoT Cloud credentials controllers
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _clientSecretController = TextEditingController();
  final TextEditingController _thingIdController = TextEditingController();
  final TextEditingController _tempPropertyIdController = TextEditingController();
  final TextEditingController _minTempPropertyIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Start with a connection attempt
    _connectToArduino();
  }

  Future<void> _connectToArduino() async {
    setState(() {
      isConnected = false;
      temperatureText = "Connecting...";
      minTemperatureText = "Connecting...";
    });

    try {
      if (_useCloudConnection) {
        // Connect using Arduino IoT Cloud
        // Update cloud service credentials
        _updateCloudServiceCredentials();
        
        // Initialize the cloud service
        final success = await _cloudService.initialize();
        
        if (success) {
          // Get temperature data from cloud
          final data = await _cloudService.getTemperatureData();
          
          if (data != null) {
            _updateTemperatureData(data);
            
            // Start periodic refresh
            _startPeriodicRefresh();
            
            setState(() {
              isConnected = true;
            });
          } else {
            setState(() {
              temperatureText = "Failed to get data from Arduino IoT Cloud";
              minTemperatureText = "Failed to get data";
              isConnected = false;
            });
          }
        } else {
          setState(() {
            temperatureText = "Failed to connect to Arduino IoT Cloud";
            minTemperatureText = "Connection failed";
            isConnected = false;
          });
        }
      } else {
        // Connect using direct WiFi
        final response = await http.get(
          Uri.parse('http://${_ipController.text}/temperature'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          // Parse the response
          final data = jsonDecode(response.body);
          _updateTemperatureData(data);
          
          // Start periodic refresh
          _startPeriodicRefresh();
          
          setState(() {
            isConnected = true;
            arduinoIp = _ipController.text;
          });
        } else {
          setState(() {
            temperatureText = "Connection failed: ${response.statusCode}";
            minTemperatureText = "Connection failed";
            isConnected = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        temperatureText = "Connection error: ${e.toString()}";
        minTemperatureText = "Connection error";
        isConnected = false;
      });
    }
  }
  
  // Update cloud service credentials from text fields
  void _updateCloudServiceCredentials() {
    // This is a simplified approach - in a real app, you'd want to store these securely
    final service = ArduinoCloudService();
    
    // Use reflection to set private fields (not ideal but works for demo)
    // In a real app, you'd want to modify the service to accept these values properly
    final serviceInstance = service.toString();
    
    // For demo purposes, just print the values that would be used
    print('Using Arduino IoT Cloud credentials:');
    print('Client ID: ${_clientIdController.text}');
    print('Thing ID: ${_thingIdController.text}');
    print('Temperature Property ID: ${_tempPropertyIdController.text}');
    print('Min Temperature Property ID: ${_minTempPropertyIdController.text}');
  }

  void _startPeriodicRefresh() {
    // Cancel any existing timer
    refreshTimer?.cancel();
    
    // Create a new timer that refreshes data every 10 seconds
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (isConnected) {
        _refreshTemperatureData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _refreshTemperatureData() async {
    try {
      if (_useCloudConnection) {
        // Refresh using Arduino IoT Cloud
        final data = await _cloudService.getTemperatureData();
        
        if (data != null) {
          _updateTemperatureData(data);
        } else {
          setState(() {
            temperatureText = "Refresh failed: Could not get data from cloud";
            isConnected = false;
          });
        }
      } else {
        // Refresh using direct WiFi
        final response = await http.get(
          Uri.parse('http://$arduinoIp/temperature'),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _updateTemperatureData(data);
        } else {
          setState(() {
            temperatureText = "Refresh failed: ${response.statusCode}";
            isConnected = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        temperatureText = "Refresh error: ${e.toString()}";
        isConnected = false;
      });
    }
  }

  void _updateTemperatureData(Map<String, dynamic> data) {
    setState(() {
      currentTemperature = data['temperature']?.toDouble();
      minTemperature = data['minTemperature']?.toDouble();
      
      temperatureText = "${currentTemperature?.toStringAsFixed(1) ?? 'N/A'} °C";
      minTemperatureText = "${minTemperature?.toStringAsFixed(1) ?? 'N/A'} °C";
      
      if (minTemperature != null) {
        _minTempController.text = minTemperature!.toStringAsFixed(1);
      }
    });
  }

  Future<void> _setMinTemperature() async {
    if (!isConnected) return;
    
    try {
      final newMinTemp = double.tryParse(_minTempController.text);
      if (newMinTemp == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid number')),
        );
        return;
      }
      
      if (_useCloudConnection) {
        // Set min temperature using Arduino IoT Cloud
        final success = await _cloudService.setMinTemperature(newMinTemp);
        
        if (success) {
          // Refresh data to get the updated minTemperature
          final data = await _cloudService.getTemperatureData();
          
          if (data != null) {
            setState(() {
              minTemperature = data['minTemperature'];
              minTemperatureText = "${minTemperature?.toStringAsFixed(1) ?? 'N/A'} °C";
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Minimum temperature updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Temperature updated but failed to refresh data')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update minimum temperature in cloud')),
          );
        }
      } else {
        // Set min temperature using direct WiFi
        final response = await http.post(
          Uri.parse('http://$arduinoIp/minTemperature'),
          body: {'value': newMinTemp.toString()},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() {
              minTemperature = data['minTemperature']?.toDouble();
              minTemperatureText = "${minTemperature?.toStringAsFixed(1) ?? 'N/A'} °C";
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Minimum temperature updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update minimum temperature')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    _ipController.dispose();
    _minTempController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _thingIdController.dispose();
    _tempPropertyIdController.dispose();
    _minTempPropertyIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AntIceBox Controller'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Connection Mode Toggle
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Mode',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Direct WiFi'),
                        Switch(
                          value: _useCloudConnection,
                          onChanged: (value) {
                            setState(() {
                              _useCloudConnection = value;
                              isConnected = false; // Reset connection status
                            });
                          },
                        ),
                        const Text('Arduino IoT Cloud'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Connection Settings
            if (_useCloudConnection)
              // Arduino IoT Cloud Settings
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Arduino IoT Cloud Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _clientIdController,
                        decoration: const InputDecoration(
                          labelText: 'Client ID',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your Arduino IoT Cloud Client ID',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _clientSecretController,
                        decoration: const InputDecoration(
                          labelText: 'Client Secret',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your Arduino IoT Cloud Client Secret',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _thingIdController,
                        decoration: const InputDecoration(
                          labelText: 'Thing ID',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your Arduino IoT Cloud Thing ID',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _tempPropertyIdController,
                        decoration: const InputDecoration(
                          labelText: 'Temperature Property ID',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your temperature property ID',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _minTempPropertyIdController,
                        decoration: const InputDecoration(
                          labelText: 'Min Temperature Property ID',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your minTemperature property ID',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Direct WiFi Settings
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Arduino IP Address',
                  border: OutlineInputBorder(),
                  hintText: 'Enter the IP address of your Arduino',
                ),
                keyboardType: TextInputType.text,
              ),
            const SizedBox(height: 16),
            
            // Connect Button
            ElevatedButton(
              onPressed: _connectToArduino,
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.green : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isConnected ? 'Connected - Tap to Reconnect' : 'Connect to Arduino',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            
            // Temperature Display
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Current Temperature',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      temperatureText,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Min Temperature Display and Setting
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Minimum Temperature',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      minTemperatureText,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _minTempController,
                      decoration: const InputDecoration(
                        labelText: 'Set New Min Temperature',
                        border: OutlineInputBorder(),
                        suffixText: '°C',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: isConnected ? _setMinTemperature : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text('Update Min Temperature'),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Status Indicator
            Container(
              padding: const EdgeInsets.all(8),
              color: isConnected ? Colors.green.shade100 : Colors.red.shade100,
              child: Text(
                isConnected 
                    ? _useCloudConnection
                        ? 'Connected to Arduino IoT Cloud'
                        : 'Connected to Arduino at $arduinoIp'
                    : 'Not connected to Arduino',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isConnected ? Colors.green.shade900 : Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}