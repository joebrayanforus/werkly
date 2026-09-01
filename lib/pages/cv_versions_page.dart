import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/werkly_repository.dart';
import '../l10n/app_language.dart';

const _writingHelpUrl = 'https://anschreiben.com/';

Future<void> _openWritingHelp(BuildContext context) async {
  final uri = Uri.parse(_writingHelpUrl);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('jobOpenFailed'))));
  }
}

const _ink = Color(0xFF17231F);
const _green = Color(0xFF2F6B55);
const _cream = Color(0xFFF7F7F2);
const _line = Color(0xFFE7EAE4);
const _muted = Color(0xFF718079);
const _mint = Color(0xFFDDEDE4);

const _categories = <String>[
  'Tous domaines',
  'Informatique',
  'Ingénierie',
  'Business & Finance',
  'Marketing & Design',
  'Data & IA',
];

/// Mirrors home_page.dart's private `_localizedPreferenceValue` for the same
/// canonical field strings -- duplicated locally rather than exported across
/// a `part of` boundary, matching this app's existing per-file convention
/// for small shared display helpers.
String _localizedCategoryLabel(BuildContext context, String value) {
  final language = AppLanguageController.language.value;
  if (language == AppLanguage.fr) return value;
  const german = <String, String>{
    'Tous domaines': 'Alle Bereiche',
    'Informatique': 'Informatik',
    'Ingénierie': 'Ingenieurwesen',
    'Business & Finance': 'Wirtschaft & Finanzen',
    'Marketing & Design': 'Marketing & Design',
    'Data & IA': 'Data & KI',
  };
  const english = <String, String>{
    'Tous domaines': 'All fields',
    'Informatique': 'Computer science',
    'Ingénierie': 'Engineering',
    'Business & Finance': 'Business & Finance',
    'Marketing & Design': 'Marketing & Design',
    'Data & IA': 'Data & AI',
  };
  return (language == AppLanguage.de ? german : english)[value] ?? value;
}

/// Mirrors cv_analysis.dart's private `_analysisItems` helper for reading a
/// jsonb list column defensively -- duplicated locally for the same reason
/// as `_localizedCategoryLabel` above.
List<Map<String, dynamic>> _analysisItems(Object? value) => value is List
    ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : const [];

class CvVersionsPage extends StatefulWidget {
  const CvVersionsPage({super.key, required this.profile});

  final UserProfileData profile;

  @override
  State<CvVersionsPage> createState() => _CvVersionsPageState();
}

class _CvVersionsPageState extends State<CvVersionsPage> {
  final _repository = WerklyRepository();
  List<CvVersionData> _versions = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final versions = await _repository.listCvVersions();
      if (!mounted) return;
      setState(() {
        _versions = versions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.tr('jobsLoadFailed');
      });
    }
  }

  Future<void> _createOrEdit({CvVersionData? existing}) async {
    final result = await showDialog<CvVersionData>(
      context: context,
      builder: (context) => _CvVersionEditor(
        version: existing ?? CvVersionData.draft(),
        profile: widget.profile,
      ),
    );
    if (result == null || !mounted) return;
    try {
      final saved = existing == null
          ? await _repository.createCvVersion(result)
          : await _repository.updateCvVersion(result);
      if (!mounted) return;
      setState(() {
        if (existing == null) {
          _versions = [..._versions, saved];
        } else {
          _versions = [
            for (final v in _versions) if (v.id == existing.id) saved else v,
          ];
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cvVersionSaved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cvAnalysisFailed'))),
      );
    }
  }

  Future<void> _delete(CvVersionData version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('deleteCvVersionTitle')),
        content: Text(
          context.trFormat('deleteCvVersionBody', {'label': version.label}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.deleteCvVersion(version.id);
      if (!mounted) return;
      setState(() {
        _versions = _versions.where((v) => v.id != version.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cvVersionDeleted'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cvAnalysisFailed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _ink,
        title: Text(context.tr('cvVersionsTitle')),
      ),
      floatingActionButton: _versions.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _createOrEdit(),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('addCvVersion')),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: _muted)))
          : _versions.isEmpty
          ? _EmptyState(onCreate: () => _createOrEdit())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                Text(
                  context.tr('cvVersionsSubtitle'),
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _WritingHelpLink(onTap: () => _openWritingHelp(context)),
                const SizedBox(height: 16),
                for (final version in _versions) ...[
                  _CvVersionCard(
                    version: version,
                    onEdit: () => _createOrEdit(existing: version),
                    onDelete: () => _delete(version),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, size: 56, color: _muted),
            const SizedBox(height: 16),
            Text(
              context.tr('cvVersionsEmptyTitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('cvVersionsEmptyBody'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _WritingHelpLink(onTap: () => _openWritingHelp(context)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('addCvVersion')),
            ),
          ],
        ),
      ),
    );
  }
}

class _WritingHelpLink extends StatelessWidget {
  const _WritingHelpLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new_rounded, size: 14, color: _green),
            const SizedBox(width: 6),
            Text(
              context.tr('cvVersionsWritingHelp'),
              style: const TextStyle(
                color: _green,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvVersionCard extends StatelessWidget {
  const _CvVersionCard({
    required this.version,
    required this.onEdit,
    required this.onDelete,
  });

  final CvVersionData version;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [version.degree, version.university, version.city]
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      version.label.isEmpty
                          ? context.tr('cvVersionLabel')
                          : version.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        _localizedCategoryLabel(context, version.category),
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: _mint,
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: context.tr('editCvVersion'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                tooltip: context.tr('delete'),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
          if (version.experiences.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final experience in version.experiences)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  [
                    experience['title']?.toString().trim() ?? '',
                    experience['organization']?.toString().trim() ?? '',
                  ].where((value) => value.isNotEmpty).join(' · '),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          if (version.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: version.skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill, style: const TextStyle(fontSize: 11)),
                      backgroundColor: const Color(0xFFF0F6F2),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// Same controller-lifecycle discipline as _EditProfileDialog in
// shared_widgets.dart: controllers are owned and disposed by this dialog's
// own state, not the caller, so a back-button race during the dialog's exit
// transition can't touch a disposed controller.
class _CvVersionEditor extends StatefulWidget {
  const _CvVersionEditor({required this.version, required this.profile});

  final CvVersionData version;
  final UserProfileData profile;

  @override
  State<_CvVersionEditor> createState() => _CvVersionEditorState();
}

class _CvVersionEditorState extends State<_CvVersionEditor> {
  late final TextEditingController _label;
  late final TextEditingController _degree;
  late final TextEditingController _university;
  late final TextEditingController _city;
  late final TextEditingController _skills;
  late final TextEditingController _summary;
  late String _category;
  late List<Map<String, dynamic>> _experiences;
  String? _labelError;

  bool get _hasAnalyzedCv =>
      _analysisItems(widget.profile.cvAnalysis['experiences']).isNotEmpty ||
      widget.profile.skills.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.version.label);
    _degree = TextEditingController(text: widget.version.degree);
    _university = TextEditingController(text: widget.version.university);
    _city = TextEditingController(text: widget.version.city);
    _skills = TextEditingController(text: widget.version.skills.join(', '));
    _summary = TextEditingController(
      text: widget.version.professionalSummary,
    );
    _category = widget.version.category;
    _experiences = List.of(widget.version.experiences);
  }

  // Explicit, user-triggered copy from the already-analyzed base CV --
  // never automatic -- so a version can start from real experience/skills
  // instead of an empty keyword list, matching what the app already knows
  // about the user rather than asking them to retype it.
  void _prefillFromAnalysis() {
    setState(() {
      if (_degree.text.trim().isEmpty) _degree.text = widget.profile.degree;
      if (_university.text.trim().isEmpty) {
        _university.text = widget.profile.university;
      }
      if (_city.text.trim().isEmpty) _city.text = widget.profile.city;
      if (_summary.text.trim().isEmpty) {
        _summary.text = widget.profile.professionalSummary;
      }
      if (_skills.text.trim().isEmpty) {
        _skills.text = widget.profile.skills.join(', ');
      }
      if (_experiences.isEmpty) {
        _experiences = _analysisItems(
          widget.profile.cvAnalysis['experiences'],
        );
      }
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _degree.dispose();
    _university.dispose();
    _city.dispose();
    _skills.dispose();
    _summary.dispose();
    super.dispose();
  }

  void _save() {
    if (_label.text.trim().isEmpty) {
      setState(() => _labelError = context.tr('cvVersionLabelRequired'));
      return;
    }
    final parsedSkills = _skills.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    Navigator.pop(
      context,
      CvVersionData(
        id: widget.version.id,
        label: _label.text,
        category: _category,
        university: _university.text,
        degree: _degree.text,
        city: _city.text,
        professionalSummary: _summary.text,
        skills: parsedSkills,
        experiences: _experiences,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('editCvVersion')),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _label,
                decoration: InputDecoration(
                  labelText: context.tr('cvVersionLabel'),
                  hintText: context.tr('cvVersionLabelHint'),
                  errorText: _labelError,
                ),
                onChanged: (_) {
                  if (_labelError != null) setState(() => _labelError = null);
                },
              ),
              if (_hasAnalyzedCv) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _prefillFromAnalysis,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(context.tr('prefillFromAnalysis')),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: context.tr('cvVersionCategory'),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(_localizedCategoryLabel(context, category)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _degree,
                decoration: InputDecoration(labelText: context.tr('education')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _university,
                decoration: InputDecoration(
                  labelText: context.tr('university'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _city,
                decoration: InputDecoration(labelText: context.tr('city')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _skills,
                decoration: InputDecoration(
                  labelText: context.tr('commaSkills'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _summary,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('professionalSummary'),
                ),
              ),
              if (_experiences.isNotEmpty) ...[
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('experiences'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < _experiences.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              _experiences[i]['title']?.toString().trim() ??
                                  '',
                              _experiences[i]['organization']
                                      ?.toString()
                                      .trim() ??
                                  '',
                            ].where((value) => value.isNotEmpty).join(' · '),
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(() => _experiences.removeAt(i)),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(context.tr('save'))),
      ],
    );
  }
}
