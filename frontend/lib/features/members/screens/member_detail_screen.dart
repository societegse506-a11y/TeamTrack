import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../../attendance/models/attendance_model.dart';
import '../../attendance/services/attendance_service.dart';
import 'member_form_screen.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/notifiers/attendance_notifier.dart';
import '../../../shared/notifiers/member_notifier.dart';
import '../../../theme/app_colors.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late Member _member;
  final _service = MemberService();
  final _attendanceService = AttendanceService();

  List<AttendanceRecord> _records = [];
  bool _isLoading = true;

  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _loadRecords();
    attendanceRefreshNotifier.addListener(_onAttendanceChanged);
    memberRefreshNotifier.addListener(_onMemberChanged);
  }

  @override
  void dispose() {
    attendanceRefreshNotifier.removeListener(_onAttendanceChanged);
    memberRefreshNotifier.removeListener(_onMemberChanged);
    super.dispose();
  }

  void _onAttendanceChanged() {
    _loadRecords();
  }

  void _onMemberChanged() {
    _reloadMember();
    _loadRecords();
  }

  Future<void> _reloadMember() async {
    try {
      final member = await _service.getMember(_member.id);
      if (mounted) setState(() => _member = member);
    } catch (_) {}
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final records = await _attendanceService.getMemberHistory(
        _member.id,
        year: _currentYear,
        month: _currentMonth,
      );
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth--;
      if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
    _loadRecords();
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth++;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      }
    });
    _loadRecords();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${_member.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteMember(_member.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_member.fullName} deleted')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberFormScreen(member: _member),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  AttendanceStatus? _getStatusForDay(int day, String session) {
    for (final rec in _records) {
      final rd = rec.date;
      if (rd.year == _currentYear &&
          rd.month == _currentMonth &&
          rd.day == day &&
          rec.session == session) {
        return rec.attendanceStatus;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_member.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _buildProfileHeader(theme),
            ),
            const SizedBox(height: 20),
            // Contact info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildContactCard(theme),
            ),
            const SizedBox(height: 24),
            // Calendar section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance Calendar',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCalendar(theme, isDark),
            ),
            const SizedBox(height: 16),
            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildLegend(),
            ),
            const SizedBox(height: 20),
            // Records list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Attendance Records',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: ShimmerCard(height: 80),
                  )
                : _buildRecordsList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: isDark
              ? AppColors.primary.withAlpha(30)
              : AppColors.primary.withAlpha(15),
          child: Text(
            _member.initials,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _member.fullName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _member.description.isNotEmpty ? _member.description : 'Team Member',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'CIN',
              value: _member.cin.isNotEmpty
                  ? _member.cin
                  : 'Not provided',
            ),
            const Divider(height: 24),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _member.telephone.isNotEmpty
                  ? _member.telephone
                  : 'Not provided',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final firstDay = DateTime(_currentYear, _currentMonth, 1);
    final lastDay = DateTime(_currentYear, _currentMonth + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7; // 0 = Sunday

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousMonth,
                ),
                Text(
                  '${monthNames[_currentMonth - 1]} $_currentYear',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Day headers
            Row(
              children: dayNames.map((d) {
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Calendar grid
            ...List.generate(_buildWeeks(daysInMonth, startWeekday), (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: List.generate(7, (dayIndex) {
                    final day = weekIndex * 7 + dayIndex - startWeekday + 1;
                    final isValid = day >= 1 && day <= daysInMonth;
                    final isToday = isValid &&
                        _currentYear == now.year &&
                        _currentMonth == now.month &&
                        day == now.day;

                    if (!isValid) {
                      return const Expanded(child: SizedBox());
                    }

                    final morningStatus = _getStatusForDay(day, 'morning');
                    final afternoonStatus = _getStatusForDay(day, 'afternoon');
                    final dayDate = DateTime(_currentYear, _currentMonth, day);
                    final isFutureDay = dayDate.isAfter(now);

                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary.withAlpha(12)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? AppColors.primary
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _SessionDot(
                                    label: 'A',
                                    status: morningStatus,
                                    isFuture: isFutureDay,
                                  ),
                                  const SizedBox(width: 3),
                                  _SessionDot(
                                    label: 'P',
                                    status: afternoonStatus,
                                    isFuture: isFutureDay,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  int _buildWeeks(int daysInMonth, int startWeekday) {
    final totalCells = startWeekday + daysInMonth;
    return (totalCells / 7).ceil();
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: AppColors.success, label: 'Present'),
          const SizedBox(width: 12),
          _LegendItem(color: AppColors.warning, label: 'Late'),
          const SizedBox(width: 12),
          _LegendItem(color: AppColors.error, label: 'Absent'),
        ],
      ),
    );
  }

  Widget _buildRecordsList(ThemeData theme) {
    if (_records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'No attendance records for this month',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _records.map((rec) {
        final statusColor = switch (rec.attendanceStatus) {
          AttendanceStatus.present => AppColors.success,
          AttendanceStatus.late => AppColors.warning,
          AttendanceStatus.absent => AppColors.error,
          AttendanceStatus.outsideZone => AppColors.error,
          AttendanceStatus.notChecked => AppColors.error,
        };

        final sessionLabel = rec.session == 'morning' ? 'AM' : 'PM';
        final sessionIcon = rec.session == 'morning'
            ? Icons.wb_sunny
            : Icons.nights_stay;
        final dateStr =
            '${rec.date.day}/${rec.date.month}/${rec.date.year}';
        final timeStr = rec.checkInTime != null
            ? (rec.checkInTime!.length > 10
                ? rec.checkInTime!.substring(11, 19)
                : rec.checkInTime!)
            : '--:--';

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      sessionIcon,
                      size: 18,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sessionLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Check-in: $timeStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      rec.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionDot extends StatelessWidget {
  final String label;
  final AttendanceStatus? status;
  final bool isFuture;

  const _SessionDot({
    required this.label,
    this.status,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AttendanceStatus.present => AppColors.success,
      AttendanceStatus.late => AppColors.warning,
      AttendanceStatus.absent => AppColors.error,
      AttendanceStatus.outsideZone => AppColors.error,
      AttendanceStatus.notChecked => isFuture ? Colors.grey.shade300 : AppColors.error,
      null => isFuture ? Colors.grey.shade300 : AppColors.error,
    };

    return Container(
      width: 22,
      height: 16,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
