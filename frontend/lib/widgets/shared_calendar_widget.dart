import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class SharedCalendarWidget extends StatefulWidget {
  final Map<DateTime, List<EventModel>> eventsMap;
  final bool isReadOnly;
  final bool showHeaderLabel;
  final bool useCard;
  final Function(EventModel) onEventTap;

  const SharedCalendarWidget({
    Key? key,
    required this.eventsMap,
    this.isReadOnly = false,
    required this.onEventTap,
    this.showHeaderLabel = true,
    this.useCard = true,
  }) : super(key: key);

  @override
  State<SharedCalendarWidget> createState() => _SharedCalendarWidgetState();
}

class _SharedCalendarWidgetState extends State<SharedCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String _calendarViewMode = 'Bulan';

  double _timeToDouble(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hours = double.parse(parts[0]);
        final minutes = double.parse(parts[1]);
        return hours + (minutes / 60.0);
      }
    } catch (e) {}
    return 0.0;
  }

  List<double> _parseTimeRange(String timeStr) {
    try {
      final parts = timeStr.split('-');
      final start = _timeToDouble(parts[0].trim());
      double end = start + 1.0;
      if (parts.length > 1) {
        end = _timeToDouble(parts[1].trim());
        if (end <= start) end = start + 1.0;
      }
      return [start, end];
    } catch (e) {
      return [0.0, 1.0];
    }
  }

  Color _getEventColor(String id) {
    final colors = [
      const Color(0xFF1A73E8), // Blue
      const Color(0xFFD93025), // Red
      const Color(0xFF188038), // Green
      const Color(0xFFF29900), // Yellow
      const Color(0xFF8E24AA), // Purple
      const Color(0xFFE67C73), // Light Red
    ];
    return colors[id.hashCode.abs() % colors.length];
  }

  Widget _buildMonthEventList() {
    final Map<String, EventModel> monthEvents = {};
    widget.eventsMap.forEach((date, events) {
      if (date.month == _focusedDay.month && date.year == _focusedDay.year) {
        for (var event in events) {
          monthEvents[event.id] = event;
        }
      }
    });

    final sortedEvents = monthEvents.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedEvents.isEmpty) return const SizedBox();

    final monthNames = [
      'januari', 'februari', 'maret', 'april', 'mei', 'juni',
      'juli', 'agustus', 'september', 'oktober', 'november', 'desember'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedEvents.map((event) {
          String dateStr;
          final startMonth = monthNames[event.date.month - 1];
          if (event.date.year == event.endDate.year &&
              event.date.month == event.endDate.month &&
              event.date.day == event.endDate.day) {
            dateStr = '${event.date.day} $startMonth: ';
          } else if (event.date.year == event.endDate.year &&
              event.date.month == event.endDate.month) {
            dateStr = '${event.date.day}-${event.endDate.day} $startMonth: ';
          } else {
            final endMonth = monthNames[event.endDate.month - 1];
            dateStr = '${event.date.day} $startMonth - ${event.endDate.day} $endMonth: ';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthCell(DateTime day, List<EventModel> events, {bool isToday = false, bool isOutside = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFE0F2FE) : (isOutside ? const Color(0xFFF8FAFC) : Colors.white),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 4),
            child: Text(
              '${day.day}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isOutside ? const Color(0xFF94A3B8) : (isToday ? const Color(0xFF1A73E8) : const Color(0xFF0F172A)),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: events.map((event) {
                final color = _getEventColor(event.id);
                
                final bool isStart = isSameDay(day, event.date);
                final bool isEnd = isSameDay(day, event.endDate);
                final bool isMultiDay = !isSameDay(event.date, event.endDate);
                
                final bool connectLeft = isMultiDay && !isStart;
                final bool connectRight = isMultiDay && !isEnd;

                return InkWell(
                  onTap: () => widget.onEventTap(event),
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: 2,
                      left: connectLeft ? 0 : 2,
                      right: connectRight ? 0 : 2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.horizontal(
                        left: connectLeft ? Radius.zero : const Radius.circular(4),
                        right: connectRight ? Radius.zero : const Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      connectLeft ? ' ' : event.name,
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView() {
    const double hourHeight = 60.0;
    DateTime startOfWeek = _focusedDay.subtract(Duration(days: _focusedDay.weekday % 7));
    
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: List.generate(7, (index) {
                      final day = startOfWeek.add(Duration(days: index));
                      final isToday = day.year == DateTime.now().year && day.month == DateTime.now().month && day.day == DateTime.now().day;
                      return Expanded(
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE', 'en_US').format(day).toUpperCase(),
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFF1A73E8) : Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isToday ? const Color(0xFF1A73E8) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(fontSize: 14, color: isToday ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Column(
                      children: List.generate(24, (index) {
                        if (index == 0) return const SizedBox(height: hourHeight);
                        final hour = index;
                        final displayHour = hour > 12 ? hour - 12 : hour;
                        final amPm = hour >= 12 ? 'PM' : 'AM';
                        return SizedBox(
                          height: hourHeight,
                          child: Center(
                            child: Text(
                              '$displayHour $amPm',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(7, (colIndex) {
                        final currentDay = startOfWeek.add(Duration(days: colIndex));
                        final dateKey = DateTime(currentDay.year, currentDay.month, currentDay.day);
                        final dayEvents = widget.eventsMap[dateKey] ?? [];
                        return Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1.0)),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  children: List.generate(24, (index) {
                                    return Container(
                                      height: hourHeight,
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                ...dayEvents.map((e) {
                                  final range = _parseTimeRange(e.time);
                                  final color = _getEventColor(e.id);
                                  return Positioned(
                                    top: range[0] * hourHeight,
                                    height: (range[1] - range[0]) * hourHeight,
                                    left: 0,
                                    right: 2,
                                    child: InkWell(
                                      onTap: () => widget.onEventTap(e),
                                      child: Container(
                                        margin: const EdgeInsets.only(top: 1, bottom: 1),
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.2),
                                          border: Border(left: BorderSide(color: color, width: 3)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          e.name,
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaView() {
    final Set<EventModel> uniqueEvents = {};
    for (var list in widget.eventsMap.values) {
      uniqueEvents.addAll(list);
    }
    
    final sortedEvents = uniqueEvents.toList()
      ..sort((a, b) {
        int dateCmp = a.date.compareTo(b.date);
        if (dateCmp != 0) return dateCmp;
        return _timeToDouble(a.time).compareTo(_timeToDouble(b.time));
      });

    if (sortedEvents.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Tidak ada event mendatang.')),
      );
    }
    
    final List<MapEntry<String, List<EventModel>>> groupedList = [];
    for (var event in sortedEvents) {
      String key = '${event.date.year}-${event.date.month}-${event.date.day}_${event.endDate.year}-${event.endDate.month}-${event.endDate.day}';
      
      bool found = false;
      for (var group in groupedList) {
        if (group.key == key) {
          group.value.add(event);
          found = true;
          break;
        }
      }
      if (!found) {
        groupedList.add(MapEntry(key, [event]));
      }
    }
    
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedList.length,
        itemBuilder: (context, index) {
          final group = groupedList[index];
          final events = group.value;
          final representativeEvent = events.first;
          
          final date = representativeEvent.date;
          final endDate = representativeEvent.endDate;
          final bool isMultiDay = !isSameDay(date, endDate);
          
          final monthNames = [
            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
            'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
          ];
          final dayNames = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MING'];
          
          final startMonth = monthNames[date.month - 1].toUpperCase();
          final endMonth = monthNames[endDate.month - 1].toUpperCase();

          String dayStr;
          String dayOfWeekStr = dayNames[date.weekday - 1];

          if (isMultiDay) {
            String endDayOfWeekStr = dayNames[endDate.weekday - 1];
            dayOfWeekStr = '$dayOfWeekStr - $endDayOfWeekStr';
            
            if (date.month == endDate.month) {
              dayStr = '${date.day}-${endDate.day}\n$startMonth';
            } else {
              dayStr = '${date.day} $startMonth\n-\n${endDate.day} $endMonth';
            }
          } else {
            dayStr = '${date.day}\n$startMonth';
          }
          
          final bool isToday = isSameDay(date, DateTime.now()) || 
             (date.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now().subtract(const Duration(days: 1))));

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayOfWeekStr,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayStr,
                        style: TextStyle(
                          fontSize: dayStr.contains('-') && dayStr.contains(' ') ? 14 : (dayStr.contains('-') ? 18 : 22), 
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: isToday 
                            ? const Color(0xFF1A73E8) 
                            : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: events.map((event) {
                      final color = _getEventColor(event.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => widget.onEventTap(event),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(
                                  event.time,
                                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(left: BorderSide(color: color, width: 4)),
                                  ),
                                  child: Text(
                                    event.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearView() {
    final year = _focusedDay.year;
    final months = List.generate(12, (index) => index + 1);
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year - 1, _focusedDay.month, 1)),
                ),
                Text(
                  year.toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year + 1, _focusedDay.month, 1)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = months[index];
                
                final firstDayOfMonth = DateTime(year, month, 1);
                final daysInMonth = DateUtils.getDaysInMonth(year, month);
                final firstWeekday = firstDayOfMonth.weekday;
                final offset = firstWeekday == 7 ? 0 : firstWeekday;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(year, month, 1);
                      _calendarViewMode = 'Bulan';
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          monthNames[index],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: month == DateTime.now().month && year == DateTime.now().year ? const Color(0xFF1A73E8) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((dayChar) {
                          return Expanded(
                            child: Center(
                              child: Text(dayChar, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: 42,
                          itemBuilder: (context, dayIndex) {
                            if (dayIndex < offset || dayIndex >= offset + daysInMonth) {
                              return const SizedBox();
                            }
                            final dayNumber = dayIndex - offset + 1;
                            final dateKey = DateTime(year, month, dayNumber);
                            final hasEvent = widget.eventsMap.containsKey(dateKey) && widget.eventsMap[dateKey]!.isNotEmpty;
                            final isToday = dateKey.year == DateTime.now().year && dateKey.month == DateTime.now().month && dateKey.day == DateTime.now().day;
                            
                            return Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isToday ? const Color(0xFF1A73E8) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$dayNumber',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: hasEvent ? FontWeight.bold : FontWeight.normal,
                                        color: isToday ? Colors.white : (hasEvent ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                                      ),
                                    ),
                                    if (hasEvent && !isToday)
                                      Container(
                                        width: 3,
                                        height: 3,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFAC282C),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final date = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final events = widget.eventsMap[date] ?? [];
    const double hourHeight = 60.0;
    
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 20),
                        onPressed: () => setState(() => _selectedDay = _selectedDay!.subtract(const Duration(days: 1))),
                      ),
                      Column(
                        children: [
                          Text(
                            DateFormat('EEE', 'en_US').format(_selectedDay!).toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A73E8),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${_selectedDay!.day}',
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 20),
                        onPressed: () => setState(() => _selectedDay = _selectedDay!.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Column(
                      children: List.generate(24, (index) {
                        if (index == 0) return const SizedBox(height: hourHeight);
                        final hour = index;
                        final displayHour = hour > 12 ? hour - 12 : hour;
                        final amPm = hour >= 12 ? 'PM' : 'AM';
                        return SizedBox(
                          height: hourHeight,
                          child: Center(
                            child: Text(
                              '$displayHour $amPm',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: List.generate(24, (index) {
                            return Container(
                              height: hourHeight,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                                ),
                              ),
                            );
                          }),
                        ),
                        ...events.map((e) {
                          final range = _parseTimeRange(e.time);
                          final startHour = range[0];
                          final endHour = range[1];
                          final color = _getEventColor(e.id);
                          return Positioned(
                            top: startHour * hourHeight,
                            height: (endHour - startHour) * hourHeight,
                            left: 0,
                            right: 8,
                            child: InkWell(
                              onTap: () => widget.onEventTap(e),
                              child: Container(
                                margin: const EdgeInsets.only(top: 1, bottom: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  border: Border(left: BorderSide(color: color, width: 4)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  e.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    if (_calendarViewMode == 'Event') {
      return _buildAgendaView();
    } else if (_calendarViewMode == 'Tahun') {
      return _buildYearView();
    } else if (_calendarViewMode == 'Hari') {
      return _buildDayView();
    } else if (_calendarViewMode == 'Minggu') {
      return _buildWeekView();
    }

    return Expanded(
      child: SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar<EventModel>(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                rowHeight: 70, // Shortened height from 90
                availableGestures: AvailableGestures.none,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) => _buildMonthCell(day, widget.eventsMap[DateTime(day.year, day.month, day.day)] ?? []),
                  todayBuilder: (context, day, focusedDay) => _buildMonthCell(day, widget.eventsMap[DateTime(day.year, day.month, day.day)] ?? [], isToday: true),
                  outsideBuilder: (context, day, focusedDay) => _buildMonthCell(day, widget.eventsMap[DateTime(day.year, day.month, day.day)] ?? [], isOutside: true),
                  selectedBuilder: (context, day, focusedDay) => _buildMonthCell(day, widget.eventsMap[DateTime(day.year, day.month, day.day)] ?? []),
                ),
              ),
              _buildMonthEventList(),
            ],
          ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.showHeaderLabel)
                  Row(
                    children: [
                      const Icon(Icons.event_note, size: 20, color: Color(0xFFAC282C)),
                      const SizedBox(width: 8),
                      Text(
                        'Schedule Event',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(),
                PopupMenuButton<String>(
                  initialValue: _calendarViewMode,
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  elevation: 6,
                  color: Colors.white,
                  onSelected: (String newValue) {
                    setState(() {
                      _calendarViewMode = newValue;
                    });
                  },
                  itemBuilder: (context) => ['Event', 'Hari', 'Minggu', 'Bulan', 'Tahun']
                      .map((value) => PopupMenuItem<String>(
                            value: value,
                            padding: EdgeInsets.zero,
                            child: _FilterMenuItem(
                              label: value,
                              isSelected: value == _calendarViewMode,
                            ),
                          ))
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _calendarViewMode,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
        _buildCalendarContent(),
      ],
    );

    if (widget.useCard) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: contentWidget,
      );
    } else {
      return contentWidget;
    }
  }
}

class _FilterMenuItem extends StatefulWidget {
  final String label;
  final bool isSelected;

  const _FilterMenuItem({required this.label, required this.isSelected});

  @override
  State<_FilterMenuItem> createState() => _FilterMenuItemState();
}

class _FilterMenuItemState extends State<_FilterMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFFAC282C).withValues(alpha: 0.1)
              : _hovered
                  ? const Color(0xFFAC282C).withValues(alpha: 0.06)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (widget.isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_rounded, size: 14, color: Color(0xFFAC282C)),
              ),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                color: widget.isSelected
                    ? const Color(0xFFAC282C)
                    : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
