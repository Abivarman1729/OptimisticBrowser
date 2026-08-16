
enum BrowserTabMode { normal, private }

class BrowserTab {
  BrowserTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
    this.mode = BrowserTabMode.normal,
    this.groupId,
    this.profileId,
    this.isLoading = false,
    this.zoom = 1.0,
  });

  final String id;
  String url;
  String title;
  BrowserTabMode mode;
  String? groupId;
  String? profileId;
  bool isLoading;
  double zoom;

  Map<String, Object?> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'mode': mode.name,
        'groupId': groupId,
        'profileId': mode == BrowserTabMode.private ? null : profileId,
        'isLoading': isLoading,
        'zoom': zoom,
      };

  factory BrowserTab.fromJson(Map<String, dynamic> json) => BrowserTab(
        id: '${json['id']}',
        url: '${json['url'] ?? ''}',
        title: '${json['title'] ?? 'New Tab'}',
        mode: json['mode'] == 'private'
            ? BrowserTabMode.private
            : BrowserTabMode.normal,
        groupId: json['groupId'] as String?,
        profileId: json['mode'] == 'private' ? null : json['profileId'] as String?,
        isLoading: json['isLoading'] == true,
        zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
      );
}
