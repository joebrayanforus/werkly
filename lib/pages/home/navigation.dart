part of '../home_page.dart';

class _WorkspaceStatusView extends StatelessWidget {
  const _WorkspaceStatusView({
    super.key,
    required this.title,
    required this.icon,
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final IconData icon;
  final bool loading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator(color: _green)
              else
                Icon(icon, size: 48, color: _muted),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                loading
                    ? context.tr('loadingRealJobs')
                    : message ?? context.tr('noJobsAvailable'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (!loading) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.selected,
    required this.profileCompletion,
    required this.onSelected,
  });

  final int selected;
  final int profileCompletion;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded, context.tr('home')),
      (Icons.work_outline_rounded, context.tr('jobs')),
      (Icons.map_outlined, context.tr('map')),
      (Icons.view_kanban_outlined, context.tr('tracking')),
      (Icons.person_outline_rounded, context.tr('profile')),
    ];

    return Container(
      width: 218,
      decoration: const BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: _Brand(light: true),
                    ),
                    SizedBox(height: compact ? 24 : 42),
                    for (var i = 0; i < items.length; i++) ...[
                      _SideNavItem(
                        icon: items[i].$1,
                        label: items[i].$2,
                        selected: selected == i,
                        onTap: () => onSelected(i),
                      ),
                      SizedBox(height: compact ? 3 : 7),
                    ],
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.all(compact ? 11 : 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: _orange,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  context.trFormat('profileCompletion', {
                                    'score': profileCompletion,
                                  }),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          LinearProgressIndicator(
                            value: profileCompletion.clamp(0, 100) / 100,
                            minHeight: 5,
                            color: _orange,
                            backgroundColor: Color(0xFF43504C),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            context.tr('profileTip'),
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB8C2BE),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 9 : 18),
                    _UserRow(light: true),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? _ink : const Color(0xFF9FABE4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? _ink : const Color(0xFFD2D8D5),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: onSelected,
      height: 68,
      backgroundColor: Colors.white,
      indicatorColor: _mint,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.grid_view_rounded),
          label: context.tr('home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.work_outline_rounded),
          label: context.tr('jobs'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.map_outlined),
          label: context.tr('map'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.view_kanban_outlined),
          label: context.tr('tracking'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          label: context.tr('profile'),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.desktop,
    required this.pageIndex,
    required this.onSearch,
    required this.onAssistant,
    required this.onNotifications,
    required this.unreadNotifications,
  });

  final bool desktop;
  final int pageIndex;
  final ValueChanged<String> onSearch;
  final VoidCallback onAssistant;
  final VoidCallback onNotifications;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final titles = [
      context.tr('dashboard'),
      context.tr('jobs'),
      context.tr('map'),
      context.tr('applications'),
      context.tr('myProfile'),
    ];
    return Container(
      height: desktop ? 86 : 72,
      padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 16),
      decoration: const BoxDecoration(
        color: _cream,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          if (!desktop) ...[
            const _Brand(light: false),
            const Spacer(),
          ] else ...[
            Text(
              titles[pageIndex],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(width: 28),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: TextField(
                  onChanged: onSearch,
                  decoration: InputDecoration(
                    hintText: context.tr('searchHint'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 21),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: context.tr('notifications'),
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(
                  unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                ),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
            const SizedBox(width: 10),
            _UserRow(light: false),
          ],
          if (!desktop) ...[
            IconButton(
              tooltip: context.tr('notifications'),
              onPressed: onNotifications,
              icon: Badge(
                isLabelVisible: unreadNotifications > 0,
                label: Text(
                  unreadNotifications > 9 ? '9+' : '$unreadNotifications',
                ),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
            IconButton(
              tooltip: context.tr('assistant'),
              onPressed: onAssistant,
              icon: const Icon(Icons.auto_awesome_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.light});
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: const Text(
            'W',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'werkly',
          style: TextStyle(
            color: light ? Colors.white : _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.light});
  final bool light;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName = (user?.userMetadata?['full_name'] as String?)?.trim();
    final name = metadataName == null || metadataName.isEmpty
        ? (user?.email?.split('@').first ?? context.tr('guestMode'))
        : metadataName;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFB9D7CC),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials.isEmpty ? 'W' : initials,
            style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: light ? Colors.white : _ink,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

