import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/session_card.dart';
import '../widgets/quick_actions_card.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/workplace_map.dart';
import '../../../shared/notifiers/attendance_notifier.dart';
import '../../../shared/notifiers/member_notifier.dart';
import '../../../theme/app_colors.dart';
import '../../statistics/widgets/overview_cards.dart';
import '../../statistics/widgets/monthly_chart.dart';
import '../../statistics/widgets/member_stats_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = DashboardService();
  final _scrollController = ScrollController();
  DashboardData? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    attendanceRefreshNotifier.addListener(_onRefreshNeeded);
    memberRefreshNotifier.addListener(_onRefreshNeeded);
  }

  @override
  void dispose() {
    attendanceRefreshNotifier.removeListener(_onRefreshNeeded);
    memberRefreshNotifier.removeListener(_onRefreshNeeded);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefreshNeeded() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchDashboard();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    return _buildContent();
  }

  Widget _buildLoading() {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;
      final hp = isWide ? 24.0 : 16.0;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildGradientHeaderShimmer(isWide),
          SizedBox(height: isWide ? 24 : 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp),
            child: ShimmerCard(height: 160),
          ),
          SizedBox(height: isWide ? 24 : 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp + 4),
            child: Text('Sessions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: isWide ? 16 : 12),
          if (isWide)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: Row(
                children: [
                  Expanded(child: ShimmerCard(height: 140)),
                  const SizedBox(width: 12),
                  Expanded(child: ShimmerCard(height: 140)),
                ],
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: ShimmerCard(height: 140),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: ShimmerCard(height: 140),
            ),
          ],
          SizedBox(height: isWide ? 24 : 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp),
            child: ShimmerCard(height: 140),
          ),
          const SizedBox(height: 24),
        ],
      );
    });
  }

  Widget _buildGradientHeaderShimmer(bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 20, 48, isWide ? 32 : 20, isWide ? 28 : 24),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader() {
    final name = _data?.user?.fullName ?? '';
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join()
        : '?';
    final timeStr = _getGreeting();
    final displayName = _data?.user?.prenom ?? '';
    final isWide = MediaQuery.of(context).size.width >= 600;
    return Container(
      padding: EdgeInsets.fromLTRB(isWide ? 32 : 20, 48, isWide ? 32 : 20, isWide ? 28 : 24),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isWide ? 28 : 24,
                  backgroundColor: Colors.white.withAlpha(30),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isWide ? 18 : 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: isWide ? 14 : 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName.isNotEmpty ? 'Welcome, $displayName' : 'Welcome',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWide ? 24 : 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_data != null) ...[
              const SizedBox(height: 20),
              _buildTodayRate(_data!.attendanceRate, isWide),
            ],
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildTodayRate(double rate, bool isWide) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Attendance",
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: isWide ? 14 : 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 36 : 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isWide ? 64 : 56,
            height: isWide ? 64 : 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: rate / 100,
                  strokeWidth: 5,
                  backgroundColor: Colors.white.withAlpha(30),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text(
                  '${rate.toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWide ? 16 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildGradientHeader(),
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

  void _scrollToAnalytics() {
    final target = _data?.memberStats != null && _data!.memberStats.isNotEmpty;
    if (target && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildContent() {
    final data = _data ?? DashboardData(
      user: null,
      totalMembers: 0,
      morningPresent: 0,
      morningLate: 0,
      afternoonPresent: 0,
      afternoonLate: 0,
    );

    final theme = Theme.of(context);

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;
      final hp = isWide ? 24.0 : 16.0;
      final sectionSpacing = isWide ? 28.0 : 20.0;
      final gridSpacing = isWide ? 12.0 : 12.0;

      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildGradientHeader(),
          SizedBox(height: sectionSpacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp + 4),
            child: Text(
              'Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: isWide ? 16 : 12),
          if (isWide)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: Row(
                children: [
                  Expanded(
                    child: SessionCard(
                      icon: Icons.wb_sunny,
                      label: 'Morning Session',
                      present: data.morningPresent,
                      late: data.morningLate,
                      total: data.totalMembers,
                      gradient: AppColors.gradientWarning,
                    ),
                  ),
                  SizedBox(width: gridSpacing),
                  Expanded(
                    child: SessionCard(
                      icon: Icons.nights_stay,
                      label: 'Afternoon Session',
                      present: data.afternoonPresent,
                      late: data.afternoonLate,
                      total: data.totalMembers,
                      gradient: AppColors.gradientInfo,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: SessionCard(
                icon: Icons.wb_sunny,
                label: 'Morning Session',
                present: data.morningPresent,
                late: data.morningLate,
                total: data.totalMembers,
                gradient: AppColors.gradientWarning,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: SessionCard(
                icon: Icons.nights_stay,
                label: 'Afternoon Session',
                present: data.afternoonPresent,
                late: data.afternoonLate,
                total: data.totalMembers,
                gradient: AppColors.gradientInfo,
              ),
            ),
          ],
          SizedBox(height: sectionSpacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp + 4),
            child: Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: isWide ? 16 : 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.people_rounded,
                    label: 'Total Members',
                    value: data.totalMembers.toString(),
                    gradient: AppColors.gradientInfo,
                  ),
                ),
                SizedBox(width: gridSpacing),
                Expanded(
                  child: StatCard(
                    icon: Icons.pie_chart_rounded,
                    label: 'Overall Rate',
                    value: '${data.attendanceRate.toStringAsFixed(1)}%',
                    gradient: AppColors.gradientSuccess,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sectionSpacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp),
            child: QuickActionsCard(onAnalytics: _scrollToAnalytics),
          ),
          SizedBox(height: sectionSpacing),

          // === Location Section ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp + 4),
            child: Row(
              children: [
                Icon(Icons.map_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Location',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(height: isWide ? 16 : 12),
          if (isWide)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WorkplaceLocationMap(
                      lat: data.workplaceLat,
                      lng: data.workplaceLng,
                      label: 'Workplace Location',
                    ),
                  ),
                  SizedBox(width: gridSpacing),
                  const Expanded(
                    child: CurrentPositionMap(),
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: WorkplaceLocationMap(
                lat: data.workplaceLat,
                lng: data.workplaceLng,
                label: 'Workplace Location',
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: const CurrentPositionMap(),
            ),
          ],
          SizedBox(height: sectionSpacing),

          // === Analytics Section ===
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp + 4),
            child: Row(
              children: [
                Icon(Icons.analytics_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isWide ? 16 : 12),

          if (isWide)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OverviewCards(
                      totalPresent: data.totalPresent,
                      totalLate: data.totalLate,
                      totalAbsent: data.totalAbsent,
                      totalRecords: data.totalRecords,
                      totalPossible: data.totalPossible,
                    ),
                  ),
                  SizedBox(width: gridSpacing),
                  if (data.monthlyStats.isNotEmpty)
                    Expanded(
                      child: MonthlyChart(monthlyStats: data.monthlyStats),
                    ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: OverviewCards(
                totalPresent: data.totalPresent,
                totalLate: data.totalLate,
                totalAbsent: data.totalAbsent,
                totalRecords: data.totalRecords,
                totalPossible: data.totalPossible,
              ),
            ),
            if (data.monthlyStats.isNotEmpty) ...[
              SizedBox(height: isWide ? 16 : 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hp),
                child: MonthlyChart(monthlyStats: data.monthlyStats),
              ),
            ],
          ],

          if (data.memberStats.isNotEmpty) ...[
            SizedBox(height: isWide ? 16 : 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: MemberStatsList(memberStats: data.memberStats),
            ),
          ] else ...[
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No statistics yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Attendance data will appear here once members start checking in.',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: 32),
        ],
      );
    });
  }
}
