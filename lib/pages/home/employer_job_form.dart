part of '../home_page.dart';

class _EmployerJobDraft {
  const _EmployerJobDraft({
    required this.companyName,
    required this.contactName,
    required this.contactEmail,
    required this.title,
    required this.location,
    required this.remoteType,
    required this.sourceUrl,
    required this.tags,
    required this.description,
    this.salaryMin,
    this.salaryMax,
  });

  final String companyName;
  final String contactName;
  final String contactEmail;
  final String title;
  final String location;
  final String remoteType;
  final double? salaryMin;
  final double? salaryMax;
  final String sourceUrl;
  final List<String> tags;
  final String description;
}

class _EmployerJobForm extends StatefulWidget {
  const _EmployerJobForm({required this.initialEmail});

  final String initialEmail;

  @override
  State<_EmployerJobForm> createState() => _EmployerJobFormState();
}

class _EmployerJobFormState extends State<_EmployerJobForm> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  late final TextEditingController _email;
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  final _url = TextEditingController();
  final _tags = TextEditingController();
  final _description = TextEditingController();
  String _remoteType = 'onsite';

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _email.dispose();
    _title.dispose();
    _location.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
    _url.dispose();
    _tags.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? context.tr('requiredField')
        : null;
  }

  double? _number(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _EmployerJobDraft(
        companyName: _company.text.trim(),
        contactName: _contact.text.trim(),
        contactEmail: _email.text.trim(),
        title: _title.text.trim(),
        location: _location.text.trim(),
        remoteType: _remoteType,
        salaryMin: _number(_salaryMin.text),
        salaryMax: _number(_salaryMax.text),
        sourceUrl: _url.text.trim(),
        tags: _tags.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('publishWerkstudentJob')),
      content: SizedBox(
        width: 590,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .68,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('employerSubmissionNotice'),
                    style: const TextStyle(color: _muted, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _company,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('company')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _contact,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('contactPerson')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final required = _required(value);
                      if (required != null) return required;
                      return value!.contains('@')
                          ? null
                          : context.tr('invalidEmail');
                    },
                    decoration: InputDecoration(
                      labelText: '${context.tr('professionalEmail')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _title,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('jobTitle')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _location,
                    validator: _required,
                    decoration: InputDecoration(
                      labelText: '${context.tr('germanCity')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _remoteType,
                    decoration: InputDecoration(
                      labelText: context.tr('workMode'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'onsite',
                        child: Text(context.tr('onSite')),
                      ),
                      DropdownMenuItem(
                        value: 'hybrid',
                        child: Text(context.tr('hybrid')),
                      ),
                      DropdownMenuItem(
                        value: 'remote',
                        child: Text(context.tr('remote')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _remoteType = value ?? _remoteType),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMin,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              value!.trim().isEmpty || _number(value) != null
                              ? null
                              : context.tr('invalidNumber'),
                          decoration: InputDecoration(
                            labelText: context.tr('minimumSalary'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _salaryMax,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value!.trim().isEmpty) return null;
                            final maximum = _number(value);
                            if (maximum == null) {
                              return context.tr('invalidNumber');
                            }
                            final minimum = _number(_salaryMin.text);
                            return minimum != null && maximum < minimum
                                ? context.tr('belowMinimum')
                                : null;
                          },
                          decoration: InputDecoration(
                            labelText: context.tr('maximumSalary'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      final required = _required(value);
                      if (required != null) return required;
                      final uri = Uri.tryParse(value!.trim());
                      return uri != null && uri.scheme == 'https'
                          ? null
                          : context.tr('httpsRequired');
                    },
                    decoration: InputDecoration(
                      labelText: '${context.tr('officialApplicationLink')} *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _tags,
                    decoration: InputDecoration(
                      labelText: context.tr('jobSkills'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 7,
                    validator: (value) => (value?.trim().length ?? 0) < 40
                        ? context.tr('minimumDescription')
                        : null,
                    decoration: InputDecoration(
                      labelText: '${context.tr('jobDescription')} *',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: Text(context.tr('submitForReview')),
        ),
      ],
    );
  }
}

