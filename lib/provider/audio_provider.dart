import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AudioProvider extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  SongModel? currentSong;
  bool isPlaying = false;

  // Play a song
  Future<void> playSong(SongModel song) async {
    try {
      await audioPlayer.setAudioSource(AudioSource.uri(
        Uri.file(song.data),
        tag: MediaItem(
          id: song.id.toString(),
          album: song.album ?? 'Unknown Album',
          title: song.displayNameWOExt,
          artUri: Uri.parse(song.id.toString()),
        ),
      ));
      await audioPlayer.play();
      currentSong = song;
      isPlaying = true;
      notifyListeners();
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  // Toggle play/pause
  void togglePlayPause() async {
    if (audioPlayer.playing) {
      await audioPlayer.pause();
      isPlaying = false;
      notifyListeners();
    } else {
      await audioPlayer.play();
      isPlaying = true;
      notifyListeners();
    }
    notifyListeners();
  }

  // Stop playback
  void stop() async {
    await audioPlayer.stop();
    isPlaying = false;
    notifyListeners();
  }

  // Getter for current song's position
  Duration get position => audioPlayer.position;

  // Getter for current song's duration
  Duration? get duration => audioPlayer.duration;

  // Seek to a specific position in the song
  Future<void> seekTo(Duration position) async {
    await audioPlayer.seek(position);
    notifyListeners();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
