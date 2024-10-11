// /lib/widgets/sound_selection_widget.dart

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SoundSelectionWidget extends StatefulWidget {
  final String initialSound;

  const SoundSelectionWidget({super.key, required this.initialSound});

  @override
  _SoundSelectionWidgetState createState() => _SoundSelectionWidgetState();
}

class _SoundSelectionWidgetState extends State<SoundSelectionWidget> {
  final List<String> sounds = [
    'marimba.mp3',
    'nokia.mp3',
    'one_piece.mp3',
    'star_wars.mp3',
    'mozart.mp3',
    // Add your sound file names here
  ];

  late String selectedSound;
  AudioPlayer audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    selectedSound = widget.initialSound;
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  void playSound(String sound) async {
    await audioPlayer.stop();
    await audioPlayer.play(
      AssetSource('sounds/$sound'),
      volume: 1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알람 소리 선택'),
      ),
      body: ListView.builder(
        itemCount: sounds.length,
        itemBuilder: (context, index) {
          String sound = sounds[index];
          bool isSelected = selectedSound == sound;
          return ListTile(
            title: Text(sound),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    playSound(sound);
                  },
                  child: const Text('미리듣기'),
                ),
                Radio<String>(
                  value: sound,
                  groupValue: selectedSound,
                  onChanged: (value) {
                    setState(() {
                      selectedSound = value!;
                    });
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          audioPlayer.stop();
          Navigator.pop(context, selectedSound);
        },
      ),
    );
  }
}
