import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:shared_preferences/shared_preferences.dart';

class ArduinoCloudService {
  // Arduino IoT Cloud API endpoints
  static const String _baseUrl = 'https://api2.arduino.cc/iot/v2';
  static const String _tokenUrl = 'https://api2.arduino.cc/iot/v1/clients/token';
  
  // Your Arduino IoT Cloud credentials
  // These should be stored securely in a production app
  static const String _clientId = 'YOUR_CLIENT_ID';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  
  // Your Arduino IoT Cloud Thing ID and property IDs
  static const String _thingId = 'YOUR_THING_ID';
  static const String _temperaturePropertyId = 'YOUR_TEMPERATURE_PROPERTY_ID';
  static const String _minTemperaturePropertyId = 'YOUR_MIN_TEMPERATURE_PROPERTY_ID';
  
  // OAuth2 client
  oauth2.Client? _client;
  
  // Singleton instance
  static final ArduinoCloudService _instance = ArduinoCloudService._internal();
  
  factory ArduinoCloudService() {
    return _instance;
  }
  
  ArduinoCloudService._internal();
  
  // Initialize the service and authenticate
  Future<bool> initialize() async {
    try {
      // Try to load saved credentials
      final client = await _loadCredentials();
      if (client != null) {
        _client = client;
        return true;
      }
      
      // If no saved credentials, authenticate
      return await authenticate();
    } catch (e) {
      print('Error initializing Arduino Cloud Service: $e');
      return false;
    }
  }
  
  // Authenticate with Arduino IoT Cloud
  Future<bool> authenticate() async {
    try {
      // Create credentials
      final credentials = oauth2.ClientCredentials(
        _clientId,
        _clientSecret,
      );
      
      // Get the OAuth2 client
      _client = await oauth2.clientCredentialsGrant(
        Uri.parse(_tokenUrl),
        _clientId,
        _clientSecret,
      );
      
      // Save the credentials
      await _saveCredentials(_client!);
      
      return true;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }
  
  // Save credentials to shared preferences
  Future<void> _saveCredentials(oauth2.Client client) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('arduino_cloud_credentials', client.credentials.toJson());
  }
  
  // Load credentials from shared preferences
  Future<oauth2.Client?> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsJson = prefs.getString('arduino_cloud_credentials');
    
    if (credentialsJson == null) {
      return null;
    }
    
    try {
      final credentials = oauth2.Credentials.fromJson(credentialsJson);
      
      // Check if credentials are expired
      if (credentials.isExpired) {
        return null;
      }
      
      return oauth2.Client(credentials);
    } catch (e) {
      print('Error loading credentials: $e');
      return null;
    }
  }
  
  // Get the current temperature
  Future<double?> getTemperature() async {
    if (_client == null) {
      final success = await initialize();
      if (!success) {
        return null;
      }
    }
    
    try {
      final response = await _client!.get(
        Uri.parse('$_baseUrl/things/$_thingId/properties/$_temperaturePropertyId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['last_value'].toDouble();
      } else {
        print('Error getting temperature: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting temperature: $e');
      return null;
    }
  }
  
  // Get the minimum temperature
  Future<double?> getMinTemperature() async {
    if (_client == null) {
      final success = await initialize();
      if (!success) {
        return null;
      }
    }
    
    try {
      final response = await _client!.get(
        Uri.parse('$_baseUrl/things/$_thingId/properties/$_minTemperaturePropertyId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['last_value'].toDouble();
      } else {
        print('Error getting min temperature: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting min temperature: $e');
      return null;
    }
  }
  
  // Set the minimum temperature
  Future<bool> setMinTemperature(double value) async {
    if (_client == null) {
      final success = await initialize();
      if (!success) {
        return false;
      }
    }
    
    try {
      final response = await _client!.put(
        Uri.parse('$_baseUrl/things/$_thingId/properties/$_minTemperaturePropertyId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'value': value,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting min temperature: $e');
      return false;
    }
  }
  
  // Get both temperature and min temperature
  Future<Map<String, double>?> getTemperatureData() async {
    final temperature = await getTemperature();
    final minTemperature = await getMinTemperature();
    
    if (temperature == null || minTemperature == null) {
      return null;
    }
    
    return {
      'temperature': temperature,
      'minTemperature': minTemperature,
    };
  }
}