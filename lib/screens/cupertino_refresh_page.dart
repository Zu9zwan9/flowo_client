import 'package:flutter/cupertino.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AnimatedCalendarPage extends StatefulWidget {
  const AnimatedCalendarPage({super.key});

  @override
  State<AnimatedCalendarPage> createState() => _AnimatedCalendarPageState();
}

class _AnimatedCalendarPageState extends State<AnimatedCalendarPage> {
  final _calendarController = CalendarController();
  DateTime _selectedDate = DateTime.now();
  bool _isCalendarVisible = false;
  bool _isPullingDown = false;

  List<int> items = List.generate(10, (index) => index);

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      items.shuffle();
    });
  }

  void _handlePull(double offset) {
    // Show calendar when pulling down far enough
    if (offset > 120 && !_isCalendarVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isCalendarVisible = true;
        });
      });
    }
  }

  void _toggleCalendarVisibility() {
    setState(() {
      _isCalendarVisible = !_isCalendarVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Pull to Show Calendar'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Button to toggle the calendar visibility
            Padding(
              padding: const EdgeInsets.only(top: 10.0, right: 10),
              child: Align(
                alignment: Alignment.topRight,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _toggleCalendarVisibility,
                  child: Icon(
                    _isCalendarVisible ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            ),

            // Animated calendar at the top
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: child,
                );
              },
              child: _isCalendarVisible
                  ? SfCalendar(
                key: const ValueKey('calendar'),
                view: CalendarView.month,
                controller: _calendarController,
                initialSelectedDate: _selectedDate,
                initialDisplayDate: _selectedDate,
                onSelectionChanged: (details) {
                  if (details.date != null && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedDate = details.date!;
                      });
                    });
                  }
                },
                showNavigationArrow: true,
                allowViewNavigation: false,
                headerStyle: const CalendarHeaderStyle(
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
                monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                  showAgenda: false,
                  monthCellStyle: MonthCellStyle(
                    textStyle: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 14,
                    ),
                    todayTextStyle: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    backgroundColor: CupertinoColors.transparent,
                    todayBackgroundColor: Color(0x1A007AFF),
                  ),
                ),
                todayHighlightColor: CupertinoColors.activeBlue,
                selectionDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Color(0x33007AFF),
                  border: Border.all(
                    color: CupertinoColors.activeBlue,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),

            // EasyRefresh content below
            Expanded(
              child: EasyRefresh(
                onRefresh: _onRefresh,
                header: BuilderHeader(
                  triggerOffset: 80.0,
                  clamping: false,
                  position: IndicatorPosition.above,
                  builder: (context, state) {
                    _handlePull(state.offset);
                    return Container(
                      alignment: Alignment.center,
                      height: 60,
                      child: AnimatedOpacity(
                        opacity: 1.0 ,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          CupertinoIcons.calendar,
                          size: 30,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    );
                  },
                ),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Item #${items[index]}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
