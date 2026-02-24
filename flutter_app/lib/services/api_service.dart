class ApiService {
  // ============================================
  // CONFIGURE YOUR PRODUCTION URL HERE
  // Uncomment and set your deployed backend URL:
  // static const String productionUrl = 'https://your-app.onrender.com';
  // ============================================
  
  // Base URL - change this for your deployment
  static String get baseUrl {
    // For production, uncomment below and comment out the rest:
    // return productionUrl;
    
    if (kIsWeb) {
      // For web, use relative path (same origin)
      return '';
    } else if (Platform.isAndroid) {
      // For Android emulator
      return 'http://10.0.2.2:3000';
    } else {
      // For iOS simulator or desktop
      return 'http://localhost:3000';
    }
  }
