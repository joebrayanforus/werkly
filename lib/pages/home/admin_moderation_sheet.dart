part of '../home_page.dart';

class _AdminModerationSheet extends StatefulWidget {
  const _AdminModerationSheet({required this.repository});

  final WerklyRepository repository;

  @override
  State<_AdminModerationSheet> createState() => _AdminModerationSheetState();
}

class _AdminModerationSheetState extends State<_AdminModerationSheet> {
  late Future<List<EmployerSubmissionData>> _future = _load();
  var _pendingOnly = true;
  final Set<String> _reviewing = {};

  Future<List<EmployerSubmissionData>> _load() =>
      widget.repository.loadEmployerSubmissions();

  Future<void> _review(EmployerSubmissionData item, bool approved) async {
    final controller = TextEditingController(
      text: approved ? context.tr('adminApprovedDefaultNote') : '',
    );
    final notes = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approved
              ? context.tr('approveJobTitle')
              : context.tr('rejectJobTitle'),
        ),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          autofocus: !approved,
          decoration: InputDecoration(
            labelText: approved
                ? context.tr('internalNote')
                : context.tr('rejectionReason'),
            hintText: approved
                ? context.tr('checksCompleted')
                : context.tr('correctionNeeded'),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (!approved && value.isEmpty) return;
              Navigator.pop(context, value);
            },
            style: approved
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(
              approved ? context.tr('approve') : context.tr('reject'),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || !mounted) return;
    setState(() => _reviewing.add(item.id));
    try {
      await widget.repository.reviewEmployerSubmission(
        id: item.id,
        approved: approved,
        notes: notes,
      );
      if (!mounted) return;
      setState(() => _future = _load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? context.tr('jobApprovedPublished')
                : context.tr('jobRejectedHistory'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trFormat('adminDecisionFailed', {'error': error}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reviewing.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * .92,
      decoration: const BoxDecoration(
        color: _cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const _SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined, color: _green),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('moderationTitle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        context.tr('moderationSubtitle'),
                        style: const TextStyle(color: _muted, fontSize: 10),
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
          SwitchListTile.adaptive(
            title: Text(context.tr('pendingOnly')),
            value: _pendingOnly,
            onChanged: (value) => setState(() => _pendingOnly = value),
          ),
          Expanded(
            child: FutureBuilder<List<EmployerSubmissionData>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.trFormat('moderationLoadFailed', {
                          'error': snapshot.error ?? '',
                        }),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final items = (snapshot.data ?? const [])
                    .where((item) => !_pendingOnly || item.status == 'pending')
                    .toList();
                if (items.isEmpty) {
                  return Center(child: Text(context.tr('noJobsToModerate')));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final busy = _reviewing.contains(item.id);
                    final statusColor = switch (item.status) {
                      'approved' => _green,
                      'rejected' => Colors.red.shade700,
                      _ => const Color(0xFF9C5E19),
                    };
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: .12),
                          foregroundColor: statusColor,
                          child: Text(
                            item.companyName.isEmpty
                                ? '?'
                                : item.companyName[0],
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${item.companyName} · ${item.location} · ${context.tr(switch (item.status) {
                            'approved' => 'moderationApproved',
                            'rejected' => 'moderationRejected',
                            _ => 'moderationPending',
                          })}',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          18,
                          0,
                          18,
                          18,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(item.description),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              context.trFormat('contactLabel', {
                                'value':
                                    '${item.contactName} · ${item.contactEmail}',
                              }),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => launchUrl(
                                Uri.parse(item.sourceUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                              ),
                              label: Text(context.tr('verifyJobPage')),
                            ),
                          ),
                          if (item.reviewNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                context.trFormat('lastNote', {
                                  'note': item.reviewNotes,
                                }),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _review(item, false),
                                  icon: const Icon(Icons.close_rounded),
                                  label: Text(context.tr('reject')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => _review(item, true),
                                  icon: busy
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_rounded),
                                  label: Text(context.tr('approve')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

