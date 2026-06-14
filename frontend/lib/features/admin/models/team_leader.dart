import '../../auth/models/user.dart';
import '../../members/models/member.dart';

class TeamLeaderWithMembers {
  final User user;
  final List<Member> members;

  TeamLeaderWithMembers({required this.user, required this.members});

  factory TeamLeaderWithMembers.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    final List<dynamic> membersList = json['members'] ?? [];
    final members = membersList
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
    return TeamLeaderWithMembers(user: user, members: members);
  }
}
