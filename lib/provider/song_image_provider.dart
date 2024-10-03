import 'package:flutter/foundation.dart';

class SongImageProvider with ChangeNotifier {
  int _id = 0;
  String _artUri = ''; // Artwork URI

  int get id => _id;
  String get artUri => _artUri;

  void setId(int id) {
    if (_id != id) {
      _id = id;
      _updateArtUri(id); // Update only if the ID changes
      notifyListeners(); // Notify listeners only when the ID actually changes
    }
  }

  // Simulate fetching artwork URI based on song ID
  void _updateArtUri(int id) {
    // Example: Replace with your actual logic to fetch artwork URI
    _artUri = 'https://example.com/albumart$id.jpg'; // Example URI
  }
}
