import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../../../theme/app_colors.dart';
import '../../auth/models/user.dart';
import '../../members/models/member.dart';
import '../../members/screens/member_detail_screen.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final _service = AdminService();
  List<_TeamData> _teams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leaders = await _service.getUsersWithMembers();
      if (!mounted) return;
      setState(() {
        _teams = leaders
            .map((tl) => _TeamData(
                  user: tl.user,
                  members: tl.members,
                ))
            .toList();
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
      appBar: AppBar(
        title: const Text('Teams Overview'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const _ShimmerTeamCard(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No team leaders found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final totalMembers = _teams.fold<int>(0, (s, t) => s + t.members.length);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          _buildSummaryCard(totalMembers),
          const SizedBox(height: 16),
          ..._teams.map(_buildTeamCard),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalMembers) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Overview',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_teams.length} teams  ·  $totalMembers members',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(_TeamData team) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: team.members.isNotEmpty && team == _teams.first,
        tilePadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: 4),
        childrenPadding: EdgeInsets.fromLTRB(isSmallScreen ? 12 : 16, 0, isSmallScreen ? 12 : 16, 12),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          radius: isSmallScreen ? 18 : 22,
          backgroundColor: AppColors.primary.withAlpha(25),
          child: Text(
            _initials(team.user),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        title: Text(
          '${team.user.prenom} ${team.user.nom}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 13 : 14,
          ),
        ),
        subtitle: Text(
          '${team.members.length} member${team.members.length == 1 ? '' : 's'}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: team.members.isEmpty
            ? Icon(Icons.info_outline, size: 20, color: Colors.grey.shade400)
            : null,
        children: team.members.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'No members assigned yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ]
            : team.members.map((m) => _buildMemberTile(m, isSmallScreen)).toList(),
      ),
    );
  }

  Widget _buildMemberTile(Member member, bool isSmall) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberDetailScreen(member: member),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: isSmall ? 28 : 32,
                  height: isSmall ? 28 : 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      member.initials,
                      style: TextStyle(
                        fontSize: isSmall ? 10 : 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary.withAlpha(180),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: TextStyle(
                          fontSize: isSmall ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'CIN: ${member.cin}  ·  ${member.telephone}',
                        style: TextStyle(
                          fontSize: isSmall ? 10 : 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(User user) {
    final p = user.prenom.isNotEmpty ? user.prenom[0] : '';
    final n = user.nom.isNotEmpty ? user.nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}

class _TeamData {
  final User user;
  final List<Member> members;
  _TeamData({required this.user, required this.members});
}

class _ShimmerTeamCard extends StatelessWidget {
  const _ShimmerTeamCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14, width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 11, width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
