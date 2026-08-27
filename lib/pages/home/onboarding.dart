part of '../home_page.dart';

class _FirstRunTutorialSheet extends StatefulWidget {
  const _FirstRunTutorialSheet();

  @override
  State<_FirstRunTutorialSheet> createState() => _FirstRunTutorialSheetState();
}

class _FirstRunTutorialSheetState extends State<_FirstRunTutorialSheet> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == 3) {
      Navigator.pop(context, true);
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.language,
      builder: (context, _, _) {
        final pages = <({IconData icon, String title, String body})>[
          (
            icon: Icons.translate_rounded,
            title: context.tr('tutorialLanguageTitle'),
            body: context.tr('tutorialLanguageBody'),
          ),
          (
            icon: Icons.auto_awesome_rounded,
            title: context.tr('tutorialMatchesTitle'),
            body: context.tr('tutorialMatchesBody'),
          ),
          (
            icon: Icons.route_rounded,
            title: context.tr('tutorialMapTitle'),
            body: context.tr('tutorialMapBody'),
          ),
          (
            icon: Icons.task_alt_rounded,
            title: context.tr('tutorialKitTitle'),
            body: context.tr('tutorialKitBody'),
          ),
        ];
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                height: math.min(650, MediaQuery.sizeOf(context).height * .9),
                decoration: const BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 14, 14, 4),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'W',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'werkly',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(context.tr('skip')),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: pages.length,
                        onPageChanged: (value) => setState(() => _page = value),
                        itemBuilder: (context, index) {
                          final item = pages[index];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    color: index.isEven
                                        ? _mint
                                        : const Color(0xFFFFEBD2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 48,
                                    color: index.isEven
                                        ? _green
                                        : const Color(0xFFAA681B),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 27,
                                    height: 1.1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 13),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 500,
                                  ),
                                  child: Text(
                                    item.body,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                if (index == 0) ...[
                                  const SizedBox(height: 26),
                                  SegmentedButton<AppLanguage>(
                                    showSelectedIcon: true,
                                    segments: [
                                      for (final language in AppLanguage.values)
                                        ButtonSegment(
                                          value: language,
                                          label: Text(language.shortLabel),
                                        ),
                                    ],
                                    selected: {
                                      AppLanguageController.language.value,
                                    },
                                    onSelectionChanged: (selection) =>
                                        AppLanguageController.setLanguage(
                                          selection.first,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var index = 0; index < pages.length; index++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: index == _page ? 24 : 7,
                                  height: 7,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == _page
                                        ? _green
                                        : const Color(0xFFD2D9D5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.trFormat('tutorialProgress', {
                              'current': _page + 1,
                              'total': pages.length,
                            }),
                            style: const TextStyle(color: _muted, fontSize: 10),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _next,
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              icon: Icon(
                                _page == pages.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                              label: Text(
                                _page == pages.length - 1
                                    ? context.tr('start')
                                    : context.tr('next'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingWelcomeSheet extends StatelessWidget {
  const _OnboardingWelcomeSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            decoration: const BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCAD2CE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'W',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('welcomeWerkly'),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              context.tr('chooseHowToPersonalize'),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('close'),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _OnboardingChoice(
                    icon: Icons.tune_rounded,
                    title: context.tr('choosePreferences'),
                    subtitle: context.tr('choosePreferencesBody'),
                    badge: context.tr('twoMinutes'),
                    primary: true,
                    onTap: () =>
                        Navigator.pop(context, _OnboardingAction.preferences),
                  ),
                  const SizedBox(height: 10),
                  _OnboardingChoice(
                    icon: Icons.document_scanner_rounded,
                    title: context.tr('importAnalyzeCv'),
                    subtitle: context.tr('importAnalyzeCvBody'),
                    badge: context.tr('secureAccountRequired'),
                    onTap: () => Navigator.pop(context, _OnboardingAction.cv),
                  ),
                  const SizedBox(height: 10),
                  _OnboardingChoice(
                    icon: Icons.explore_outlined,
                    title: context.tr('exploreFirst'),
                    subtitle: context.tr('exploreFirstBody'),
                    badge: context.tr('guestBadge'),
                    onTap: () =>
                        Navigator.pop(context, _OnboardingAction.explore),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: _muted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          context.tr('noAutomaticApplication'),
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingChoice extends StatelessWidget {
  const _OnboardingChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? _ink : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary ? _ink : _line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary
                      ? const Color(0xFF304039)
                      : const Color(0xFFF0F5F2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primary ? _orange : _green, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primary ? Colors.white : _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: primary ? const Color(0xFFC9D1CE) : _muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      badge,
                      style: TextStyle(
                        color: primary ? _orange : _green,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: primary ? Colors.white : _green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPreferencesSheet extends StatefulWidget {
  const _QuickPreferencesSheet({required this.profile});

  final UserProfileData profile;

  @override
  State<_QuickPreferencesSheet> createState() => _QuickPreferencesSheetState();
}

class _QuickPreferencesSheetState extends State<_QuickPreferencesSheet> {
  static const _availableFields = [
    'Tous domaines',
    'Informatique',
    'Data & IA',
    'Ingénierie',
    'Business & Finance',
    'Marketing & Design',
  ];
  static const _workModes = ['Hybride', 'Télétravail', 'Sur site'];
  static const _weeklyHours = ['10–15 h', '16–20 h', 'Plus de 20 h'];
  static const _germanLevels = [
    'Non précisé',
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
  ];
  static const _radii = [10, 25, 50, 100];

  late final TextEditingController _city;
  late final FocusNode _cityFocus;
  late final Set<String> _fields;
  late String _workMode;
  late String _hours;
  late String _german;
  late int _radius;
  GermanCity? _selectedCity;
  bool _isLocating = false;
  bool _showDomainError = false;
  String? _locationError;
  String _locationSource = 'manual';

  @override
  void initState() {
    super.initState();
    final preferences = widget.profile.preferences;
    _city = TextEditingController(text: widget.profile.city);
    _cityFocus = FocusNode();
    _selectedCity = GermanCityService.exact(widget.profile.city);
    _locationSource = preferences['location_source'] as String? ?? 'manual';
    _fields = List<String>.from(
      preferences['fields'] as List? ?? const [],
    ).toSet();
    if (_fields.isEmpty) _fields.add('Tous domaines');
    _workMode = preferences['work_mode'] as String? ?? 'Hybride';
    _hours = preferences['weekly_hours'] as String? ?? '16–20 h';
    _german = preferences['german_level'] as String? ?? 'Non précisé';
    _radius = (preferences['search_radius'] as num?)?.toInt() ?? 25;
  }

  @override
  void dispose() {
    _city.dispose();
    _cityFocus.dispose();
    super.dispose();
  }

  void _selectCity(GermanCity city, {bool fromCurrentPosition = false}) {
    setState(() {
      _selectedCity = city;
      _city.text = city.name;
      _city.selection = TextSelection.collapsed(offset: city.name.length);
      _locationError = null;
      _locationSource = fromCurrentPosition
          ? 'current_position_city'
          : 'city_suggestion';
    });
    _cityFocus.unfocus();
  }

  Future<void> _useCurrentLocation() async {
    final serviceOffMessage = context.tr('locationServiceOff');
    final deniedMessage = context.tr('locationDenied');
    final blockedMessage = context.tr('locationBlocked');
    final outsideGermanyMessage = context.tr('outsideGermany');
    final unavailableMessage = context.tr('locationUnavailable');
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw _LocationSelectionException(serviceOffMessage);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw _LocationSelectionException(deniedMessage);
      }
      if (permission == LocationPermission.deniedForever) {
        throw _LocationSelectionException(blockedMessage);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final nearest = GermanCityService.nearest(
        position.latitude,
        position.longitude,
      );
      if (nearest.distanceKm > 180) {
        throw _LocationSelectionException(outsideGermanyMessage);
      }
      if (!mounted) return;
      _selectCity(nearest.city, fromCurrentPosition: true);
    } on _LocationSelectionException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = unavailableMessage);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _toggleField(String field, bool selected) {
    setState(() {
      _showDomainError = false;
      if (field == 'Tous domaines') {
        _fields.clear();
        if (selected) _fields.add(field);
        return;
      }
      _fields.remove('Tous domaines');
      selected ? _fields.add(field) : _fields.remove(field);
    });
  }

  void _submit() {
    final cityName = _city.text.trim();
    if (cityName.isEmpty || _fields.isEmpty) {
      setState(() {
        _showDomainError = _fields.isEmpty;
        if (cityName.isEmpty) {
          _locationError = context.tr('chooseCityRequired');
        }
      });
      return;
    }
    final city = _selectedCity ?? GermanCityService.exact(cityName);
    Navigator.pop(
      context,
      _OnboardingPreferences(
        city: city?.name ?? cityName,
        fields: _fields.toList(),
        workMode: _workMode,
        weeklyHours: _hours,
        germanLevel: _german,
        searchRadius: _radius,
        cityLatitude: city?.latitude,
        cityLongitude: city?.longitude,
        locationSource: city == null ? 'manual' : _locationSource,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(context).height * .92,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('preferencesTitle'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.tr('preferencesPurpose'),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _city,
                          focusNode: _cityFocus,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.addressCity],
                          onTap: () => setState(() {}),
                          onChanged: (value) => setState(() {
                            _selectedCity = GermanCityService.exact(value);
                            _locationError = null;
                            _locationSource = 'manual';
                          }),
                          decoration: InputDecoration(
                            labelText: context.tr('searchCity'),
                            hintText: context.tr('cityHint'),
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: _city.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: context.tr('clearCity'),
                                    onPressed: () => setState(() {
                                      _city.clear();
                                      _selectedCity = null;
                                      _locationError = null;
                                      _locationSource = 'manual';
                                      _cityFocus.requestFocus();
                                    }),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        _CitySuggestions(
                          query: _city.text,
                          visible: _cityFocus.hasFocus,
                          onSelected: _selectCity,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _isLocating ? null : _useCurrentLocation,
                            icon: _isLocating
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded),
                            label: Text(
                              _isLocating
                                  ? context.tr('locatingCity')
                                  : context.tr('useCurrentLocation'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('approximateCityOnly'),
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                        if (_locationError != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            _locationError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('domainsQuestion'),
                          subtitle: context.tr('chooseAtLeastOne'),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableFields
                              .map(
                                (field) => FilterChip(
                                  selected: _fields.contains(field),
                                  label: Text(
                                    _localizedPreferenceValue(context, field),
                                  ),
                                  onSelected: (selected) =>
                                      _toggleField(field, selected),
                                ),
                              )
                              .toList(),
                        ),
                        if (_showDomainError) ...[
                          const SizedBox(height: 7),
                          Text(
                            context.tr('domainRequired'),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('preferredWorkMode'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _workModes,
                          selected: _workMode,
                          onSelected: (value) =>
                              setState(() => _workMode = value),
                        ),
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('weeklyAvailability'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _weeklyHours,
                          selected: _hours,
                          onSelected: (value) => setState(() => _hours = value),
                        ),
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.tr('germanLevelChoice'),
                          subtitle: context.tr('germanLevelHelp'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _germanLevels,
                          selected: _german,
                          onSelected: (value) =>
                              setState(() => _german = value),
                        ),
                        const SizedBox(height: 20),
                        _PreferenceLabel(
                          title: context.trFormat('searchRadius', {
                            'radius': _radius,
                          }),
                          subtitle: context.tr('distantJobsVisible'),
                        ),
                        const SizedBox(height: 10),
                        _ChoiceRow(
                          values: _radii.map((value) => '$value km').toList(),
                          selected: '$_radius km',
                          onSelected: (value) => setState(
                            () => _radius = int.parse(value.split(' ').first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(context.tr('personalizeJobs')),
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

class _LocationSelectionException implements Exception {
  const _LocationSelectionException(this.message);

  final String message;
}

class _CitySuggestions extends StatelessWidget {
  const _CitySuggestions({
    required this.query,
    required this.visible,
    required this.onSelected,
  });

  final String query;
  final bool visible;
  final ValueChanged<GermanCity> onSelected;

  @override
  Widget build(BuildContext context) {
    if (!visible || query.trim().isEmpty) return const SizedBox.shrink();
    final suggestions = GermanCityService.search(query);
    if (suggestions.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 7, 12, 0),
        child: Text(
          context.tr('noCitySuggestion'),
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < suggestions.length; index++) ...[
              if (index > 0) const Divider(height: 1, indent: 46),
              ListTile(
                dense: true,
                visualDensity: const VisualDensity(vertical: -3),
                leading: const Icon(
                  Icons.location_city_rounded,
                  color: _green,
                  size: 19,
                ),
                title: Text(
                  suggestions[index].name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  suggestions[index].state,
                  style: const TextStyle(fontSize: 10),
                ),
                onTap: () => onSelected(suggestions[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreferenceLabel extends StatelessWidget {
  const _PreferenceLabel({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ],
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => ChoiceChip(
              selected: value == selected,
              label: Text(_localizedPreferenceValue(context, value)),
              onSelected: (_) => onSelected(value),
            ),
          )
          .toList(),
    );
  }
}

