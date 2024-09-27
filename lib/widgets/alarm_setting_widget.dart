import 'package:flutter/material.dart';

class AlarmSettingWidget extends StatelessWidget {
  final String title;
  final TimeOfDay time;
  final bool isEnabled;
  final List<String> selectedDays;
  final Function(TimeOfDay) onTimeChanged;
  final Function(bool) onToggleChanged;
  final Function(List<String>) onDaysChanged;

  AlarmSettingWidget({
    required this.title,
    required this.time,
    required this.isEnabled,
    required this.selectedDays,
    required this.onTimeChanged,
    required this.onToggleChanged,
    required this.onDaysChanged,
  });

  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isEnabled ? Colors.purple[700] : Colors.grey[800],
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            trailing: Switch(
              value: isEnabled,
              activeColor: Colors.purple,
              onChanged: onToggleChanged,
            ),
          ),
          GestureDetector(
            onTap: () async {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (pickedTime != null) {
                onTimeChanged(pickedTime);
              }
            },
            child: Text(
              time.format(context),
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: days.map((day) {
              bool isSelected = selectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  List<String> newSelectedDays = List.from(selectedDays);
                  if (isSelected) {
                    newSelectedDays.remove(day);
                  } else {
                    newSelectedDays.add(day);
                  }
                  onDaysChanged(newSelectedDays);
                },
                child: Container(
                  margin: EdgeInsets.all(4.0),
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.purple : Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
