import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_language.dart';

const _ink = Color(0xFF17231F);
const _green = Color(0xFF2F6B55);
const _orange = Color(0xFFE9A95B);
const _cream = Color(0xFFF7F7F2);

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const supportEmail = 'joeoumbe@gmail.com';

  String _text(AppLanguage language, String fr, String de, String en) =>
      switch (language) {
        AppLanguage.fr => fr,
        AppLanguage.de => de,
        AppLanguage.en => en,
      };

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageController.language.value;
    final sections = <(String, String)>[
      (
        _text(
          language,
          'Données traitées',
          'Verarbeitete Daten',
          'Data we process',
        ),
        _text(
          language,
          'Selon les fonctions choisies : adresse e-mail, nom, profil professionnel, compétences, formation, préférences, ville, CV envoyé volontairement, favoris, suivi des candidatures, questions adressées à Nia et signalements de réponses IA.',
          'Je nach gewählter Funktion: E-Mail-Adresse, Name, Berufsprofil, Kompetenzen, Ausbildung, Präferenzen, Stadt, freiwillig hochgeladener Lebenslauf, Favoriten, Bewerbungsstatus, Fragen an Nia und Meldungen zu KI-Antworten.',
          'Depending on the features you choose: email address, name, professional profile, skills, education, preferences, city, a voluntarily uploaded CV, favorites, application tracking, questions sent to Nia, and reports about AI answers.',
        ),
      ),
      (
        _text(language, 'Finalités', 'Zwecke', 'Why we process it'),
        _text(
          language,
          'Ces données servent à gérer le compte, analyser le CV à la demande, classer les offres, expliquer la compatibilité, préparer les candidatures, synchroniser le suivi et protéger le service contre les abus.',
          'Diese Daten werden verwendet, um das Konto zu betreiben, den Lebenslauf auf Wunsch zu analysieren, Stellen zu sortieren, die Kompatibilität zu erklären, Bewerbungen vorzubereiten, den Status zu synchronisieren und den Dienst vor Missbrauch zu schützen.',
          'We use this data to operate the account, analyze a CV on request, rank jobs, explain compatibility, prepare applications, synchronize tracking, and protect the service from abuse.',
        ),
      ),
      (
        _text(
          language,
          'Services externes',
          'Externe Dienste',
          'External services',
        ),
        _text(
          language,
          'Supabase héberge l’authentification, la base de données, les fichiers privés et les fonctions serveur dans l’Union européenne. OpenStreetMap affiche la carte. Google Gemini traite uniquement les contenus envoyés après un consentement explicite à l’analyse du CV ou à l’assistant génératif.',
          'Supabase hostet Authentifizierung, Datenbank, private Dateien und Serverfunktionen in der Europäischen Union. OpenStreetMap zeigt die Karte. Google Gemini verarbeitet nur Inhalte, die nach ausdrücklicher Einwilligung zur Lebenslaufanalyse oder zum generativen Assistenten gesendet werden.',
          'Supabase hosts authentication, the database, private files, and server functions in the European Union. OpenStreetMap displays the map. Google Gemini processes only content sent after explicit consent to CV analysis or the generative assistant.',
        ),
      ),
      (
        _text(
          language,
          'Localisation et mode invité',
          'Standort und Gastmodus',
          'Location and guest mode',
        ),
        _text(
          language,
          'Werkly fonctionne sans compte. Avec ta permission, la position approximative est convertie sur l’appareil en une ville prise en charge ; les coordonnées brutes ne sont pas enregistrées. Les données invité restent sur l’appareil.',
          'Werkly funktioniert ohne Konto. Mit deiner Erlaubnis wird der ungefähre Standort auf dem Gerät in eine unterstützte Stadt umgewandelt; rohe Koordinaten werden nicht gespeichert. Gastdaten bleiben auf dem Gerät.',
          'Werkly works without an account. With your permission, the approximate location is converted on-device into a supported city; raw coordinates are not stored. Guest data stays on the device.',
        ),
      ),
      (
        _text(
          language,
          'Conservation et suppression',
          'Speicherung und Löschung',
          'Retention and deletion',
        ),
        _text(
          language,
          'Les données du compte sont conservées pendant l’existence du compte, sauf obligation légale contraire. Tu peux supprimer définitivement le compte, le CV privé et les données associées depuis Profil → Compte et confidentialité → Supprimer mon compte et mes données.',
          'Kontodaten werden gespeichert, solange das Konto besteht, sofern keine gesetzliche Pflicht entgegensteht. Konto, privater Lebenslauf und zugehörige Daten können unter Profil → Konto und Datenschutz → Konto und Daten löschen dauerhaft entfernt werden.',
          'Account data is retained while the account exists unless law requires otherwise. You can permanently delete the account, private CV, and associated data from Profile → Account and privacy → Delete my account and data.',
        ),
      ),
      (
        _text(
          language,
          'Recommandations automatisées',
          'Automatisierte Empfehlungen',
          'Automated recommendations',
        ),
        _text(
          language,
          'Les scores de compatibilité sont des recommandations informatives basées sur le profil et les préférences. Ils ne constituent pas une décision de recrutement et peuvent être imparfaits. Les réponses IA peuvent être signalées directement dans la conversation.',
          'Kompatibilitätswerte sind informative Empfehlungen auf Basis von Profil und Präferenzen. Sie sind keine Einstellungsentscheidung und können fehlerhaft sein. KI-Antworten können direkt in der Unterhaltung gemeldet werden.',
          'Compatibility scores are informative recommendations based on profile and preferences. They are not hiring decisions and may be imperfect. AI answers can be reported directly in the conversation.',
        ),
      ),
      (
        _text(language, 'Tes droits', 'Deine Rechte', 'Your rights'),
        _text(
          language,
          'Tu peux demander l’accès, la rectification, la suppression, la limitation ou la portabilité de tes données et retirer un consentement facultatif pour l’avenir.',
          'Du kannst Auskunft, Berichtigung, Löschung, Einschränkung oder Übertragbarkeit deiner Daten verlangen und eine optionale Einwilligung für die Zukunft widerrufen.',
          'You can request access, correction, deletion, restriction, or portability of your data and withdraw optional consent for the future.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _ink,
        title: Text(context.tr('privacyPolicy')),
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 80),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Text(
                        'W',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('privacyPolicy'),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _text(
                        language,
                        'Dernière mise à jour : 11 août 2026',
                        'Zuletzt aktualisiert: 11. August 2026',
                        'Last updated: 11 August 2026',
                      ),
                      style: const TextStyle(color: _green),
                    ),
                    const SizedBox(height: 22),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _text(
                            language,
                            'Werkly aide les étudiants à trouver un poste de Werkstudent en Allemagne et à préparer leur candidature. La création d’un compte, l’envoi d’un CV, la localisation et l’IA générative sont facultatifs.',
                            'Werkly hilft Studierenden, Werkstudentenstellen in Deutschland zu finden und Bewerbungen vorzubereiten. Konto, Lebenslauf-Upload, Standort und generative KI sind optional.',
                            'Werkly helps students find working-student jobs in Germany and prepare applications. Creating an account, uploading a CV, location, and generative AI are optional.',
                          ),
                          style: const TextStyle(height: 1.55),
                        ),
                      ),
                    ),
                    for (final section in sections) ...[
                      const SizedBox(height: 28),
                      Text(
                        section.$1,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(section.$2, style: const TextStyle(height: 1.6)),
                    ],
                    const SizedBox(height: 30),
                    Card(
                      color: const Color(0xFFFFF1DD),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(
                                language,
                                'Responsable et contact',
                                'Verantwortlicher und Kontakt',
                                'Controller and contact',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tchinda Oumbe Joe Brayan\n'
                              'Engsbachstraße 58\n'
                              '57076 Siegen, Germany',
                              style: TextStyle(height: 1.5),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () => launchUrl(
                                Uri(
                                  scheme: 'mailto',
                                  path: supportEmail,
                                  queryParameters: {
                                    'subject': _text(
                                      language,
                                      'Werkly – demande relative à la confidentialité',
                                      'Werkly – Datenschutzanfrage',
                                      'Werkly privacy request',
                                    ),
                                  },
                                ),
                              ),
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: const Text(supportEmail),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
