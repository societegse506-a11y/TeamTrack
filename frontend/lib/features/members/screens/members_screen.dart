import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../widgets/member_card.dart';
import '../widgets/delete_confirm_dialog.dart';
import 'member_form_screen.dart';
import 'member_detail_screen.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/notifiers/member_notifier.dart';
import '../../../theme/app_colors.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _service = MemberService();
  final _searchController = TextEditingController();

  List<Member> _allMembers = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = true;
  String? _error;


  final Set<String> _frequentLateIds = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
    memberRefreshNotifier.addListener(_loadMembers);
  }

  @override
  void dispose() {
    memberRefreshNotifier.removeListener(_loadMembers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getMembers(),
        _service.getFrequentLateMemberIds(),
      ]);
      final members = results[0] as List<Member>;
      final lateIds = results[1] as Set<String>;
      if (!mounted) return;
      setState(() {
        _allMembers = members;
        _frequentLateIds.addAll(lateIds);
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((m) {
        if (query.isNotEmpty &&
            !m.fullName.toLowerCase().contains(query) &&
            !m.cin.toLowerCase().contains(query) &&
            !m.telephone.contains(query)) {
          return false;
        }
        return true;
      }).toList();
    });
  }



  void _onSearchChanged(String query) {
    _applyFilters();
  }

  Future<void> _deleteMember(Member member) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      memberName: member.fullName,
    );
    if (confirmed != true) return;

    try {
      await _service.deleteMember(member.id);
      if (!mounted) return;
      memberRefreshNotifier.value++;
      setState(() {
        _allMembers.removeWhere((m) => m.id == member.id);
        _frequentLateIds.remove(member.id);
      });
      _applyFilters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.fullName} deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openForm({Member? member}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MemberFormScreen(member: member),
      ),
    );
    if (result == true) _loadMembers();
  }

  void _openDetail(Member member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberDetailScreen(member: member),
      ),
    ).then((refreshed) {
      if (refreshed == true) _loadMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 600;
      final hp = isWide ? 24.0 : 16.0;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Members'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            if (!_isLoading) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(hp, 8, hp, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withAlpha(60),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

            ],
            Expanded(child: _buildBody(isWide, hp)),
          ],
        ),
      );
    });
  }

  Widget _buildBody(bool isWide, double hp) {
    if (_isLoading) return _buildLoading(hp);
    if (_error != null) return _buildError();
    if (_allMembers.isEmpty) return _buildEmpty();
    if (_filteredMembers.isEmpty) return _buildNoResults();
    return _buildList(hp);
  }

  Widget _buildLoading([double hp = 16]) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(hp, 8, hp, 88),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerCard(height: 96),
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
            onRetry: _loadMembers,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 40,
                color: AppColors.primary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No members yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first team member to start\ntracking attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add your first member'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No members found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or filter.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(double hp) {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final columnCount = isWide ? 2 : 1;
        final spacing = isWide ? 12.0 : 0.0;

        if (columnCount == 1) {
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(hp, 4, hp, 88),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _filteredMembers.length,
            itemBuilder: (context, index) {
              final member = _filteredMembers[index];
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: MemberCard(
                  member: member,
                  isLateFrequent: _frequentLateIds.contains(member.id),
                  onTap: () => _openDetail(member),
                  onEdit: () => _openForm(member: member),
                  onDelete: () => _deleteMember(member),
                  onViewHistory: () => _openDetail(member),
                ),
              );
            },
          );
        }

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(hp, 4, hp, 88),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisExtent: 160,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: _filteredMembers.length,
          itemBuilder: (context, index) {
            final member = _filteredMembers[index];
            return MemberCard(
              member: member,
              isLateFrequent: _frequentLateIds.contains(member.id),
              onTap: () => _openDetail(member),
              onEdit: () => _openForm(member: member),
              onDelete: () => _deleteMember(member),
              onViewHistory: () => _openDetail(member),
            );
          },
        );
      }),
    );
  }
}
