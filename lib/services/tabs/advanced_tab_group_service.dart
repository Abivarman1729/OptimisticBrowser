class TabGroup {
  TabGroup({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    Iterable<String>? tabIds,
  }) : tabIds = {...?tabIds};

  final String id;
  String name;
  int colorIndex;
  final Set<String> tabIds;

  bool contains(String tabId) => tabIds.contains(tabId);

  void add(String tabId) => tabIds.add(tabId);

  void remove(String tabId) => tabIds.remove(tabId);

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'tabIds': tabIds.toList(),
      };
}

class AdvancedTabGroupService {
  final Map<String, TabGroup> _groups = {};

  List<TabGroup> get groups => List.unmodifiable(_groups.values);

  TabGroup create(String name, {int colorIndex = 0}) {
    final id = 'group-${DateTime.now().microsecondsSinceEpoch}';
    final group = TabGroup(
      id: id,
      name: name.trim().isEmpty ? 'Tab group' : name.trim(),
      colorIndex: colorIndex,
    );
    _groups[id] = group;
    return group;
  }

  bool addTab(String groupId, String tabId) {
    final group = _groups[groupId];
    if (group == null) return false;
    for (final other in _groups.values) {
      if (other.id != groupId) other.remove(tabId);
    }
    group.add(tabId);
    return true;
  }

  void removeTab(String groupId, String tabId) {
    _groups[groupId]?.remove(tabId);
  }

  TabGroup? groupForTab(String tabId) {
    for (final group in _groups.values) {
      if (group.contains(tabId)) return group;
    }
    return null;
  }

  bool rename(String id, String name) {
    final group = _groups[id];
    if (group == null || name.trim().isEmpty) return false;
    group.name = name.trim();
    return true;
  }

  void delete(String id) => _groups.remove(id);

  Map<String, Object?> snapshot() => {
        'groups': _groups.values.map((e) => e.toJson()).toList(),
      };
}
