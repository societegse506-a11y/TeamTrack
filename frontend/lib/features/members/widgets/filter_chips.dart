enum MemberFilter { all }

class FilterChips {
  final MemberFilter selected;
  final void Function(MemberFilter) onChanged;

  const FilterChips({
    required this.selected,
    required this.onChanged,
  });
}
