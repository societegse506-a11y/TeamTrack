import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../widgets/member_attendance_card.dart';
import '../widgets/session_selector.dart';
import '../../members/models/member.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/fingerprint_modal.dart';
import '../../../shared/notifiers/attendance_notifier.dart';
import '../../../shared/notifiers/member_notifier.dart';
import '../../../shared/notifiers/settings_notifier.dart';
import '../../../theme/app_colors.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _service = AttendanceService();

  String? _selectedSession;
  List<Member> _members = [];
  Map<String, MemberAttendance> _memberStatuses = {};
  bool _isLoading = true;
  String? _error;
  final Set<String> _checkingIn = {};

  @override
  void initState() {
    super.initState();
    _load();
    attendanceRefreshNotifier.addListener(_onRefreshNotified);
    memberRefreshNotifier.addListener(_onRefreshNotified);
  }

  @override
  void dispose() {
    attendanceRefreshNotifier.removeListener(_onRefreshNotified);
    memberRefreshNotifier.removeListener(_onRefreshNotified);
    super.dispose();
  }

  void _onRefreshNotified() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await _service.getMembers();
      final statusMap = await _service.getMemberAttendanceMap(members);
      if (!mounted) return;
      setState(() {
        _members = members;
        _memberStatuses = statusMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  AttendanceStatus _statusForSession(MemberAttendance att) {
    if (_selectedSession == 'morning') return att.morningStatus;
    return att.afternoonStatus;
  }

  bool _isSessionOpen(String session) {
    final settings = SettingsNotifier.instance.value;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startField = session == 'morning' ? settings.morningStart : settings.afternoonStart;
    final endField = session == 'morning' ? settings.morningEnd : settings.afternoonEnd;

    int parseMin(String str) {
      final parts = str.split(':');
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    final start = parseMin(startField);
    final end = parseMin(endField);
    return currentMinutes >= start && currentMinutes < end;
  }

  bool get _canCheckIn {
    if (_selectedSession == null) return false;
    return _isSessionOpen(_selectedSession!);
  }

  Future<void> _onTapMember(Member member) async {
    if (!_canCheckIn || _selectedSession == null) {
      _showSnackBar(
        '${_selectedSession == 'morning' ? 'Morning' : 'Afternoon'} session is not open yet',
        color: AppColors.warning,
      );
      return;
    }
    final att = _memberStatuses[member.id] ??
        MemberAttendance(member: member);
    final session = _selectedSession!;

    final currentStatus = _statusForSession(att);
    if (currentStatus == AttendanceStatus.present ||
        currentStatus == AttendanceStatus.late) {
      _showSnackBar(
        '${member.fullName} already checked in for ${session == 'morning' ? 'Morning' : 'Afternoon'}',
        color: AppColors.warning,
      );
      return;
    }

    if (_checkingIn.contains(member.id)) return;
    if (!mounted) return;
    final ctx = context;

    final isMorning = session == 'morning';
    final sessionLabel = isMorning ? 'Morning' : 'Afternoon';
    final settings = SettingsNotifier.instance.value;
    final sessionTime = isMorning
        ? '${settings.morningStart} - ${settings.morningEnd}'
        : '${settings.afternoonStart} - ${settings.afternoonEnd}';

    final confirmed = await showFingerprintModal(
      ctx,
      memberName: member.fullName,
      sessionLabel: sessionLabel,
      sessionTime: sessionTime,
      isMorning: isMorning,
    );
    if (confirmed != true || !mounted) return;

    Position position;
    try {
      position = await _getCurrentPosition();
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not get GPS location. Please enable location.',
          color: AppColors.error);
      return;
    }

    setState(() => _checkingIn.add(member.id));

    try {
      final result = await _service.checkIn(
        memberId: member.id,
        session: session,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      if (result.success) {
        await _load();

        String msg = result.message;
        if (result.distance != null && result.allowedRadius != null) {
          msg += ' (${result.distance}m / max ${result.allowedRadius}m)';
        }

        final statusColor = result.attendanceStatus == AttendanceStatus.present
            ? AppColors.success
            : AppColors.warning;

        _showSnackBar(msg, color: statusColor);
        attendanceRefreshNotifier.value++;
      } else {
        String msg = result.message;
        if (result.distance != null && result.allowedRadius != null) {
          msg += ' (${result.distance}m / max ${result.allowedRadius}m)';
        }
        _showSnackBar(msg, color: AppColors.error);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Check-in failed: $e', color: AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _checkingIn.remove(member.id));
      }
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(const Duration(seconds: 15));
  }

  String get _sessionTimeRange {
    final settings = SettingsNotifier.instance.value;
    final isMorning = _selectedSession == 'morning';
    return isMorning
        ? '${settings.morningStart} - ${settings.morningEnd}'
        : '${settings.afternoonStart} - ${settings.afternoonEnd}';
  }

  void _showSnackBar(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return _isLoading ? _buildLoading() : _buildBody(isWide);
        }),
      ),
    );
  }

  Widget _buildLoading() {
    if (_selectedSession == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: ShimmerCard(height: 80),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (_) => const ShimmerCard(height: 160)),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(bool isWide) {
    if (_error != null && _members.isEmpty) return _buildError();
    if (_selectedSession == null) return _buildSessionSelector();
    if (_members.isEmpty) return _buildEmpty();
    return _buildContent(isWide);
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isMorning = _selectedSession == 'morning';
    final sessionOpen = _isSessionOpen(_selectedSession ?? 'morning');
    final isWide = MediaQuery.of(context).size.width >= 600;
    final hp = isWide ? 32.0 : 20.0;
    return Container(
      padding: EdgeInsets.fromLTRB(hp, 48, hp, isWide ? 32 : 24),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMorning ? 'Morning Session' : 'Afternoon Session',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isMorning ? Icons.wb_sunny : Icons.nights_stay,
                            size: 16,
                            color: Colors.white.withAlpha(180),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _sessionTimeRange,
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 14,
                            ),
                          ),
                          if (!sessionOpen) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Closed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade200,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _SessionTab(
                        label: 'AM',
                        selected: isMorning,
                        onTap: () {
                          if (isMorning) return;
                          setState(() => _selectedSession = 'morning');
                        },
                      ),
                      _SessionTab(
                        label: 'PM',
                        selected: !isMorning,
                        onTap: () {
                          if (!isMorning) return;
                          setState(() => _selectedSession = 'afternoon');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: ErrorState(
            message: _error!,
            onRetry: _load,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        EmptyState(
          icon: Icons.people_outline_rounded,
          title: 'No members found',
          subtitle: 'Add members first to start tracking attendance.',
        ),
      ],
    );
  }

  Widget _buildSessionSelector() {
    return SessionSelector(
      onSelected: (session) {
        setState(() => _selectedSession = session);
      },
    );
  }

  Widget _buildContent(bool isWide) {
    if (_selectedSession == null) return const SizedBox();
    final isMorning = _selectedSession == 'morning';
    final sessionOpen = _isSessionOpen(_selectedSession!);

    int presentCount = 0;
    int lateCount = 0;

    for (final att in _memberStatuses.values) {
      final st = isMorning ? att.morningStatus : att.afternoonStatus;
      if (st == AttendanceStatus.present) { presentCount++; }
      else if (st == AttendanceStatus.late) { lateCount++; }
    }
    final notCheckedCount = _members.length - presentCount - lateCount;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 8),
          child: _buildSummaryRow(presentCount, lateCount, notCheckedCount),
        ),
        const SizedBox(height: 16),
        if (!sessionOpen)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 8),
            child: Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Session is closed. Check-in is only allowed during session hours.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isWide ? 240 : 200,
              mainAxisExtent: 170,
              mainAxisSpacing: isWide ? 12 : 8,
              crossAxisSpacing: isWide ? 12 : 8,
            ),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              final att = _memberStatuses[member.id] ??
                  MemberAttendance(member: member);
              final status = isMorning ? att.morningStatus : att.afternoonStatus;
              return MemberAttendanceCard(
                member: member,
                status: status,
                session: _selectedSession!,
                isLoading: _checkingIn.contains(member.id),
                isSessionOpen: sessionOpen,
                onTap: sessionOpen ? () => _onTapMember(member) : null,
              );
            },
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSummaryRow(int present, int late, int notChecked) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                icon: Icons.check_circle,
                color: AppColors.success,
                label: 'Present',
                count: present,
              ),
            ),
            Container(
              width: 1, height: 36,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _SummaryItem(
                icon: Icons.access_time,
                color: AppColors.warning,
                label: 'Late',
                count: late,
              ),
            ),
            Container(
              width: 1, height: 36,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _SummaryItem(
                icon: Icons.cancel,
                color: AppColors.error,
                label: 'Not Checked',
                count: notChecked,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SessionTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _SummaryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
