import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/app_language.dart';
import 'compatibility_service.dart';

class ApplicationKitData {
  const ApplicationKitData({
    required this.applicantName,
    required this.email,
    required this.phone,
    required this.address,
    required this.degree,
    required this.university,
    required this.city,
    required this.summary,
    required this.profileSkills,
    required this.jobTitle,
    required this.company,
    required this.jobLocation,
    required this.jobTags,
    required this.sourceUrl,
    required this.coverLetter,
    required this.generatedAt,
    required this.language,
  });

  final String applicantName;
  final String email;
  final String phone;
  final String address;
  final String degree;
  final String university;
  final String city;
  final String summary;
  final List<String> profileSkills;
  final String jobTitle;
  final String company;
  final String jobLocation;
  final List<String> jobTags;
  final String sourceUrl;
  final String coverLetter;
  final DateTime generatedAt;
  final AppLanguage language;

  // Boilerplate tags ("Werkstudent", "IT"...) are never real skills, so they
  // should never show up as either a match or something to add to the CV.
  List<String> get _realJobTags =>
      jobTags.where((tag) => !isGenericJobTag(tag)).toList();

  List<String> get matchedSkills => _realJobTags
      .where(
        (tag) => profileSkills.any(
          (skill) =>
              skill.toLowerCase().contains(tag.toLowerCase()) ||
              tag.toLowerCase().contains(skill.toLowerCase()),
        ),
      )
      .toList();

  List<String> get missingSkills =>
      _realJobTags.where((tag) => !matchedSkills.contains(tag)).toList();
}

class ApplicationKitService {
  const ApplicationKitService._();

  /// Shared document/theme setup for both [buildPdf] and [buildLetterPdf], so
  /// the letter-only PDF looks and reads identically to the letter page
  /// inside the full kit rather than drifting into a second copy.
  static Future<
    ({
      pw.Document document,
      pw.ThemeData theme,
      String generatedDate,
      AppStrings strings,
    })
  >
  _newDocument(ApplicationKitData data) async {
    final strings = AppStrings(data.language);
    final regularData = await rootBundle.load(
      'assets/fonts/Poppins-Regular.ttf',
    );
    final semiboldData = await rootBundle.load(
      'assets/fonts/Poppins-SemiBold.ttf',
    );
    final regularFont = pw.Font.ttf(regularData);
    final semiboldFont = pw.Font.ttf(semiboldData);
    final document = pw.Document(
      title: strings.format('pdfDocumentTitle', {
        'job': data.jobTitle,
        'company': data.company,
      }),
      author: data.applicantName,
      creator: 'Werkly',
      subject: strings.get('pdfSubject'),
    );
    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: semiboldFont,
      italic: regularFont,
      boldItalic: semiboldFont,
    );
    return (
      document: document,
      theme: theme,
      generatedDate: _date(data.generatedAt),
      strings: strings,
    );
  }

  /// The letter's own content -- sender info, a proper subject line, then
  /// the paragraphs -- as a flat widget list so a [pw.MultiPage] can break
  /// between them. Deliberately has no Werkly branding: this is the
  /// applicant's own letter, not a Werkly document, and should never look
  /// like one whether it's read as page 1 of the full kit or downloaded on
  /// its own. The subject line ("Bewerbung als ...") follows the standard
  /// German Anschreiben convention (per Bundesagentur für Arbeit guidance)
  /// instead of the earlier stylized info card.
  static List<pw.Widget> _letterWidgets(
    AppStrings strings,
    ApplicationKitData data,
  ) => [
    pw.Text(
      data.applicantName,
      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
    ),
    if (data.address.isNotEmpty) pw.Text(data.address),
    if (data.phone.isNotEmpty) pw.Text(data.phone),
    if (data.email.isNotEmpty) pw.Text(data.email),
    if (data.city.isNotEmpty) pw.Text(data.city),
    pw.SizedBox(height: 26),
    pw.Text(
      strings.format('pdfObjectiveText', {
        'job': data.jobTitle,
        'company': data.company,
      }),
      style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 20),
    for (final paragraph in data.coverLetter.split('\n\n')) ...[
      pw.Text(
        paragraph.trim(),
        style: const pw.TextStyle(fontSize: 11.2, lineSpacing: 4),
        textAlign: pw.TextAlign.justify,
      ),
      pw.SizedBox(height: 13),
    ],
  ];

  /// Same content as [_letterWidgets], boxed into one widget for the full
  /// kit's fixed-height page 1, which only ever holds the bounded-length
  /// static template so overflow isn't a concern there.
  static pw.Widget _letterBody(AppStrings strings, ApplicationKitData data) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: _letterWidgets(strings, data),
      );

  /// Page 1 of the full kit: same letter body, but framed with the Werkly
  /// header/footer since the kit as a whole is explicitly a Werkly-prepared
  /// bundle (page 2 is a Werkly profile summary, never meant to be sent as
  /// a document in its own right).
  static pw.Widget _letterPageContent(
    AppStrings strings,
    ApplicationKitData data,
    String generatedDate,
  ) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _header(strings.get('pdfCoverLetter'), generatedDate),
      pw.SizedBox(height: 28),
      _letterBody(strings, data),
      pw.Spacer(),
      _footer(strings.get('pdfFooter')),
    ],
  );

  /// The standalone letter download: just the letter, formatted like a real
  /// cover letter (city + date in the corner, the way a German Anschreiben
  /// conventionally opens) rather than under a Werkly letterhead -- this is
  /// the file someone might actually send to an employer as-is. Returned as
  /// a flat list (not one boxed widget) so [pw.MultiPage] can flow it onto
  /// as many pages as the letter actually needs instead of clipping it.
  static List<pw.Widget> _standaloneLetterWidgets(
    AppStrings strings,
    ApplicationKitData data,
    String generatedDate,
  ) => [
    pw.Align(
      alignment: pw.Alignment.topRight,
      child: pw.Text(
        [
          data.city,
          generatedDate,
        ].where((value) => value.trim().isNotEmpty).join(', '),
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColor.fromInt(0xFF718079),
        ),
      ),
    ),
    pw.SizedBox(height: 20),
    ..._letterWidgets(strings, data),
  ];

  /// A PDF with just the cover letter -- for downloading the letter on its
  /// own, separate from the full application kit. Paginates across multiple
  /// pages (via [pw.MultiPage]) since a letter's length isn't bounded the
  /// way the kit's static template is.
  static Future<Uint8List> buildLetterPdf(ApplicationKitData data) async {
    final setup = await _newDocument(data);
    setup.document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 42),
        theme: setup.theme,
        build: (context) => _standaloneLetterWidgets(
          setup.strings,
          data,
          setup.generatedDate,
        ),
      ),
    );
    return setup.document.save();
  }

  static Future<Uint8List> buildPdf(ApplicationKitData data) async {
    final setup = await _newDocument(data);
    final document = setup.document;
    final theme = setup.theme;
    final strings = setup.strings;
    final generatedDate = setup.generatedDate;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 42),
        theme: theme,
        build: (context) =>
            _letterPageContent(strings, data, generatedDate),
      ),
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(48, 44, 48, 42),
        theme: theme,
        header: (_) =>
            _header(strings.get('pdfTailoredProfile'), generatedDate),
        footer: (_) => _footer(strings.get('pdfFooter')),
        build: (context) => [
          pw.SizedBox(height: 24),
          pw.Text(
            data.applicantName,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            [
              data.degree,
              data.university,
            ].where((value) => value.trim().isNotEmpty).join(' - '),
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFF557067),
              fontSize: 11,
            ),
          ),
          pw.SizedBox(height: 22),
          _sectionTitle(strings.get('pdfObjective')),
          pw.Text(
            strings.format('pdfObjectiveText', {
              'job': data.jobTitle,
              'company': data.company,
            }),
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle(strings.get('pdfProfessionalProfile')),
          pw.Text(
            data.summary.trim().isEmpty
                ? strings.get('pdfStudentFallback')
                : data.summary.trim(),
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
          ),
          pw.SizedBox(height: 18),
          _skillSection(
            strings.get('pdfMatchingSkills'),
            data.matchedSkills,
            emptyText: strings.get('pdfNoExactMatch'),
          ),
          pw.SizedBox(height: 18),
          _skillSection(
            strings.get('pdfOtherSkills'),
            data.profileSkills,
            emptyText: strings.get('pdfNoSkills'),
          ),
          if (data.missingSkills.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle(strings.get('pdfKeywordsReview')),
            pw.Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.missingSkills
                  .map(
                    (skill) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFFF4E4),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        skill,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          pw.SizedBox(height: 22),
          _sectionTitle(strings.get('pdfBeforeSending')),
          for (final item in [
            strings.get('pdfChecklistCompany'),
            strings.get('pdfChecklistProjects'),
            strings.get('pdfChecklistAttachments'),
            strings.get('pdfChecklistAccuracy'),
          ])
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 10,
                    height: 10,
                    margin: const pw.EdgeInsets.only(top: 2, right: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: const PdfColor.fromInt(0xFF2F6B55),
                      ),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      item,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          if (data.sourceUrl.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle(strings.get('pdfOriginalJob')),
            pw.UrlLink(
              destination: data.sourceUrl,
              child: pw.Text(
                data.sourceUrl,
                style: const pw.TextStyle(
                  color: PdfColor.fromInt(0xFF2F6B55),
                  decoration: pw.TextDecoration.underline,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _header(String title, String date) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Row(
        children: [
          pw.Container(
            width: 24,
            height: 24,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFE9A95B),
              borderRadius: pw.BorderRadius.circular(7),
            ),
            child: pw.Text(
              'W',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            'werkly',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF2F6B55),
            ),
          ),
          pw.Text(date, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    ],
  );

  static pw.Widget _footer(String text) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PdfColor.fromInt(0xFFE7EAE4)),
      ),
    ),
    child: pw.Text(
      text,
      textAlign: pw.TextAlign.center,
      style: const pw.TextStyle(
        color: PdfColor.fromInt(0xFF718079),
        fontSize: 8,
      ),
    ),
  );

  static pw.Widget _sectionTitle(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: const PdfColor.fromInt(0xFF2F6B55),
      ),
    ),
  );

  static pw.Widget _skillSection(
    String title,
    List<String> skills, {
    required String emptyText,
  }) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle(title),
      if (skills.isEmpty)
        pw.Text(emptyText, style: const pw.TextStyle(fontSize: 10))
      else
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills
              .toSet()
              .map(
                (skill) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF0F6F2),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(skill, style: const pw.TextStyle(fontSize: 9)),
                ),
              )
              .toList(),
        ),
    ],
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
