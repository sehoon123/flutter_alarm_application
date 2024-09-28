// lib/screens/alarm_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:alarmshare/widgets/sound_selection_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmDetailScreen extends StatefulWidget {
  final String alarmType; // 'Wake-up' or 'Bedtime'
  final TimeOfDay initialTime;
  final List<String> initialDays;
  final String initialSound;
  final bool initialVibration;
  final int initialSnoozeDuration;
  final Function(TimeOfDay, List<String>, String, bool, int) onSave;

  const AlarmDetailScreen({
    super.key,
    required this.alarmType,
    required this.initialTime,
    required this.initialDays,
    required this.initialSound,
    required this.initialVibration,
    required this.initialSnoozeDuration,
    required this.onSave,
  });

  @override
  _AlarmDetailScreenState createState() => _AlarmDetailScreenState();
}

class _AlarmDetailScreenState extends State<AlarmDetailScreen> {
  late TimeOfDay selectedTime;
  late List<String> selectedDays;
  late String selectedSound;
  late bool vibrationEnabled;
  late int snoozeDuration; // in minutes

  final List<int> snoozeOptions = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
    selectedDays = List.from(widget.initialDays);
    selectedSound = widget.initialSound;
    vibrationEnabled = widget.initialVibration;
    snoozeDuration = widget.initialSnoozeDuration;
  }

  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.alarmType} 알람 설정'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(selectedTime, selectedDays, selectedSound,
                  vibrationEnabled, snoozeDuration);
              Navigator.pop(context);
            },
            child: const Text(
              '저장',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Time Picker
            ListTile(
              title: const Text('시간 설정'),
              subtitle: Text(
                selectedTime.format(context),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (pickedTime != null) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                }
              },
            ),
            const Divider(),
            // Day Selection
            ListTile(
              title: const Text('반복 요일'),
              subtitle: Wrap(
                spacing: 10.0,
                children: days.map((day) {
                  bool isSelected = selectedDays.contains(day);
                  return ChoiceChip(
                    label: Text(day),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            // Sound Selection
            ListTile(
              title: const Text('알람 소리'),
              subtitle: Text(selectedSound),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                String? sound = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SoundSelectionWidget(
                      initialSound: selectedSound,
                    ),
                  ),
                );
                if (sound != null) {
                  setState(() {
                    selectedSound = sound;
                  });
                }
              },
            ),
            const Divider(),
            // Vibration Toggle
            SwitchListTile(
              title: const Text('진동'),
              value: vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  vibrationEnabled = value;
                });
              },
            ),
            const Divider(),
            // Snooze Duration
            ListTile(
              title: const Text('스누즈 지속 시간'),
              subtitle: DropdownButton<int>(
                value: snoozeDuration,
                items: snoozeOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value 분'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      snoozeDuration = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
