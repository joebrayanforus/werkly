import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { fr, de, en }

extension AppLanguageDetails on AppLanguage {
  String get code => name;

  Locale get locale => Locale(code);

  String get label => switch (this) {
    AppLanguage.fr => 'Français',
    AppLanguage.de => 'Deutsch',
    AppLanguage.en => 'English',
  };

  String get shortLabel => code.toUpperCase();
}

class AppLanguageController {
  AppLanguageController._();

  static const _storageKey = 'werkly_app_language';
  static final ValueNotifier<AppLanguage> language = ValueNotifier<AppLanguage>(
    AppLanguage.en,
  );

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_storageKey);
    language.value = AppLanguage.values.firstWhere(
      (item) => item.code == saved,
      orElse: () => AppLanguage.en,
    );
  }

  static Future<void> setLanguage(AppLanguage value) async {
    if (language.value != value) language.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, value.code);
  }
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  static const Map<String, List<String>> _values = {
    'appTitle': [
      'Werkly — Ton job étudiant, mieux ciblé',
      'Werkly — Dein Studentenjob, besser abgestimmt',
      'Werkly — Your student job, better matched',
    ],
    'home': ['Accueil', 'Start', 'Home'],
    'dashboard': ['Dashboard', 'Übersicht', 'Dashboard'],
    'jobs': ['Offres', 'Jobs', 'Jobs'],
    'map': ['Carte', 'Karte', 'Map'],
    'tracking': ['Suivi', 'Bewerbungen', 'Tracking'],
    'applications': [
      'Mes candidatures',
      'Meine Bewerbungen',
      'My applications',
    ],
    'profile': ['Profil', 'Profil', 'Profile'],
    'myProfile': ['Mon profil', 'Mein Profil', 'My profile'],
    'guestMode': ['Mode invité', 'Gastmodus', 'Guest mode'],
    'searchHint': [
      'Métier, entreprise, compétence…',
      'Job, Unternehmen, Kompetenz…',
      'Role, company, skill…',
    ],
    'profileCompletion': [
      'Profil à {score} %',
      'Profil zu {score} %',
      'Profile {score}% complete',
    ],
    'profileTip': [
      'Ajoute tes projets pour améliorer tes matchs.',
      'Füge Projekte hinzu, um deine Matches zu verbessern.',
      'Add projects to improve your matches.',
    ],
    'professionalProfile': [
      'Ton profil professionnel',
      'Dein berufliches Profil',
      'Your professional profile',
    ],
    'professionalProfileSubtitle': [
      'Construit à partir de ton CV, de tes compétences et de tes préférences',
      'Erstellt aus deinem Lebenslauf, deinen Kompetenzen und Präferenzen',
      'Built from your CV, skills and preferences',
    ],
    'addEducationCity': [
      'Ajoute ta formation et ta ville',
      'Füge Studium und Stadt hinzu',
      'Add your education and city',
    ],
    'editProfile': ['Modifier le profil', 'Profil bearbeiten', 'Edit profile'],
    'addCv': ['Ajouter un CV', 'Lebenslauf hinzufügen', 'Add CV'],
    'editPreferences': [
      'Modifier mes préférences',
      'Präferenzen bearbeiten',
      'Edit preferences',
    ],
    'aiSummary': ['Résumé IA', 'KI-Zusammenfassung', 'AI summary'],
    'addSummary': [
      'Ajoute un résumé professionnel pour présenter clairement ton objectif.',
      'Füge eine berufliche Zusammenfassung hinzu, um dein Ziel klar darzustellen.',
      'Add a professional summary to clearly present your goal.',
    ],
    'detectedSkills': [
      'Compétences détectées',
      'Erkannte Kompetenzen',
      'Detected skills',
    ],
    'language': ['Langue de l’application', 'App-Sprache', 'App language'],
    'languageHelp': [
      'Tu peux la modifier à tout moment.',
      'Du kannst sie jederzeit ändern.',
      'You can change it at any time.',
    ],
    'cvAnalysis': [
      'Analyse réelle du CV',
      'Echte Lebenslaufanalyse',
      'Real CV analysis',
    ],
    'extractingCv': [
      'Extraction des informations en cours…',
      'Informationen werden extrahiert…',
      'Extracting information…',
    ],
    'cvScanPreparing': [
      'Préparation sécurisée du document',
      'Dokument wird sicher vorbereitet',
      'Securely preparing the document',
    ],
    'cvScanReading': [
      'Lecture du contenu du CV',
      'Lebenslauf wird gelesen',
      'Reading the CV content',
    ],
    'cvScanSkills': [
      'Détection des compétences et des langues',
      'Kompetenzen und Sprachen werden erkannt',
      'Detecting skills and languages',
    ],
    'cvScanProfile': [
      'Construction de ton profil professionnel',
      'Dein berufliches Profil wird erstellt',
      'Building your professional profile',
    ],
    'cvScanWait': [
      'Garde cette page ouverte. L’analyse peut prendre jusqu’à une minute.',
      'Lass diese Seite geöffnet. Die Analyse kann bis zu einer Minute dauern.',
      'Keep this page open. Analysis can take up to one minute.',
    ],
    'cvResultsVerify': [
      'Résultats extraits du document · à vérifier',
      'Aus dem Dokument extrahiert · bitte prüfen',
      'Results extracted from the document · please review',
    ],
    'cvLastFailed': [
      'La dernière analyse a échoué',
      'Die letzte Analyse ist fehlgeschlagen',
      'The last analysis failed',
    ],
    'cvAddPdf': [
      'Ajoute un PDF avec du texte sélectionnable pour commencer',
      'Füge zum Start eine PDF mit auswählbarem Text hinzu',
      'Add a PDF with selectable text to get started',
    ],
    'cvStored': [
      "Le CV est stocké mais n'a pas encore été analysé",
      'Der Lebenslauf ist gespeichert, aber noch nicht analysiert',
      'The CV is stored but has not been analyzed yet',
    ],
    'addMyCv': ['Ajouter mon CV', 'Lebenslauf hinzufügen', 'Add my CV'],
    'viewMyCv': ['Voir mon CV', 'Meinen Lebenslauf ansehen', 'View my CV'],
    'viewCvFailed': [
      "Impossible d’ouvrir le CV : {error}",
      'Der Lebenslauf konnte nicht geöffnet werden: {error}',
      'Could not open the CV: {error}',
    ],
    'reanalyze': ['Réanalyser', 'Erneut analysieren', 'Analyze again'],
    'analyze': ['Analyser', 'Analysieren', 'Analyze'],
    'skills': ['Compétences', 'Kompetenzen', 'Skills'],
    'languages': ['Langues', 'Sprachen', 'Languages'],
    'experiences': ['Expériences', 'Erfahrungen', 'Experience'],
    'nothingFound': [
      'Aucune information trouvée dans le document.',
      'Keine Informationen im Dokument gefunden.',
      'No information found in the document.',
    ],
    'cvScore': ['Score de ton CV', 'Dein Lebenslauf-Score', 'Your CV score'],
    'profileSolid': [
      'Ton profil est solide. Vérifie les recommandations avant chaque candidature.',
      'Dein Profil ist stark. Prüfe die Empfehlungen vor jeder Bewerbung.',
      'Your profile is strong. Review the recommendations before each application.',
    ],
    'completeProfile': [
      'Complète les éléments manquants pour améliorer la qualité de tes candidatures.',
      'Ergänze fehlende Angaben, um deine Bewerbungen zu verbessern.',
      'Complete the missing details to improve your applications.',
    ],
    'optimizeAi': [
      'Optimiser avec l’IA',
      'Mit KI optimieren',
      'Optimize with AI',
    ],
    'nextImprovements': [
      'Prochaines améliorations',
      'Nächste Verbesserungen',
      'Next improvements',
    ],
    'clearProfile': [
      'Profil professionnel clair',
      'Klares berufliches Profil',
      'Clear professional profile',
    ],
    'skillsProvided': [
      'Compétences renseignées',
      'Kompetenzen angegeben',
      'Skills provided',
    ],
    'educationUniversity': [
      'Formation et université',
      'Studium und Hochschule',
      'Education and university',
    ],
    'germanLevel': [
      "Préciser le niveau d'allemand",
      'Deutschniveau angeben',
      'Specify German level',
    ],
    'cvAdded': [
      'CV ajouté au profil',
      'Lebenslauf im Profil',
      'CV added to profile',
    ],
    'accountPrivacy': [
      'Compte et confidentialité',
      'Konto und Datenschutz',
      'Account and privacy',
    ],
    'privacyPolicy': [
      'Politique de confidentialité',
      'Datenschutzerklärung',
      'Privacy policy',
    ],
    'readPrivacyPolicy': [
      'Lire la politique de confidentialité',
      'Datenschutzerklärung lesen',
      'Read the privacy policy',
    ],
    'guestNavigation': [
      'Navigation sans compte',
      'Nutzung ohne Konto',
      'Browsing without an account',
    ],
    'moderateJobs': [
      'Modérer les offres entreprises',
      'Arbeitgeberangebote moderieren',
      'Moderate employer jobs',
    ],
    'signInSync': [
      'Se connecter pour synchroniser',
      'Anmelden und synchronisieren',
      'Sign in to sync',
    ],
    'signOut': ['Se déconnecter', 'Abmelden', 'Sign out'],
    'legal': [
      'Licences et mentions légales',
      'Lizenzen und Rechtliches',
      'Licenses and legal notices',
    ],
    'deleteAccount': [
      'Supprimer mon compte et mes données',
      'Konto und Daten löschen',
      'Delete my account and data',
    ],
    'bestMatches': [
      'Tes meilleurs matchs',
      'Deine besten Matches',
      'Your best matches',
    ],
    'matchesSubtitle': [
      'Triés selon ton CV, tes préférences et ton trajet',
      'Sortiert nach Lebenslauf, Präferenzen und Arbeitsweg',
      'Ranked by your CV, preferences and commute',
    ],
    'seeJobs': [
      'Voir les {count} offres',
      '{count} Jobs ansehen',
      'See {count} jobs',
    ],
    'jobsUpdated': ['Offres actualisées', 'Jobs aktualisiert', 'Jobs updated'],
    'newJobsToday': [
      '{count} nouvelle(s) offre(s) aujourd’hui',
      '{count} neue Jobangebote heute',
      '{count} new jobs today',
    ],
    'welcome': ['Bonjour, {name} !', 'Hallo, {name}!', 'Hello, {name}!'],
    'welcomeSubtitle': [
      'Ton prochain Werkstudent job est peut-être déjà là.\nTes recommandations ont été actualisées.',
      'Dein nächster Werkstudentenjob ist vielleicht schon da.\nDeine Empfehlungen wurden aktualisiert.',
      'Your next working-student job may already be here.\nYour recommendations have been updated.',
    ],
    'exploreMatches': [
      'Explorer mes matchs',
      'Meine Matches ansehen',
      'Explore my matches',
    ],
    'radius': ['rayon', 'Umkreis', 'radius'],
    'openMap': ['Ouvrir la carte', 'Karte öffnen', 'Open map'],
    'skip': ['Passer', 'Überspringen', 'Skip'],
    'next': ['Suivant', 'Weiter', 'Next'],
    'start': ['Commencer', 'Loslegen', 'Get started'],
    'tutorialLanguageTitle': [
      'Choisis ta langue',
      'Wähle deine Sprache',
      'Choose your language',
    ],
    'tutorialLanguageBody': [
      'Werkly adaptera toute son interface. Tu pourras changer ce choix dans ton profil.',
      'Werkly passt die gesamte Oberfläche an. Du kannst die Sprache später im Profil ändern.',
      'Werkly will adapt the whole interface. You can change this later in your profile.',
    ],
    'tutorialMatchesTitle': [
      'Des offres vraiment adaptées',
      'Wirklich passende Jobs',
      'Jobs that truly fit',
    ],
    'tutorialMatchesBody': [
      'Ton CV et tes préférences alimentent un score explicable, sans note inventée.',
      'Lebenslauf und Präferenzen ergeben einen erklärbaren Score – ohne erfundene Bewertung.',
      'Your CV and preferences create an explainable score with no invented rating.',
    ],
    'tutorialMapTitle': [
      'La distance qui compte vraiment',
      'Die Entfernung, die wirklich zählt',
      'Distance that actually matters',
    ],
    'tutorialMapBody': [
      'Explore les offres sur la carte et compare le trajet réel depuis ta ville.',
      'Entdecke Jobs auf der Karte und vergleiche den echten Arbeitsweg ab deiner Stadt.',
      'Explore jobs on the map and compare the real commute from your city.',
    ],
    'tutorialKitTitle': [
      'De l’offre à l’entretien',
      'Vom Job bis zum Gespräch',
      'From job to interview',
    ],
    'tutorialKitBody': [
      'Prépare ton CV, ta lettre, ton entretien et suis chaque candidature au même endroit.',
      'Bereite Lebenslauf, Anschreiben und Gespräch vor und verfolge jede Bewerbung zentral.',
      'Prepare your CV, letter and interview, then track every application in one place.',
    ],
    'tutorialProgress': [
      'Étape {current} sur {total}',
      'Schritt {current} von {total}',
      'Step {current} of {total}',
    ],
    'welcomeWerkly': [
      'Bienvenue sur Werkly',
      'Willkommen bei Werkly',
      'Welcome to Werkly',
    ],
    'chooseHowToPersonalize': [
      'Choisis comment personnaliser tes offres. Tu peux tout modifier plus tard.',
      'Wähle, wie deine Jobs personalisiert werden. Du kannst später alles ändern.',
      'Choose how to personalize your jobs. You can change everything later.',
    ],
    'choosePreferences': [
      'Choisir mes préférences',
      'Präferenzen auswählen',
      'Choose my preferences',
    ],
    'choosePreferencesBody': [
      'Domaines, ville, télétravail, heures par semaine et niveau d’allemand.',
      'Bereiche, Stadt, Homeoffice, Wochenstunden und Deutschniveau.',
      'Fields, city, remote work, weekly hours and German level.',
    ],
    'twoMinutes': ['2 min', '2 Min.', '2 min'],
    'importAnalyzeCv': [
      'Importer et analyser mon CV',
      'Lebenslauf importieren und analysieren',
      'Import and analyze my CV',
    ],
    'importAnalyzeCvBody': [
      'L’IA extrait les compétences et construit le profil après ton consentement.',
      'Die KI extrahiert nach deiner Zustimmung Kompetenzen und erstellt dein Profil.',
      'AI extracts skills and builds your profile after your consent.',
    ],
    'secureAccountRequired': [
      'Compte sécurisé requis',
      'Sicheres Konto erforderlich',
      'Secure account required',
    ],
    'exploreFirst': [
      'Découvrir les offres d’abord',
      'Zuerst Jobs entdecken',
      'Explore jobs first',
    ],
    'exploreFirstBody': [
      'Accède immédiatement à l’application sans créer de compte.',
      'Nutze die App sofort, ohne ein Konto zu erstellen.',
      'Open the app immediately without creating an account.',
    ],
    'guestBadge': ['Mode invité', 'Gastmodus', 'Guest mode'],
    'noAutomaticApplication': [
      'Aucune candidature n’est envoyée automatiquement.',
      'Keine Bewerbung wird automatisch versendet.',
      'No application is sent automatically.',
    ],
    'preferencesTitle': [
      'Tes préférences',
      'Deine Präferenzen',
      'Your preferences',
    ],
    'preferencesPurpose': [
      'Elles servent au classement, jamais à exclure automatiquement une offre.',
      'Sie beeinflussen die Sortierung, schließen aber nie automatisch einen Job aus.',
      'They affect ranking but never automatically exclude a job.',
    ],
    'searchCity': ['Ville de recherche', 'Suchstadt', 'Search city'],
    'cityHint': [
      'Ex. Köln, Berlin, Siegen…',
      'Z. B. Köln, Berlin, Siegen…',
      'E.g. Köln, Berlin, Siegen…',
    ],
    'clearCity': ['Effacer la ville', 'Stadt löschen', 'Clear city'],
    'locatingCity': [
      'Recherche de ta ville…',
      'Deine Stadt wird gesucht…',
      'Finding your city…',
    ],
    'useCurrentLocation': [
      'Utiliser ma position actuelle',
      'Aktuellen Standort verwenden',
      'Use my current location',
    ],
    'approximateCityOnly': [
      'Seule la ville approximative est enregistrée, jamais ta position exacte.',
      'Gespeichert wird nur die ungefähre Stadt, niemals dein genauer Standort.',
      'Only the approximate city is saved, never your exact location.',
    ],
    'domainsQuestion': [
      'Quels domaines t’intéressent ?',
      'Welche Bereiche interessieren dich?',
      'Which fields interest you?',
    ],
    'chooseAtLeastOne': [
      'Choisis-en au moins un.',
      'Wähle mindestens einen aus.',
      'Choose at least one.',
    ],
    'domainRequired': [
      'Sélectionne au moins un domaine ou « Tous domaines ».',
      'Wähle mindestens einen Bereich oder „Alle Bereiche“.',
      'Select at least one field or “All fields”.',
    ],
    'preferredWorkMode': [
      'Mode de travail préféré',
      'Bevorzugtes Arbeitsmodell',
      'Preferred work mode',
    ],
    'weeklyAvailability': [
      'Disponibilité hebdomadaire',
      'Wöchentliche Verfügbarkeit',
      'Weekly availability',
    ],
    'germanLevelChoice': ['Niveau d’allemand', 'Deutschniveau', 'German level'],
    'germanLevelHelp': [
      'Tu pourras le corriger après l’analyse du CV.',
      'Du kannst es nach der Lebenslaufanalyse korrigieren.',
      'You can correct it after the CV analysis.',
    ],
    'searchRadius': [
      'Rayon de recherche : {radius} km',
      'Suchradius: {radius} km',
      'Search radius: {radius} km',
    ],
    'distantJobsVisible': [
      'Les offres à distance restent visibles.',
      'Weiter entfernte Jobs bleiben sichtbar.',
      'More distant jobs remain visible.',
    ],
    'personalizeJobs': [
      'Personnaliser mes offres',
      'Jobs personalisieren',
      'Personalize my jobs',
    ],
    'noCitySuggestion': [
      'Aucune suggestion. Tu peux quand même enregistrer cette ville manuellement.',
      'Kein Vorschlag. Du kannst die Stadt trotzdem manuell speichern.',
      'No suggestion. You can still save this city manually.',
    ],
    'locationServiceOff': [
      'Active la localisation de ton appareil puis réessaie.',
      'Aktiviere die Standortdienste und versuche es erneut.',
      'Enable location services and try again.',
    ],
    'locationDenied': [
      'Autorisation refusée. Tu peux toujours choisir une ville manuellement.',
      'Berechtigung abgelehnt. Du kannst eine Stadt weiterhin manuell wählen.',
      'Permission denied. You can still choose a city manually.',
    ],
    'locationBlocked': [
      'La localisation est bloquée dans les réglages du navigateur ou de l’appareil.',
      'Der Standort ist in den Browser- oder Geräteeinstellungen blockiert.',
      'Location is blocked in your browser or device settings.',
    ],
    'outsideGermany': [
      'Ta position semble être hors d’Allemagne. Choisis une ville manuellement.',
      'Dein Standort scheint außerhalb Deutschlands zu liegen. Wähle eine Stadt manuell.',
      'Your location seems to be outside Germany. Choose a city manually.',
    ],
    'locationUnavailable': [
      'Position indisponible. Vérifie l’autorisation ou choisis une ville.',
      'Standort nicht verfügbar. Prüfe die Berechtigung oder wähle eine Stadt.',
      'Location unavailable. Check permission or choose a city.',
    ],
    'chooseCityRequired': [
      'Choisis une ville ou utilise ta position actuelle.',
      'Wähle eine Stadt oder verwende deinen aktuellen Standort.',
      'Choose a city or use your current location.',
    ],
    'preferencesSaved': [
      'Tes offres sont maintenant personnalisées.',
      'Deine Jobs sind jetzt personalisiert.',
      'Your jobs are now personalized.',
    ],
    'preferencesSaveFailed': [
      'Préférences non enregistrées : {error}',
      'Präferenzen nicht gespeichert: {error}',
      'Preferences not saved: {error}',
    ],
    'profileCardTitle': ['Ton profil', 'Dein Profil', 'Your profile'],
    'profileIncomplete': [
      'Profil à compléter',
      'Profil vervollständigen',
      'Complete your profile',
    ],
    'skillsSought': [
      'Compétences recherchées dans ces offres',
      'In diesen Jobs gesuchte Kompetenzen',
      'Skills sought in these jobs',
    ],
    'skillsPresence': [
      'Présence de tes compétences dans ces offres',
      'Deine Kompetenzen in diesen Jobs',
      'Your skills across these jobs',
    ],
    'noData': [
      'Aucune donnée disponible.',
      'Keine Daten verfügbar.',
      'No data available.',
    ],
    'jobCount': ['{count} offre(s)', '{count} Jobangebote', '{count} jobs'],
    'addSkillsForScores': [
      'Ajoute tes compétences dans le profil pour calculer des scores personnalisés.',
      'Füge Kompetenzen zum Profil hinzu, um persönliche Scores zu berechnen.',
      'Add skills to your profile to calculate personalized scores.',
    ],
    'scoreUsesProfile': [
      'Ton score est calculé à partir de tes compétences et de tes préférences.',
      'Dein Score wird aus deinen Kompetenzen und Präferenzen berechnet.',
      'Your score is calculated from your skills and preferences.',
    ],
    'jobsForYou': [
      '{count} offres pour toi',
      '{count} Jobs für dich',
      '{count} jobs for you',
    ],
    'changeFilters': [
      'Modifie tes filtres pour afficher davantage de résultats',
      'Ändere deine Filter, um mehr Ergebnisse zu sehen',
      'Change your filters to see more results',
    ],
    'sourcesActive': [
      '{count} sources actives',
      '{count} aktive Quellen',
      '{count} active sources',
    ],
    'syncPending': [
      'Synchronisation en attente',
      'Synchronisierung ausstehend',
      'Sync pending',
    ],
    'updatedAt': [
      'Actualisé à {time}',
      'Aktualisiert um {time}',
      'Updated at {time}',
    ],
    'publishJob': ['Publier une offre', 'Job veröffentlichen', 'Post a job'],
    'forYou': ['Pour toi', 'Für dich', 'For you'],
    'newFilter': ['Nouvelles', 'Neu', 'New'],
    'remoteFilter': ['Remote', 'Remote', 'Remote'],
    'savedFilter': ['Sauvegardées', 'Gespeichert', 'Saved'],
    'moreFilters': ['Plus de filtres', 'Mehr Filter', 'More filters'],
    'savedSearches': [
      'Mes recherches ({count})',
      'Meine Suchen ({count})',
      'My searches ({count})',
    ],
    'refreshJobs': [
      'Actualiser les offres',
      'Jobs aktualisieren',
      'Refresh jobs',
    ],
    'searchAlsoOn': ['Chercher aussi sur', 'Auch suchen auf', 'Also search on'],
    'sortJobs': ['Trier les offres', 'Jobs sortieren', 'Sort jobs'],
    'sortMatch': [
      'Meilleure compatibilité',
      'Beste Übereinstimmung',
      'Best match',
    ],
    'sortNewest': ['Plus récentes', 'Neueste zuerst', 'Newest'],
    'sortSalary': [
      'Salaire le plus élevé',
      'Höchstes Gehalt',
      'Highest salary',
    ],
    'maximumDistance': [
      'Distance maximale',
      'Maximale Entfernung',
      'Maximum distance',
    ],
    'nearbyJobs': [
      '{count} offres à proximité',
      '{count} Jobs in der Nähe',
      '{count} nearby jobs',
    ],
    'profileNeedsCompletion': [
      'profil à compléter',
      'Profil vervollständigen',
      'complete profile',
    ],
    'compatibility': ['compatibilité', 'Übereinstimmung', 'match'],
    'openJobAt': [
      'Ouvrir {job} chez {company}',
      '{job} bei {company} öffnen',
      'Open {job} at {company}',
    ],
    'originalJobOn': [
      'Voir l’offre originale sur {source}',
      'Originalangebot auf {source} ansehen',
      'View original job on {source}',
    ],
    'postedHours': ['Il y a {count} h', 'Vor {count} Std.', '{count}h ago'],
    'postedDays': ['Il y a {count} j', 'Vor {count} Tagen', '{count}d ago'],
    'postedToday': ['Aujourd’hui', 'Heute', 'Today'],
    'postedYesterday': ['Hier', 'Gestern', 'Yesterday'],
    'marketDemand': [
      'Ce que recherchent les offres autour de toi',
      'Was Jobs in deiner Nähe suchen',
      'What nearby jobs are looking for',
    ],
    'marketTrendsEmpty': [
      'Les tendances apparaîtront avec les offres actives.',
      'Trends erscheinen mit aktiven Jobangeboten.',
      'Trends will appear with active jobs.',
    ],
    'noSkillsProvided': [
      'Aucune compétence renseignée.',
      'Keine Kompetenzen angegeben.',
      'No skills provided.',
    ],
    'declared': ['Déclaré', 'Angegeben', 'Provided'],
    'trackingTitle': [
      'Ton suivi de candidatures',
      'Deine Bewerbungsübersicht',
      'Your application tracking',
    ],
    'trackingSubtitle': [
      'Une vue simple de chaque prochaine étape',
      'Alle nächsten Schritte auf einen Blick',
      'A simple view of every next step',
    ],
    'inProgress': ['En cours', 'Laufend', 'In progress'],
    'interviewsMetric': ['Entretiens', 'Gespräche', 'Interviews'],
    'responseRate': ['Taux de réponse', 'Antwortrate', 'Response rate'],
    'indicativeDelay': [
      'Délai indicatif',
      'Geschätzte Dauer',
      'Estimated time',
    ],
    'statusPreparing': ['À préparer', 'Vorbereiten', 'To prepare'],
    'statusApplied': ['Candidature envoyée', 'Bewerbung gesendet', 'Applied'],
    'statusInterview': ['Entretien', 'Gespräch', 'Interview'],
    'statusOffer': ['Offre reçue', 'Angebot erhalten', 'Offer received'],
    'statusRejected': ['Refus', 'Absage', 'Rejected'],
    'removeTracking': [
      'Retirer du suivi',
      'Aus Übersicht entfernen',
      'Remove from tracking',
    ],
    'dropJobHere': [
      'Dépose une offre ici',
      'Job hier ablegen',
      'Drop a job here',
    ],
    'changeStatus': ['Modifier le statut', 'Status ändern', 'Change status'],
    'prepareQuestions': [
      'Préparer les questions',
      'Fragen vorbereiten',
      'Prepare questions',
    ],
    'replyCompany': [
      'Répondre à l’entreprise',
      'Dem Unternehmen antworten',
      'Reply to the company',
    ],
    'completeApplication': [
      'Compléter la candidature',
      'Bewerbung vervollständigen',
      'Complete application',
    ],
    'followUp': [
      'Relancer si nécessaire',
      'Bei Bedarf nachfassen',
      'Follow up if needed',
    ],
    'noJobsFound': [
      'Aucune offre trouvée',
      'Keine Jobs gefunden',
      'No jobs found',
    ],
    'tryOtherSearch': [
      'Essaie un autre mot-clé ou modifie les filtres.',
      'Versuche einen anderen Suchbegriff oder ändere die Filter.',
      'Try another keyword or change the filters.',
    ],
    'hoursPerWeek': ['16–20 h/semaine', '16–20 Std./Woche', '16–20 h/week'],
    'fromHome': ['{time} de chez toi', '{time} von dir', '{time} from home'],
    'hybrid': ['Hybride', 'Hybrid', 'Hybrid'],
    'realRoute': [
      'Voir l’itinéraire routier réel sur OpenStreetMap',
      'Echte Route auf OpenStreetMap ansehen',
      'View the real route on OpenStreetMap',
    ],
    'aboutRole': ['À propos du poste', 'Über die Stelle', 'About the role'],
    'requiredSkills': [
      'Compétences recherchées',
      'Gesuchte Kompetenzen',
      'Required skills',
    ],
    'continueApplication': [
      'Continuer ma candidature',
      'Bewerbung fortsetzen',
      'Continue my application',
    ],
    'prepareApplication': [
      'Préparer ma candidature',
      'Bewerbung vorbereiten',
      'Prepare my application',
    ],
    'aiLetter': ['Lettre IA', 'KI-Anschreiben', 'AI letter'],
    'prepareInterview': [
      'Préparer et répéter mon entretien',
      'Gespräch vorbereiten und üben',
      'Prepare and practice my interview',
    ],
    'scoreNeedsProfile': [
      'Ajoute tes compétences ou analyse ton CV pour obtenir un score personnalisé. Aucune note par défaut n’est inventée.',
      'Füge Kompetenzen hinzu oder analysiere deinen Lebenslauf für einen persönlichen Score. Es wird keine Standardnote erfunden.',
      'Add skills or analyze your CV to get a personalized score. No default rating is invented.',
    ],
    'compatAddProfile': [
      'Ajoute tes compétences ou analyse ton CV pour calculer un score fiable.',
      'Füge Kompetenzen hinzu oder analysiere deinen Lebenslauf, um einen verlässlichen Score zu berechnen.',
      'Add skills or analyze your CV to calculate a reliable score.',
    ],
    'compatUnknownLevel': ['non renseigné', 'nicht angegeben', 'not provided'],
    'compatLanguageDetail': [
      '{profile} dans ton profil · {required} requis',
      '{profile} im Profil · {required} erforderlich',
      '{profile} in your profile · {required} required',
    ],
    'compatMatchedSkills': [
      '{count} compétence(s) demandée(s) retrouvée(s) dans ton profil.',
      '{count} geforderte Kompetenz(en) in deinem Profil gefunden.',
      '{count} required skill(s) found in your profile.',
    ],
    'compatGermanMatches': [
      'Ton niveau d’allemand correspond au niveau détecté dans l’offre.',
      'Dein Deutschniveau entspricht dem in der Stelle erkannten Niveau.',
      'Your German level matches the level detected in the job.',
    ],
    'compatFullyRemote': [
      'L’offre est entièrement réalisable à distance.',
      'Die Stelle kann vollständig remote ausgeübt werden.',
      'The role can be performed fully remotely.',
    ],
    'compatWithinRadius': [
      'Le poste se situe dans ou près de ton rayon de recherche.',
      'Die Stelle liegt innerhalb oder nahe deinem Suchradius.',
      'The role is within or close to your search radius.',
    ],
    'compatSalaryMatches': [
      'Le salaire annoncé est proche ou supérieur à ton minimum.',
      'Das angegebene Gehalt liegt nahe oder über deinem Minimum.',
      'The advertised salary is close to or above your minimum.',
    ],
    'compatNoStructuredSkills': [
      'L’offre ne fournit pas assez de compétences structurées : ce critère est exclu du score.',
      'Die Stelle enthält nicht genügend strukturierte Kompetenzen; dieses Kriterium wird nicht bewertet.',
      'The job does not provide enough structured skills, so this criterion is excluded from the score.',
    ],
    'compatMissingSkills': [
      '{count} compétence(s) reste(nt) à confirmer.',
      '{count} Kompetenz(en) müssen noch bestätigt werden.',
      '{count} skill(s) still need to be confirmed.',
    ],
    'compatGermanReview': [
      'Niveau d’allemand à vérifier : {detail}.',
      'Deutschniveau prüfen: {detail}.',
      'German level to review: {detail}.',
    ],
    'compatSalaryNotPublished': [
      'Salaire non publié : il n’est pas utilisé dans le score.',
      'Kein Gehalt veröffentlicht; es wird nicht im Score berücksichtigt.',
      'Salary not published; it is not used in the score.',
    ],
    'compatOutsideRadius': [
      'Le poste dépasse ton rayon de recherche actuel.',
      'Die Stelle liegt außerhalb deines aktuellen Suchradius.',
      'The role is outside your current search radius.',
    ],
    'whyMatch': [
      'Pourquoi cette offre te correspond',
      'Warum dieser Job zu dir passt',
      'Why this job matches you',
    ],
    'criterionSkills': ['Compétences', 'Kompetenzen', 'Skills'],
    'criterionRelevance': [
      'Profil et mission',
      'Profil und Aufgabe',
      'Profile and role',
    ],
    'criterionWork': [
      'Conditions de travail',
      'Arbeitsbedingungen',
      'Working conditions',
    ],
    'criterionGerman': ['Allemand', 'Deutsch', 'German'],
    'criterionEducation': ['Formation', 'Ausbildung', 'Education'],
    'criterionExperience': ['Expérience', 'Erfahrung', 'Experience'],
    'criterionSalary': ['Salaire', 'Gehalt', 'Salary'],
    'criterionDistance': ['Distance', 'Entfernung', 'Distance'],
    'criterionFreshness': ['Fraîcheur', 'Aktualität', 'Freshness'],
    'scoreReliability': [
      'Fiabilité du score : {score}% · calcul fondé sur ton profil, les exigences et la date de publication.',
      'Score-Zuverlässigkeit: {score}% · basiert auf deinem Profil, den Anforderungen und dem Veröffentlichungsdatum.',
      'Score reliability: {score}% · based on your profile, requirements and publication date.',
    ],
    'matchesLabel': [
      'Correspondances : {items}',
      'Übereinstimmungen: {items}',
      'Matches: {items}',
    ],
    'developLabel': [
      'À vérifier ou développer : {items}',
      'Prüfen oder ausbauen: {items}',
      'Review or develop: {items}',
    ],
    'languageLabel': [
      'Langue : {value}',
      'Sprache: {value}',
      'Language: {value}',
    ],
    'verifyLabel': [
      'À vérifier : {value}',
      'Prüfen: {value}',
      'Review: {value}',
    ],
    'applicationKit': [
      'Kit de candidature',
      'Bewerbungspaket',
      'Application kit',
    ],
    'beforeYouApply': [
      'Avant d’envoyer ta candidature',
      'Bevor du dich bewirbst',
      'Before you apply',
    ],
    'sourceOfficialEmployer': [
      'Offre publiée directement par l’entreprise',
      'Direkt vom Unternehmen veröffentlicht',
      'Posted directly by the employer',
    ],
    'sourceOfficialBoard': [
      'Bourse officielle de l’emploi (Bundesagentur für Arbeit)',
      'Offizielle Jobbörse (Bundesagentur für Arbeit)',
      'Official job board (Bundesagentur für Arbeit)',
    ],
    'sourceVerifiedSubmission': [
      'Offre soumise et vérifiée par Werkly',
      'Von Werkly geprüfte Einreichung',
      'Submitted and verified by Werkly',
    ],
    'sourceAggregator': [
      'Offre agrégée depuis une autre plateforme',
      'Aggregierte Anzeige von einer anderen Plattform',
      'Aggregated listing from another platform',
    ],
    'readyToSend': ['Prêt à envoyer', 'Versandbereit', 'Ready to send'],
    'profileSummaryReady': [
      'Profil et résumé professionnel complétés',
      'Profil und berufliche Zusammenfassung vollständig',
      'Profile and professional summary complete',
    ],
    'cvKeywordsReady': [
      'Mots-clés adaptés dans le CV',
      'Schlüsselwörter im Lebenslauf angepasst',
      'CV keywords tailored',
    ],
    'pdfLetterReady': [
      'Dossier PDF et lettre préparés',
      'PDF-Paket und Anschreiben vorbereitet',
      'PDF kit and letter prepared',
    ],
    'applicationTracked': [
      'Candidature envoyée et suivie',
      'Bewerbung gesendet und verfolgt',
      'Application sent and tracked',
    ],
    'strengthsForRole': [
      'Tes atouts pour ce poste',
      'Deine Stärken für diese Stelle',
      'Your strengths for this role',
    ],
    'addSkillsAnalysis': [
      'Ajoute tes compétences pour obtenir une analyse personnalisée.',
      'Füge Kompetenzen für eine persönliche Analyse hinzu.',
      'Add skills to get a personalized analysis.',
    ],
    'noExactMatch': [
      'Aucune correspondance exacte détectée pour le moment.',
      'Noch keine genaue Übereinstimmung erkannt.',
      'No exact match detected yet.',
    ],
    'keywordsToStrengthen': [
      'Mots-clés à renforcer dans ton CV',
      'Schlüsselwörter für deinen Lebenslauf',
      'Keywords to strengthen in your CV',
    ],
    'allKeywordsCovered': [
      'Ton profil couvre tous les mots-clés détectés.',
      'Dein Profil deckt alle erkannten Schlüsselwörter ab.',
      'Your profile covers all detected keywords.',
    ],
    'completeMyProfile': [
      'Compléter mon profil',
      'Profil vervollständigen',
      'Complete my profile',
    ],
    'keywordsCopied': [
      'Mots-clés copiés',
      'Schlüsselwörter kopiert',
      'Keywords copied',
    ],
    'copyKeywords': [
      'Copier les mots-clés pour mon CV',
      'Schlüsselwörter für meinen Lebenslauf kopieren',
      'Copy keywords for my CV',
    ],
    'reopenPdfKit': [
      'Rouvrir mon dossier PDF',
      'PDF-Paket erneut öffnen',
      'Reopen my PDF kit',
    ],
    'createPdfKit': [
      'Créer mon dossier de candidature PDF',
      'PDF-Bewerbungspaket erstellen',
      'Create my application PDF kit',
    ],
    'reopenLetter': [
      'Rouvrir le texte de la lettre',
      'Anschreiben erneut öffnen',
      'Reopen letter text',
    ],
    'viewLetterOnly': [
      'Voir seulement la lettre',
      'Nur das Anschreiben ansehen',
      'View letter only',
    ],
    'originalOpened': [
      'Offre originale ouverte',
      'Originalangebot geöffnet',
      'Original job opened',
    ],
    'openOriginal': [
      'Ouvrir l’offre originale',
      'Originalangebot öffnen',
      'Open original job',
    ],
    'editReminder': [
      'Modifier mon rappel',
      'Erinnerung ändern',
      'Edit my reminder',
    ],
    'addReminder': [
      'Ajouter un rappel de candidature',
      'Bewerbungserinnerung hinzufügen',
      'Add application reminder',
    ],
    'applicationStatus': [
      'Statut de ma candidature',
      'Bewerbungsstatus',
      'Application status',
    ],
    'guestProgressSaved': [
      'Ton avancement est conservé sur cet appareil. La connexion reste facultative.',
      'Dein Fortschritt bleibt auf diesem Gerät gespeichert. Die Anmeldung ist optional.',
      'Your progress is saved on this device. Signing in remains optional.',
    ],
    'accountProgressSynced': [
      'Ton avancement est synchronisé avec ton compte.',
      'Dein Fortschritt wird mit deinem Konto synchronisiert.',
      'Your progress is synced with your account.',
    ],
    'statusInterviewObtained': [
      'Entretien obtenu',
      'Gespräch erhalten',
      'Interview secured',
    ],
    'statusRejectedFeminine': ['Refusée', 'Abgelehnt', 'Rejected'],
    'loadJobsFirst': [
      'Charge d’abord les offres disponibles.',
      'Lade zuerst die verfügbaren Jobs.',
      'Load the available jobs first.',
    ],
    'alertsReminders': [
      'Alertes et rappels',
      'Benachrichtigungen und Erinnerungen',
      'Alerts and reminders',
    ],
    'markAllRead': ['Tout lire', 'Alle gelesen', 'Mark all read'],
    'alertsSubtitle': [
      'Nouvelles offres compatibles et échéances de candidature.',
      'Neue passende Jobs und Bewerbungsfristen.',
      'New matching jobs and application deadlines.',
    ],
    'receiveDeviceReminders': [
      'Recevoir les rappels sur cet appareil',
      'Erinnerungen auf diesem Gerät erhalten',
      'Receive reminders on this device',
    ],
    'permissionOptional': [
      'L’autorisation reste facultative.',
      'Die Berechtigung bleibt optional.',
      'Permission remains optional.',
    ],
    'enable': ['Activer', 'Aktivieren', 'Enable'],
    'notificationsEnabled': [
      'Notifications activées.',
      'Benachrichtigungen aktiviert.',
      'Notifications enabled.',
    ],
    'notificationsDenied': [
      'Autorisation refusée. Les alertes restent visibles dans Werkly.',
      'Berechtigung abgelehnt. Hinweise bleiben in Werkly sichtbar.',
      'Permission denied. Alerts remain visible in Werkly.',
    ],
    'noAlerts': [
      'Aucune alerte pour le moment',
      'Noch keine Hinweise',
      'No alerts yet',
    ],
    'alertsEmptyBody': [
      'Les nouvelles offres et tes rappels apparaîtront ici.',
      'Neue Jobs und Erinnerungen erscheinen hier.',
      'New jobs and your reminders will appear here.',
    ],
    'newJob': ['Nouvelle offre', 'Neuer Job', 'New job'],
    'reminderDue': [
      'Rappel arrivé · {date}',
      'Erinnerung fällig · {date}',
      'Reminder due · {date}',
    ],
    'scheduledFor': [
      'Prévu le {date}',
      'Geplant für {date}',
      'Scheduled for {date}',
    ],
    'advancedFilters': [
      'Filtres avancés',
      'Erweiterte Filter',
      'Advanced filters',
    ],
    'allSalaries': ['Tous les salaires', 'Alle Gehälter', 'All salaries'],
    'salaryFrom': [
      'À partir de {salary} €/h',
      'Ab {salary} €/Std.',
      'From €{salary}/h',
    ],
    'all': ['Tous', 'Alle', 'All'],
    'flexibleOnly': [
      'Hybride ou remote uniquement',
      'Nur Hybrid oder Remote',
      'Hybrid or remote only',
    ],
    'sources': ['Sources', 'Quellen', 'Sources'],
    'reset': ['Réinitialiser', 'Zurücksetzen', 'Reset'],
    'apply': ['Appliquer', 'Anwenden', 'Apply'],
    'saveThisSearch': [
      'Sauvegarder cette recherche',
      'Diese Suche speichern',
      'Save this search',
    ],
    'searchName': ['Nom de la recherche', 'Name der Suche', 'Search name'],
    'searchSavedToast': [
      'Recherche sauvegardée. Les nouvelles offres seront signalées.',
      'Suche gespeichert. Neue Jobs werden gemeldet.',
      'Search saved. New jobs will trigger an alert.',
    ],
    'searchApplyFailed': [
      'Cette recherche n’a pas pu être appliquée.',
      'Diese Suche konnte nicht angewendet werden.',
      'This search could not be applied.',
    ],
    'noSavedSearches': [
      'Aucune recherche sauvegardée pour le moment.',
      'Noch keine gespeicherten Suchen.',
      'No saved searches yet.',
    ],
    'mySavedSearches': [
      'Mes recherches sauvegardées',
      'Meine gespeicherten Suchen',
      'My saved searches',
    ],
    'salaryStarting': [
      'dès {salary} €/h',
      'ab {salary} €/Std.',
      'from €{salary}/h',
    ],
    'delete': ['Supprimer', 'Löschen', 'Delete'],
    'applicationFolder': [
      'Dossier de candidature – {company}',
      'Bewerbungsunterlagen – {company}',
      'Application folder – {company}',
    ],
    'fullName': ['Nom complet', 'Vollständiger Name', 'Full name'],
    'university': ['Université', 'Hochschule', 'University'],
    'education': ['Formation', 'Ausbildung', 'Education'],
    'city': ['Ville', 'Stadt', 'City'],
    'phone': ['Téléphone', 'Telefon', 'Phone'],
    'address': ['Adresse', 'Adresse', 'Address'],
    'commaSkills': [
      'Compétences séparées par des virgules',
      'Kompetenzen durch Kommas getrennt',
      'Skills separated by commas',
    ],
    'professionalSummary': [
      'Résumé professionnel',
      'Berufliche Zusammenfassung',
      'Professional summary',
    ],
    'preferFlexibleJobs': [
      'Je préfère les postes hybrides/remote',
      'Ich bevorzuge Hybrid- oder Remote-Jobs',
      'I prefer hybrid or remote jobs',
    ],
    'profileSaved': [
      'Profil enregistré.',
      'Profil gespeichert.',
      'Profile saved.',
    ],
    'profileSaveFailed': [
      'Profil non enregistré : {error}',
      'Profil nicht gespeichert: {error}',
      'Profile not saved: {error}',
    ],
    'savedOnDevice': [
      'Enregistré sur cet appareil. Connecte-toi pour synchroniser tes données.',
      'Auf diesem Gerät gespeichert. Melde dich zum Synchronisieren an.',
      'Saved on this device. Sign in to sync your data.',
    ],
    'syncUnavailable': [
      'Synchronisation temporairement indisponible.',
      'Synchronisierung vorübergehend nicht verfügbar.',
      'Sync temporarily unavailable.',
    ],
    'signIn': ['Se connecter', 'Anmelden', 'Sign in'],
    'cvAddedToast': [
      '{file} a été ajouté à ton profil.',
      '{file} wurde deinem Profil hinzugefügt.',
      '{file} was added to your profile.',
    ],
    'cvAddFailed': [
      'Impossible d’ajouter le CV : {error}',
      'Lebenslauf konnte nicht hinzugefügt werden: {error}',
      'Could not add CV: {error}',
    ],
    'analyzeCvConsentTitle': [
      'Analyser ton CV avec l’IA ?',
      'Lebenslauf mit KI analysieren?',
      'Analyze your CV with AI?',
    ],
    'analyzeCvConsentBody': [
      'Ton CV privé sera envoyé à Google Gemini uniquement pour extraire tes compétences, langues, expériences et formation. Vérifie ensuite les informations détectées : l’IA peut se tromper.',
      'Dein privater Lebenslauf wird nur zur Extraktion von Kompetenzen, Sprachen, Erfahrungen und Ausbildung an Google Gemini gesendet. Prüfe die Ergebnisse anschließend – KI kann Fehler machen.',
      'Your private CV will only be sent to Google Gemini to extract skills, languages, experience and education. Review the detected information afterwards because AI can make mistakes.',
    ],
    'keepWithoutAnalysis': [
      'Garder sans analyser',
      'Ohne Analyse behalten',
      'Keep without analysis',
    ],
    'cvKeptPrivate': [
      'Le CV reste enregistré sans être envoyé à l’IA.',
      'Der Lebenslauf bleibt gespeichert, ohne an die KI gesendet zu werden.',
      'The CV remains saved without being sent to AI.',
    ],
    'cvSkillsDetected': [
      '{count} compétences ont été détectées et les scores ont été recalculés.',
      '{count} Kompetenzen wurden erkannt und die Scores neu berechnet.',
      '{count} skills were detected and scores were recalculated.',
    ],
    'cvAnalysisFailed': [
      'L’analyse du CV a échoué. Le document reste sécurisé et tu peux réessayer.',
      'Die Lebenslaufanalyse ist fehlgeschlagen. Das Dokument bleibt sicher und du kannst es erneut versuchen.',
      'CV analysis failed. The document remains secure and you can try again.',
    ],
    'deleteAccountTitle': [
      'Supprimer ton compte ?',
      'Konto löschen?',
      'Delete your account?',
    ],
    'deleteAccountBody': [
      'Ton profil, ton CV, tes favoris et tes candidatures seront définitivement supprimés.',
      'Dein Profil, Lebenslauf, Favoriten und Bewerbungen werden endgültig gelöscht.',
      'Your profile, CV, favorites and applications will be permanently deleted.',
    ],
    'deleteAccountUnavailable': [
      'La suppression du compte est temporairement indisponible.',
      'Die Kontolöschung ist vorübergehend nicht verfügbar.',
      'Account deletion is temporarily unavailable.',
    ],
    'loadingRealJobs': [
      'Chargement des offres réelles…',
      'Echte Jobs werden geladen…',
      'Loading real jobs…',
    ],
    'noJobsAvailable': [
      'Aucune offre disponible pour le moment.',
      'Derzeit sind keine Jobs verfügbar.',
      'No jobs are available right now.',
    ],
    'jobsUpdatedToast': [
      '{count} offres mises à jour.',
      '{count} Jobs aktualisiert.',
      '{count} jobs updated.',
    ],
    'jobsUpdateFailed': [
      'La mise à jour a échoué. Réessaie dans un instant.',
      'Die Aktualisierung ist fehlgeschlagen. Versuche es gleich erneut.',
      'Update failed. Try again in a moment.',
    ],
    'jobsLoadFailed': [
      'Impossible de charger les offres pour le moment.',
      'Jobs können derzeit nicht geladen werden.',
      'Jobs cannot be loaded right now.',
    ],
    'unknownDistance': [
      'Distance inconnue',
      'Entfernung unbekannt',
      'Unknown distance',
    ],
    'estimatedMinutes': [
      '~{minutes} min estimées',
      '~{minutes} Min. geschätzt',
      '~{minutes} min estimated',
    ],
    'recently': ['Récemment', 'Kürzlich', 'Recently'],
    'justNow': ['À l’instant', 'Gerade eben', 'Just now'],
    'salaryUnknown': [
      'Salaire non précisé',
      'Gehalt nicht angegeben',
      'Salary not specified',
    ],
    'authHero': [
      'Ton prochain job\ncommence ici.',
      'Dein nächster Job\nbeginnt hier.',
      'Your next job\nstarts here.',
    ],
    'authHeroBody': [
      'Des offres de Werkstudent classées selon ton profil, tes compétences et ton trajet.',
      'Werkstudentenjobs, sortiert nach Profil, Kompetenzen und Arbeitsweg.',
      'Working-student jobs ranked by your profile, skills and commute.',
    ],
    'authFeatureMatching': [
      'Matching personnalisé par IA',
      'Persönliches KI-Matching',
      'Personalized AI matching',
    ],
    'authFeatureNearby': [
      'Opportunités proches de chez toi',
      'Chancen in deiner Nähe',
      'Opportunities near you',
    ],
    'authFeatureTracking': [
      'Candidatures toujours organisées',
      'Bewerbungen immer organisiert',
      'Applications always organized',
    ],
    'designedForStudents': [
      'Pensé pour les étudiants en Allemagne.',
      'Für Studierende in Deutschland entwickelt.',
      'Designed for students in Germany.',
    ],
    'createProfile': [
      'Crée ton profil',
      'Erstelle dein Profil',
      'Create your profile',
    ],
    'welcomeBack': ['Bon retour !', 'Willkommen zurück!', 'Welcome back!'],
    'signupSubtitle': [
      'Quelques secondes pour lancer ta recherche.',
      'Nur wenige Sekunden bis zu deiner Suche.',
      'A few seconds to start your search.',
    ],
    'signinSubtitle': [
      'Connecte-toi pour retrouver tes matchs.',
      'Melde dich an, um deine Matches wiederzufinden.',
      'Sign in to find your matches again.',
    ],
    'nameField': ['Prénom et nom', 'Vor- und Nachname', 'First and last name'],
    'nameRequired': [
      'Indique ton nom.',
      'Gib deinen Namen an.',
      'Enter your name.',
    ],
    'email': ['Adresse e-mail', 'E-Mail-Adresse', 'Email address'],
    'invalidEmail': [
      'Adresse e-mail invalide.',
      'Ungültige E-Mail-Adresse.',
      'Invalid email address.',
    ],
    'password': ['Mot de passe', 'Passwort', 'Password'],
    'passwordLength': [
      'Utilise au moins 8 caractères.',
      'Verwende mindestens 8 Zeichen.',
      'Use at least 8 characters.',
    ],
    'forgotPassword': [
      'Mot de passe oublié ?',
      'Passwort vergessen?',
      'Forgot password?',
    ],
    'acceptPrivacy': [
      'J’accepte la politique de confidentialité et le traitement de mon CV.',
      'Ich akzeptiere die Datenschutzerklärung und die Verarbeitung meines Lebenslaufs.',
      'I accept the privacy policy and processing of my CV.',
    ],
    'createAccount': [
      'Créer mon compte',
      'Konto erstellen',
      'Create my account',
    ],
    'alreadyRegistered': [
      'Déjà inscrit ?',
      'Bereits registriert?',
      'Already registered?',
    ],
    'newToWerkly': [
      'Nouveau sur Werkly ?',
      'Neu bei Werkly?',
      'New to Werkly?',
    ],
    'continueGuest': [
      'Continuer sans compte',
      'Ohne Konto fortfahren',
      'Continue without an account',
    ],
    'privacyRequired': [
      'Accepte la politique de confidentialité pour continuer.',
      'Akzeptiere die Datenschutzerklärung, um fortzufahren.',
      'Accept the privacy policy to continue.',
    ],
    'verifyEmail': [
      'Vérifie ta boîte mail pour confirmer ton compte.',
      'Prüfe dein Postfach, um dein Konto zu bestätigen.',
      'Check your inbox to confirm your account.',
    ],
    'resendConfirmation': [
      'Renvoyer l’e-mail de confirmation',
      'Bestätigungs-E-Mail erneut senden',
      'Resend confirmation email',
    ],
    'confirmationResent': [
      'Un nouvel e-mail a été envoyé. Utilise uniquement ce nouveau lien.',
      'Eine neue E-Mail wurde gesendet. Verwende nur diesen neuen Link.',
      'A new email was sent. Only use this new link.',
    ],
    'authEmailDeliveryFailed': [
      'L’e-mail de confirmation ne peut pas être envoyé pour le moment. Réessaie plus tard ou contacte le support Werkly.',
      'Die Bestätigungs-E-Mail kann im Moment nicht versendet werden. Versuche es später erneut oder kontaktiere den Werkly-Support.',
      'The confirmation email cannot be sent right now. Try again later or contact Werkly support.',
    ],
    'connectionFailed': [
      'Connexion impossible. Vérifie ton réseau puis réessaie.',
      'Anmeldung nicht möglich. Prüfe dein Netzwerk und versuche es erneut.',
      'Could not sign in. Check your network and try again.',
    ],
    'enterEmailFirst': [
      'Entre d’abord ton adresse e-mail.',
      'Gib zuerst deine E-Mail-Adresse ein.',
      'Enter your email address first.',
    ],
    'resetLinkSent': [
      'Un lien de réinitialisation vient de t’être envoyé.',
      'Ein Link zum Zurücksetzen wurde dir gesendet.',
      'A reset link has been sent to you.',
    ],
    'chooseNewPassword': [
      'Choisis un nouveau mot de passe',
      'Neues Passwort festlegen',
      'Choose a new password',
    ],
    'passwordRecoverySubtitle': [
      'Saisis puis confirme ton nouveau mot de passe.',
      'Gib dein neues Passwort ein und bestätige es.',
      'Enter and confirm your new password.',
    ],
    'passwordRecoveryFor': [
      'Nouveau mot de passe pour {email}',
      'Neues Passwort für {email}',
      'New password for {email}',
    ],
    'newPassword': ['Nouveau mot de passe', 'Neues Passwort', 'New password'],
    'confirmNewPassword': [
      'Confirmer le nouveau mot de passe',
      'Neues Passwort bestätigen',
      'Confirm new password',
    ],
    'passwordsDoNotMatch': [
      'Les mots de passe ne correspondent pas.',
      'Die Passwörter stimmen nicht überein.',
      'The passwords do not match.',
    ],
    'saveNewPassword': [
      'Enregistrer le nouveau mot de passe',
      'Neues Passwort speichern',
      'Save new password',
    ],
    'passwordUpdated': [
      'Ton mot de passe a été mis à jour.',
      'Dein Passwort wurde aktualisiert.',
      'Your password has been updated.',
    ],
    'replayTutorial': [
      'Revoir le tutoriel',
      'Tutorial erneut ansehen',
      'Replay tutorial',
    ],
    'retry': ['Réessayer', 'Erneut versuchen', 'Try again'],
    'notifications': ['Notifications', 'Benachrichtigungen', 'Notifications'],
    'assistant': ['Demander à Nia', 'Nia fragen', 'Ask Nia'],
    'reportAiContent': [
      'Signaler cette réponse',
      'Diese Antwort melden',
      'Report this answer',
    ],
    'reportAiTitle': [
      'Signaler une réponse IA',
      'KI-Antwort melden',
      'Report an AI answer',
    ],
    'reportAiExplanation': [
      'Ton signalement reste dans Werkly et nous aide à examiner les contenus inexacts, offensants ou dangereux.',
      'Deine Meldung bleibt in Werkly und hilft uns, ungenaue, beleidigende oder gefährliche Inhalte zu prüfen.',
      'Your report stays in Werkly and helps us review inaccurate, offensive, or unsafe content.',
    ],
    'reportAiReason': ['Motif', 'Grund', 'Reason'],
    'reportAiInaccurate': [
      'Information inexacte',
      'Ungenaue Information',
      'Inaccurate information',
    ],
    'reportAiOffensive': [
      'Contenu offensant',
      'Beleidigender Inhalt',
      'Offensive content',
    ],
    'reportAiUnsafe': [
      'Conseil dangereux',
      'Gefährlicher Rat',
      'Unsafe advice',
    ],
    'reportAiOther': ['Autre', 'Sonstiges', 'Other'],
    'reportAiDetails': [
      'Détails facultatifs',
      'Optionale Details',
      'Optional details',
    ],
    'sendReport': ['Envoyer le signalement', 'Meldung senden', 'Send report'],
    'reportAiSent': [
      'Merci. Le signalement a été envoyé.',
      'Danke. Die Meldung wurde gesendet.',
      'Thank you. The report was sent.',
    ],
    'reportAiFailed': [
      'Le signalement n’a pas pu être envoyé.',
      'Die Meldung konnte nicht gesendet werden.',
      'The report could not be sent.',
    ],
    'addFavorite': [
      'Ajouter aux favoris',
      'Zu Favoriten hinzufügen',
      'Add to favorites',
    ],
    'removeFavorite': [
      'Retirer des favoris',
      'Aus Favoriten entfernen',
      'Remove from favorites',
    ],
    'coverLetterFor': [
      'Lettre pour {company}',
      'Anschreiben für {company}',
      'Letter for {company}',
    ],
    'letterCopied': [
      'Lettre copiée.',
      'Anschreiben kopiert.',
      'Letter copied.',
    ],
    'letterGenerating': [
      'Nia rédige ta lettre…',
      'Nia schreibt dein Anschreiben…',
      'Nia is writing your letter…',
    ],
    'letterByNia': [
      'Rédigée par Nia',
      'Von Nia geschrieben',
      'Written by Nia',
    ],
    'letterQuickTemplate': [
      'Modèle rapide',
      'Schnellvorlage',
      'Quick template',
    ],
    'letterAiUnavailable': [
      'IA indisponible pour le moment : voici un modèle rapide.',
      'KI derzeit nicht verfügbar: hier eine Schnellvorlage.',
      'AI unavailable right now — showing a quick template instead.',
    ],
    'letterAiInstruction': [
      "Rédige uniquement le corps d'une lettre de motivation pour cette offre, "
          'prêt à être inséré tel quel dans un document final. Écris directement '
          'en texte brut, sans astérisques ni aucune mise en forme markdown, sans '
          "titre, sans note ou commentaire sur ta démarche, et sans bloc d'adresse, "
          'date ou objet : le nom du candidat, le poste et l’entreprise sont déjà '
          'affichés séparément, donc ne les répète pas et ne mets aucun texte entre '
          'crochets. Commence directement par une formule de salutation, rédige 2 à '
          '4 courts paragraphes séparés par une ligne vide, puis termine par une '
          'formule de politesse suivie du prénom du candidat sur la ligne suivante. '
          'Si le contexte contient des expériences professionnelles réelles (poste, '
          'employeur, tâches), appuie-toi précisément dessus — nomme l’employeur et '
          'les tâches réelles au lieu de rester vague ; sinon, reste général sans '
          'inventer d’expérience.',
      'Schreibe ausschließlich den Fließtext eines Anschreibens für diese '
          'Stelle, fertig zum direkten Einfügen in ein finales Dokument. '
          'Schreibe reinen Text ohne Sternchen oder andere Markdown-Formatierung, '
          'ohne Überschrift, ohne Notiz oder Kommentar zu deiner Vorgehensweise '
          'und ohne Absender-/Empfängerblock, Datum oder Betreffzeile: Name, '
          'Stelle und Firma werden bereits separat angezeigt, wiederhole sie also '
          'nicht und verwende keine Platzhalter in eckigen Klammern. Beginne '
          'direkt mit einer Anrede, schreibe 2 bis 4 kurze Absätze, getrennt '
          'durch eine Leerzeile, und schließe mit einer Grußformel gefolgt vom '
          'Vornamen des Kandidaten in der nächsten Zeile. Enthält der Kontext '
          'echte berufliche Erfahrungen (Position, Arbeitgeber, Aufgaben), stütze '
          'dich konkret darauf — nenne den echten Arbeitgeber und die echten '
          'Aufgaben statt allgemein zu bleiben; ist das nicht der Fall, bleibe '
          'allgemein und erfinde keine Erfahrung.',
      'Write only the body of a cover letter for this job, ready to be dropped '
          'straight into a final document. Write plain prose with no asterisks or '
          'other markdown formatting, no heading, no note or comment about your '
          'approach, and no sender/recipient address block, date or subject line — '
          'the name, job title and company are already shown separately, so do not '
          'repeat them and do not use any bracketed placeholders. Start directly '
          'with a salutation, write 2 to 4 short paragraphs separated by a blank '
          'line, then end with a closing line followed by the applicant’s first '
          'name on the next line. If the context includes real work experience '
          '(role, employer, tasks), ground the letter in it specifically — name '
          'the real employer and real tasks instead of staying vague; if not, '
          'stay general and do not invent experience.',
    ],
    'downloadLetter': [
      'Télécharger',
      'Herunterladen',
      'Download',
    ],
    'letterNeedsNameTitle': [
      'Ajoute ton nom avant de télécharger',
      'Füge zuerst deinen Namen hinzu',
      'Add your name first',
    ],
    'letterNeedsNameBody': [
      'Sans compte, la lettre est signée « Candidat·e Werkly » au lieu de ton vrai nom. Connecte-toi et complète ton profil pour que la lettre te représente vraiment.',
      'Ohne Konto wird das Anschreiben mit „Werkly-Bewerber/in“ statt mit deinem echten Namen unterschrieben. Melde dich an und vervollständige dein Profil, damit das Anschreiben wirklich dich zeigt.',
      'Without an account, the letter is signed "Werkly applicant" instead of your real name. Sign in and complete your profile so the letter actually represents you.',
    ],
    'letterDownloadAnyway': [
      'Télécharger quand même',
      'Trotzdem herunterladen',
      'Download anyway',
    ],
    'copy': ['Copier', 'Kopieren', 'Copy'],
    'externalOpenFailed': [
      'Impossible d’ouvrir {provider}.',
      '{provider} konnte nicht geöffnet werden.',
      'Could not open {provider}.',
    ],
    'employerJobSubmitted': [
      'Offre envoyée. Elle apparaîtra après vérification.',
      'Job gesendet. Er erscheint nach der Prüfung.',
      'Job submitted. It will appear after review.',
    ],
    'employerJobSubmitFailed': [
      'Offre non envoyée : {error}',
      'Job nicht gesendet: {error}',
      'Job not submitted: {error}',
    ],
    'reminderDate': ['Date du rappel', 'Erinnerungsdatum', 'Reminder date'],
    'reminderTime': [
      'Heure du rappel',
      'Uhrzeit der Erinnerung',
      'Reminder time',
    ],
    'continue': ['Continuer', 'Weiter', 'Continue'],
    'futureDateRequired': [
      'Choisis une date dans le futur.',
      'Wähle ein Datum in der Zukunft.',
      'Choose a date in the future.',
    ],
    'reminderScheduled': [
      'Rappel prévu le {date} à {time}.',
      'Erinnerung geplant für den {date} um {time}.',
      'Reminder scheduled for {date} at {time}.',
    ],
    'originalLinkUnavailable': [
      'Lien original indisponible.',
      'Original-Link nicht verfügbar.',
      'Original link unavailable.',
    ],
    'jobOpenFailed': [
      'Impossible d’ouvrir cette offre.',
      'Dieser Job konnte nicht geöffnet werden.',
      'Could not open this job.',
    ],
    'interviewPrepSaved': [
      'Préparation enregistrée.',
      'Vorbereitung gespeichert.',
      'Preparation saved.',
    ],
    'assistantGreeting': [
      'Salut{name}! Je suis Nia, ton copilote carrière. Comment puis-je t’aider aujourd’hui ?',
      'Hallo{name}! Ich bin Nia, deine Karrierebegleiterin. Wie kann ich dir heute helfen?',
      'Hi{name}! I’m Nia, your career copilot. How can I help today?',
    ],
    'assistantLocalMode': [
      'Mode local · utilisable sans compte',
      'Lokaler Modus · ohne Konto nutzbar',
      'Local mode · works without an account',
    ],
    'assistantGeminiMode': [
      'IA gratuite Gemini · mode local de secours',
      'Kostenlose Gemini-KI · lokaler Ersatzmodus',
      'Free Gemini AI · local fallback mode',
    ],
    'assistantQuotaRemaining': [
      '{count} questions gratuites restantes cette heure',
      'Noch {count} kostenlose Fragen in dieser Stunde',
      '{count} free questions left this hour',
    ],
    'assistantLocalFallback': [
      'Mode local (le service génératif gratuit est indisponible).',
      'Lokaler Modus (der kostenlose generative Dienst ist nicht verfügbar).',
      'Local mode (the free generative service is unavailable).',
    ],
    'assistantSuggestions': ['Suggestions', 'Vorschläge', 'Suggestions'],
    'assistantInterviewPrompt': [
      'Préparer mon entretien',
      'Mein Gespräch vorbereiten',
      'Prepare my interview',
    ],
    'assistantLetterPrompt': [
      'Créer une lettre',
      'Anschreiben erstellen',
      'Create a letter',
    ],
    'assistantCvPrompt': [
      'Améliorer mon CV',
      'Meinen Lebenslauf verbessern',
      'Improve my CV',
    ],
    'assistantHint': [
      'Pose une question à Nia…',
      'Stelle Nia eine Frage…',
      'Ask Nia a question…',
    ],
    'aiConsentTitle': [
      'Activer l’IA générative gratuite ?',
      'Kostenlose generative KI aktivieren?',
      'Enable free generative AI?',
    ],
    'aiConsentBody': [
      'Ta question, tes compétences, ta formation et le contexte de l’offre seront envoyés de façon anonymisée à Google Gemini. Ton nom, ton e-mail et le fichier de ton CV ne sont jamais transmis. Évite d’écrire des données sensibles. Le service gratuit de Google peut utiliser le contenu pour améliorer ses produits.',
      'Deine Frage, Kompetenzen, Ausbildung und der Jobkontext werden anonymisiert an Google Gemini gesendet. Dein Name, deine E-Mail-Adresse und deine Lebenslaufdatei werden niemals übertragen. Gib keine sensiblen Daten ein. Google kann Inhalte des kostenlosen Dienstes zur Verbesserung seiner Produkte verwenden.',
      'Your question, skills, education and job context will be sent anonymously to Google Gemini. Your name, email address and CV file are never transmitted. Do not enter sensitive data. Google may use content from the free service to improve its products.',
    ],
    'stayLocal': [
      'Rester en mode local',
      'Im lokalen Modus bleiben',
      'Stay in local mode',
    ],
    'summaryProvided': [
      'Résumé renseigné',
      'Zusammenfassung angegeben',
      'Summary provided',
    ],
    'skillCount': [
      '{count} compétence(s)',
      '{count} Kompetenz(en)',
      '{count} skill(s)',
    ],
    'informationPresent': [
      'Informations présentes',
      'Angaben vorhanden',
      'Information provided',
    ],
    'potentialPoints': [
      '+{count} points potentiels',
      '+{count} mögliche Punkte',
      '+{count} potential points',
    ],
    'secureSupabaseDocument': [
      'Document sécurisé dans Supabase',
      'Dokument sicher in Supabase gespeichert',
      'Document secured in Supabase',
    ],
    'interviewTitleCompany': [
      'Entretien · {company}',
      'Vorstellungsgespräch · {company}',
      'Interview · {company}',
    ],
    'interviewProgressPrivate': [
      '{progress} % préparé · réponses privées sur cet appareil',
      '{progress} % vorbereitet · Antworten bleiben auf diesem Gerät',
      '{progress}% prepared · answers stay private on this device',
    ],
    'questionProgress': [
      'Question {current}/{total}',
      'Frage {current}/{total}',
      'Question {current}/{total}',
    ],
    'interviewRoleSkillsFallback': [
      'les compétences clés du poste',
      'die wichtigsten Kompetenzen der Stelle',
      'the role’s key skills',
    ],
    'interviewStudyFallback': [
      'ta formation',
      'dein Studium',
      'your degree programme',
    ],
    'interviewPitchQuestion': [
      'Présente-toi en 60 secondes.',
      'Stell dich in 60 Sekunden vor.',
      'Introduce yourself in 60 seconds.',
    ],
    'interviewPitchPurpose': [
      'Vérifier que ton parcours est clair et pertinent.',
      'Prüfen, ob dein Werdegang klar und relevant ist.',
      'Check that your background is clear and relevant.',
    ],
    'interviewPitchGuidance': [
      'Structure : situation actuelle, deux preuves utiles, puis objectif pour ce poste.',
      'Struktur: aktuelle Situation, zwei relevante Belege und anschließend dein Ziel für diese Stelle.',
      'Structure: current situation, two relevant examples, then your goal for this role.',
    ],
    'interviewLearnAtCompany': [
      'Ce que tu veux apprendre chez {company}',
      'Was du bei {company} lernen möchtest',
      'What you want to learn at {company}',
    ],
    'interviewMotivationQuestion': [
      'Pourquoi veux-tu rejoindre {company} comme {job} ?',
      'Warum möchtest du als {job} zu {company} kommen?',
      'Why do you want to join {company} as {job}?',
    ],
    'interviewMotivationPurpose': [
      'Mesurer ta motivation spécifique, pas une réponse générique.',
      'Deine konkrete Motivation statt einer allgemeinen Antwort beurteilen.',
      'Assess your specific motivation rather than a generic answer.',
    ],
    'interviewMotivationGuidance': [
      'Relie une mission de l’offre, une compétence de ton profil et un objectif professionnel.',
      'Verbinde eine Aufgabe aus der Stellenanzeige, eine Kompetenz aus deinem Profil und ein berufliches Ziel.',
      'Connect one responsibility from the job, one skill from your profile and one career goal.',
    ],
    'interviewSpecificTask': [
      'Une mission précise de l’offre',
      'Eine konkrete Aufgabe aus der Stellenanzeige',
      'One specific responsibility from the job',
    ],
    'interviewSkillInterest': [
      'Ton intérêt pour {skills}',
      'Dein Interesse an {skills}',
      'Your interest in {skills}',
    ],
    'interviewEarlyContribution': [
      'La contribution possible dès les premières semaines',
      'Dein möglicher Beitrag in den ersten Wochen',
      'How you could contribute in the first few weeks',
    ],
    'interviewStarQuestion': [
      'Raconte un projet où tu as utilisé ou appris rapidement {skills}.',
      'Erzähle von einem Projekt, in dem du {skills} eingesetzt oder schnell gelernt hast.',
      'Tell me about a project where you used or quickly learned {skills}.',
    ],
    'interviewStarPurpose': [
      'Obtenir une preuve concrète de tes compétences.',
      'Einen konkreten Beleg für deine Kompetenzen erhalten.',
      'Get concrete evidence of your skills.',
    ],
    'interviewStarGuidance': [
      'Utilise STAR : Situation, Tâche, Actions personnelles, Résultat mesurable.',
      'Nutze STAR: Situation, Aufgabe, deine eigenen Handlungen und ein messbares Ergebnis.',
      'Use STAR: Situation, Task, your own Actions and a measurable Result.',
    ],
    'interviewContextProblem': [
      'Contexte et problème',
      'Kontext und Problem',
      'Context and problem',
    ],
    'interviewExactResponsibility': [
      'Ta responsabilité exacte',
      'Deine genaue Verantwortung',
      'Your exact responsibility',
    ],
    'interviewDecisionsTools': [
      'Décisions et outils utilisés',
      'Entscheidungen und eingesetzte Werkzeuge',
      'Decisions and tools used',
    ],
    'interviewResultLesson': [
      'Résultat et leçon retenue',
      'Ergebnis und wichtigste Erkenntnis',
      'Result and lesson learned',
    ],
    'interviewTeamworkQuestion': [
      'Donne un exemple de désaccord ou de difficulté dans une équipe.',
      'Nenne ein Beispiel für eine Meinungsverschiedenheit oder Schwierigkeit im Team.',
      'Give an example of a disagreement or difficulty within a team.',
    ],
    'interviewTeamworkPurpose': [
      'Évaluer communication, fiabilité et capacité à progresser.',
      'Kommunikation, Zuverlässigkeit und Lernfähigkeit beurteilen.',
      'Assess communication, reliability and ability to improve.',
    ],
    'interviewTeamworkGuidance': [
      'Explique ce que tu as fait toi-même, comment tu as écouté et ce qui a changé.',
      'Erkläre, was du selbst getan hast, wie du zugehört hast und was sich verändert hat.',
      'Explain what you did yourself, how you listened and what changed.',
    ],
    'interviewFactsNoBlame': [
      'Faits sans accuser',
      'Fakten ohne Schuldzuweisung',
      'Facts without blame',
    ],
    'interviewCommunicationUsed': [
      'Communication employée',
      'Eingesetzte Kommunikation',
      'Communication approach used',
    ],
    'interviewSharedSolution': [
      'Solution commune',
      'Gemeinsame Lösung',
      'Shared solution',
    ],
    'interviewResult': ['Résultat', 'Ergebnis', 'Result'],
    'interviewGapQuestion': [
      'Quelle compétence de cette offre dois-tu encore renforcer, et comment vas-tu le faire ?',
      'Welche Kompetenz für diese Stelle musst du noch ausbauen und wie wirst du das tun?',
      'Which skill for this role do you still need to strengthen, and how will you do it?',
    ],
    'interviewGapPurpose': [
      'Tester ton honnêteté et ta capacité d’apprentissage.',
      'Deine Ehrlichkeit und Lernfähigkeit prüfen.',
      'Test your honesty and ability to learn.',
    ],
    'interviewGapGuidance': [
      'Choisis un écart réel mais gérable et propose un plan concret sur 30 jours.',
      'Wähle eine echte, aber überschaubare Lücke und schlage einen konkreten 30-Tage-Plan vor.',
      'Choose a genuine but manageable gap and propose a concrete 30-day plan.',
    ],
    'interviewLearningResource': [
      'Ressource ou mini-projet prévu',
      'Geplante Lernressource oder Mini-Projekt',
      'Planned learning resource or mini-project',
    ],
    'interviewMeasureProgress': [
      'Façon de mesurer les progrès',
      'Methode zur Fortschrittsmessung',
      'How you will measure progress',
    ],
    'interviewAvailabilityQuestion': [
      'Quelle est ta disponibilité pendant le semestre et les examens ?',
      'Wie sieht deine Verfügbarkeit während des Semesters und der Prüfungszeit aus?',
      'What is your availability during the semester and exam periods?',
    ],
    'interviewAvailabilityPurpose': [
      'Confirmer une organisation réaliste pour un Werkstudent job.',
      'Eine realistische Organisation für einen Werkstudentenjob bestätigen.',
      'Confirm a realistic schedule for a working-student job.',
    ],
    'interviewAvailabilityGuidance': [
      'Donne des heures précises, les jours possibles et anticipe les périodes d’examen.',
      'Nenne konkrete Stunden und mögliche Tage und plane Prüfungszeiten ein.',
      'Give specific hours and possible days, and plan ahead for exam periods.',
    ],
    'interviewWeeklyHours': [
      'Heures disponibles par semaine',
      'Verfügbare Stunden pro Woche',
      'Available hours per week',
    ],
    'interviewPreferredDays': [
      'Jours préférés',
      'Bevorzugte Tage',
      'Preferred days',
    ],
    'interviewExamNotice': [
      'Préavis pour les examens',
      'Vorlaufzeit für Prüfungen',
      'Notice needed for exams',
    ],
    'interviewCurrentSchedule': [
      'Lien avec ton organisation actuelle',
      'Bezug zu deiner aktuellen Zeitplanung',
      'Connection to your current schedule',
    ],
    'answerQuality': [
      'Qualité de la réponse : {score} %',
      'Antwortqualität: {score} %',
      'Answer quality: {score}%',
    ],
    'buildAnswerHere': [
      'Construis ta réponse ici',
      'Formuliere hier deine Antwort',
      'Build your answer here',
    ],
    'answerHint': [
      'Écris des faits précis, tes actions personnelles et un résultat…',
      'Nenne konkrete Fakten, deine eigenen Handlungen und ein Ergebnis…',
      'Write specific facts, your own actions and a result…',
    ],
    'rehearsedAnswer': [
      'Je l’ai répétée à voix haute',
      'Ich habe sie laut geübt',
      'I rehearsed it out loud',
    ],
    'rehearsalGoal': [
      'Objectif : une réponse naturelle en 60 à 90 secondes.',
      'Ziel: eine natürliche Antwort in 60 bis 90 Sekunden.',
      'Goal: a natural answer in 60 to 90 seconds.',
    ],
    'previous': ['Précédente', 'Zurück', 'Previous'],
    'finish': ['Terminer', 'Fertigstellen', 'Finish'],
    'publishWerkstudentJob': [
      'Publier une offre de Werkstudent',
      'Werkstudentenjob veröffentlichen',
      'Post a working-student job',
    ],
    'employerSubmissionNotice': [
      'L’offre sera vérifiée avant sa publication. Les coordonnées du contact ne seront pas affichées.',
      'Der Job wird vor der Veröffentlichung geprüft. Die Kontaktdaten werden nicht angezeigt.',
      'The job will be reviewed before publication. Contact details will not be displayed.',
    ],
    'requiredField': ['Champ obligatoire', 'Pflichtfeld', 'Required field'],
    'company': ['Entreprise', 'Unternehmen', 'Company'],
    'contactPerson': ['Personne de contact', 'Kontaktperson', 'Contact person'],
    'professionalEmail': [
      'E-mail professionnel',
      'Geschäftliche E-Mail',
      'Professional email',
    ],
    'jobTitle': ['Intitulé du poste', 'Stellenbezeichnung', 'Job title'],
    'germanCity': [
      'Ville en Allemagne',
      'Stadt in Deutschland',
      'City in Germany',
    ],
    'workMode': ['Mode de travail', 'Arbeitsmodell', 'Work mode'],
    'onSite': ['Sur site', 'Vor Ort', 'On site'],
    'remote': ['À distance', 'Remote', 'Remote'],
    'invalidNumber': ['Nombre invalide', 'Ungültige Zahl', 'Invalid number'],
    'belowMinimum': [
      'Inférieur au minimum',
      'Niedriger als das Minimum',
      'Below the minimum',
    ],
    'minimumSalary': [
      'Salaire min. €/h',
      'Mindestlohn €/Std.',
      'Min. salary €/h',
    ],
    'maximumSalary': [
      'Salaire max. €/h',
      'Höchstlohn €/Std.',
      'Max. salary €/h',
    ],
    'httpsRequired': [
      'Lien HTTPS obligatoire',
      'HTTPS-Link erforderlich',
      'HTTPS link required',
    ],
    'officialApplicationLink': [
      'Lien officiel pour candidater',
      'Offizieller Bewerbungslink',
      'Official application link',
    ],
    'jobSkills': [
      'Compétences (séparées par des virgules)',
      'Kompetenzen (durch Kommas getrennt)',
      'Skills (comma-separated)',
    ],
    'minimumDescription': [
      'Ajoute au moins 40 caractères',
      'Füge mindestens 40 Zeichen hinzu',
      'Add at least 40 characters',
    ],
    'jobDescription': [
      'Description du poste',
      'Stellenbeschreibung',
      'Job description',
    ],
    'submitForReview': [
      'Envoyer pour vérification',
      'Zur Prüfung senden',
      'Submit for review',
    ],
    'adminApprovedDefaultNote': [
      'Offre vérifiée et conforme aux règles de publication.',
      'Job geprüft und mit den Veröffentlichungsregeln konform.',
      'Job reviewed and compliant with publication rules.',
    ],
    'approveJobTitle': [
      'Approuver cette offre ?',
      'Diesen Job genehmigen?',
      'Approve this job?',
    ],
    'rejectJobTitle': [
      'Refuser cette offre ?',
      'Diesen Job ablehnen?',
      'Reject this job?',
    ],
    'internalNote': ['Note interne', 'Interne Notiz', 'Internal note'],
    'rejectionReason': [
      'Motif du refus',
      'Ablehnungsgrund',
      'Rejection reason',
    ],
    'checksCompleted': [
      'Contrôles effectués…',
      'Durchgeführte Prüfungen…',
      'Checks completed…',
    ],
    'correctionNeeded': [
      'Explique ce qui doit être corrigé…',
      'Beschreibe, was korrigiert werden muss…',
      'Explain what needs to be corrected…',
    ],
    'approve': ['Approuver', 'Genehmigen', 'Approve'],
    'reject': ['Refuser', 'Ablehnen', 'Reject'],
    'jobApprovedPublished': [
      'Offre approuvée et publiée.',
      'Job genehmigt und veröffentlicht.',
      'Job approved and published.',
    ],
    'jobRejectedHistory': [
      'Offre refusée et conservée dans l’historique.',
      'Job abgelehnt und im Verlauf gespeichert.',
      'Job rejected and kept in history.',
    ],
    'adminDecisionFailed': [
      'Décision non enregistrée : {error}',
      'Entscheidung nicht gespeichert: {error}',
      'Decision not saved: {error}',
    ],
    'moderationTitle': [
      'Modération des offres',
      'Jobmoderation',
      'Job moderation',
    ],
    'moderationSubtitle': [
      'Accès protégé par rôle administrateur Supabase',
      'Durch Supabase-Administratorrolle geschützt',
      'Protected by a Supabase administrator role',
    ],
    'pendingOnly': [
      'Afficher uniquement les offres en attente',
      'Nur ausstehende Jobs anzeigen',
      'Show pending jobs only',
    ],
    'moderationLoadFailed': [
      'Impossible de charger la file de modération.\n{error}',
      'Moderationswarteschlange konnte nicht geladen werden.\n{error}',
      'Could not load the moderation queue.\n{error}',
    ],
    'noJobsToModerate': [
      'Aucune offre à modérer pour le moment.',
      'Derzeit gibt es keine Jobs zu moderieren.',
      'There are no jobs to moderate right now.',
    ],
    'contactLabel': [
      'Contact : {value}',
      'Kontakt: {value}',
      'Contact: {value}',
    ],
    'verifyJobPage': [
      'Vérifier la page de l’offre',
      'Jobseite prüfen',
      'Check the job page',
    ],
    'lastNote': [
      'Dernière note : {note}',
      'Letzte Notiz: {note}',
      'Latest note: {note}',
    ],
    'errorProfileNotFound': [
      'Profil introuvable. Reconnecte-toi puis réessaie.',
      'Profil nicht gefunden. Melde dich erneut an und versuche es noch einmal.',
      'Profile not found. Sign in again and retry.',
    ],
    'errorSignInAddCv': [
      'Connecte-toi pour ajouter ton CV.',
      'Melde dich an, um deinen Lebenslauf hinzuzufügen.',
      'Sign in to add your CV.',
    ],
    'errorPdfRequired': [
      'Utilise un fichier PDF pour permettre une analyse fiable.',
      'Verwende eine PDF-Datei für eine zuverlässige Analyse.',
      'Use a PDF file to enable reliable analysis.',
    ],
    'errorSignInAnalyzeCv': [
      'Connecte-toi pour analyser ton CV.',
      'Melde dich an, um deinen Lebenslauf zu analysieren.',
      'Sign in to analyze your CV.',
    ],
    'errorCvAnalysisFailed': [
      'L’analyse du CV a échoué.',
      'Die Lebenslaufanalyse ist fehlgeschlagen.',
      'CV analysis failed.',
    ],
    'errorInvalidAnalyzedProfile': [
      'Le profil analysé est invalide.',
      'Das analysierte Profil ist ungültig.',
      'The analyzed profile is invalid.',
    ],
    'errorSignInViewCv': [
      'Connecte-toi pour consulter ton CV.',
      'Melde dich an, um deinen Lebenslauf anzusehen.',
      'Sign in to view your CV.',
    ],
    'errorInvalidCvPath': [
      'Chemin du CV invalide.',
      'Ungültiger Lebenslaufpfad.',
      'Invalid CV path.',
    ],
    'errorSignInPublishJob': [
      'Connecte-toi pour publier une offre entreprise.',
      'Melde dich an, um eine Unternehmensstelle zu veröffentlichen.',
      'Sign in to submit an employer job.',
    ],
    'errorAdminRequired': [
      'Accès administrateur requis.',
      'Administratorzugriff erforderlich.',
      'Administrator access required.',
    ],
    'errorDeleteAccountFailed': [
      'La suppression du compte a échoué.',
      'Das Konto konnte nicht gelöscht werden.',
      'Account deletion failed.',
    ],
    'errorSignInUseAi': [
      'Connecte-toi pour utiliser l’IA générative gratuite.',
      'Melde dich an, um die kostenlose generative KI zu verwenden.',
      'Sign in to use the free generative AI.',
    ],
    'errorAssistantUnavailable': [
      'L’assistant IA est momentanément indisponible.',
      'Der KI-Assistent ist vorübergehend nicht verfügbar.',
      'The AI assistant is temporarily unavailable.',
    ],
    'errorAiNoResponse': [
      'Aucune réponse n’a été générée.',
      'Es wurde keine Antwort erstellt.',
      'No response was generated.',
    ],
    'errorSignInReportAi': [
      'Connecte-toi pour signaler une réponse générée.',
      'Melde dich an, um eine generierte Antwort zu melden.',
      'Sign in to report a generated response.',
    ],
    'errorSignInPush': [
      'Connecte-toi pour activer les notifications.',
      'Melde dich an, um Benachrichtigungen zu aktivieren.',
      'Sign in to enable notifications.',
    ],
    'enableNotifications': [
      'Activer les notifications',
      'Benachrichtigungen aktivieren',
      'Enable notifications',
    ],
    'disableNotifications': [
      'Désactiver les notifications',
      'Benachrichtigungen deaktivieren',
      'Disable notifications',
    ],
    'pushEnabled': [
      'Notifications activées : tu seras alerté·e des nouvelles offres qui te correspondent.',
      'Benachrichtigungen aktiviert: Du wirst über neue passende Stellen informiert.',
      'Notifications enabled — you\'ll be alerted about new matching jobs.',
    ],
    'pushDisabled': [
      'Notifications désactivées.',
      'Benachrichtigungen deaktiviert.',
      'Notifications disabled.',
    ],
    'pushPermissionDenied': [
      'Autorisation refusée. Active les notifications dans les réglages de ton navigateur pour réessayer.',
      'Berechtigung verweigert. Aktiviere Benachrichtigungen in deinen Browser-Einstellungen, um es erneut zu versuchen.',
      'Permission denied. Enable notifications in your browser settings to try again.',
    ],
    'pushUnsupported': [
      'Les notifications ne sont pas prises en charge sur cet appareil ou ce navigateur.',
      'Benachrichtigungen werden auf diesem Gerät oder Browser nicht unterstützt.',
      'Notifications aren\'t supported on this device or browser.',
    ],
    'pushSubscribeFailed': [
      'Impossible d\'activer les notifications pour le moment. Réessaie plus tard.',
      'Benachrichtigungen konnten gerade nicht aktiviert werden. Versuche es später erneut.',
      'Couldn\'t enable notifications right now. Try again later.',
    ],
    'errorRefreshRejected': [
      'Mise à jour refusée ({status}).',
      'Aktualisierung abgelehnt ({status}).',
      'Refresh rejected ({status}).',
    ],
    'guestProfileName': ['Profil invité', 'Gastprofil', 'Guest profile'],
    'guestApplicantName': [
      'Candidat·e Werkly',
      'Werkly-Bewerber/in',
      'Werkly applicant',
    ],
    'cvWarnings': [
      'À vérifier : {items}',
      'Bitte prüfen: {items}',
      'Review: {items}',
    ],
    'cvLastAnalysis': [
      'Dernière analyse : {date}',
      'Letzte Analyse: {date}',
      'Last analysis: {date}',
    ],
    'moderationPending': ['En attente', 'Ausstehend', 'Pending'],
    'moderationApproved': ['Approuvée', 'Genehmigt', 'Approved'],
    'moderationRejected': ['Refusée', 'Abgelehnt', 'Rejected'],
    'pdfDocumentTitle': [
      'Candidature {job} - {company}',
      'Bewerbung {job} - {company}',
      'Application {job} - {company}',
    ],
    'pdfSubject': [
      'Dossier de candidature Werkstudent',
      'Werkstudent-Bewerbungsunterlagen',
      'Working-student application kit',
    ],
    'pdfCoverLetter': ['LETTRE DE MOTIVATION', 'ANSCHREIBEN', 'COVER LETTER'],
    'pdfTailoredProfile': [
      'PROFIL ADAPTÉ À L’OFFRE',
      'AUF DIE STELLE ABGESTIMMTES PROFIL',
      'PROFILE TAILORED TO THE ROLE',
    ],
    'pdfObjective': ['OBJECTIF', 'ZIEL', 'OBJECTIVE'],
    'pdfObjectiveText': [
      'Candidature au poste {job} chez {company}.',
      'Bewerbung als {job} bei {company}.',
      'Application for {job} at {company}.',
    ],
    'pdfProfessionalProfile': [
      'PROFIL PROFESSIONNEL',
      'BERUFLICHES PROFIL',
      'PROFESSIONAL PROFILE',
    ],
    'pdfStudentFallback': [
      'Étudiant motivé, fiable et prêt à mettre rapidement ses compétences en pratique.',
      'Motivierte und zuverlässige studentische Fachkraft, die Kompetenzen schnell in die Praxis umsetzt.',
      'Motivated and reliable student ready to put skills into practice quickly.',
    ],
    'pdfMatchingSkills': [
      'COMPÉTENCES CORRESPONDANTES',
      'PASSENDE KOMPETENZEN',
      'MATCHING SKILLS',
    ],
    'pdfNoExactMatch': [
      'Aucune correspondance exacte détectée. Vérifie les compétences avant l’envoi.',
      'Keine genaue Übereinstimmung erkannt. Prüfe die Kompetenzen vor dem Versand.',
      'No exact match detected. Review the skills before sending.',
    ],
    'pdfOtherSkills': [
      'AUTRES COMPÉTENCES DU PROFIL',
      'WEITERE KOMPETENZEN IM PROFIL',
      'OTHER PROFILE SKILLS',
    ],
    'pdfNoSkills': [
      'Aucune compétence ajoutée.',
      'Keine Kompetenzen hinzugefügt.',
      'No skills added.',
    ],
    'pdfKeywordsReview': [
      'MOTS-CLÉS À VÉRIFIER OU RENFORCER',
      'SCHLÜSSELWÖRTER ZUM PRÜFEN ODER AUSBAUEN',
      'KEYWORDS TO REVIEW OR STRENGTHEN',
    ],
    'pdfBeforeSending': ['AVANT ENVOI', 'VOR DEM VERSAND', 'BEFORE SENDING'],
    'pdfChecklistCompany': [
      'Vérifier les coordonnées et le nom de l’entreprise.',
      'Kontaktdaten und Unternehmensname prüfen.',
      'Check the contact details and company name.',
    ],
    'pdfChecklistProjects': [
      'Adapter les exemples de projets à l’offre.',
      'Projektbeispiele an die Stelle anpassen.',
      'Tailor project examples to the role.',
    ],
    'pdfChecklistAttachments': [
      'Joindre le CV original et les certificats demandés.',
      'Originalen Lebenslauf und angeforderte Nachweise beifügen.',
      'Attach the original CV and requested certificates.',
    ],
    'pdfChecklistAccuracy': [
      'Relire la lettre et ne conserver que les affirmations exactes.',
      'Anschreiben prüfen und nur korrekte Aussagen beibehalten.',
      'Review the letter and keep only accurate statements.',
    ],
    'pdfOriginalJob': ['OFFRE ORIGINALE', 'ORIGINALSTELLE', 'ORIGINAL JOB'],
    'pdfFooter': [
      'Document préparé avec Werkly - à vérifier avant envoi.',
      'Mit Werkly vorbereitet - vor dem Versand prüfen.',
      'Prepared with Werkly - review before sending.',
    ],
    'notificationNewJobMatch': [
      'Nouvelle offre à {match} %',
      'Neuer Job mit {match} %',
      'New job at {match}%',
    ],
    'applicationReminderTitle': [
      'Rappel de candidature',
      'Bewerbungserinnerung',
      'Application reminder',
    ],
    'notificationJobAtCompany': [
      '{job} chez {company}',
      '{job} bei {company}',
      '{job} at {company}',
    ],
    'notificationChannelName': [
      'Alertes et rappels Werkly',
      'Werkly-Hinweise und Erinnerungen',
      'Werkly alerts and reminders',
    ],
    'notificationChannelDescription': [
      'Nouvelles offres et rappels de candidatures',
      'Neue Jobs und Bewerbungserinnerungen',
      'New jobs and application reminders',
    ],
    'openWerkly': ['Ouvrir Werkly', 'Werkly öffnen', 'Open Werkly'],
    'authInvalidCredentials': [
      'Adresse e-mail ou mot de passe incorrect.',
      'E-Mail-Adresse oder Passwort ist falsch.',
      'Incorrect email address or password.',
    ],
    'authEmailNotConfirmed': [
      'Confirme d’abord ton adresse e-mail.',
      'Bestätige zuerst deine E-Mail-Adresse.',
      'Confirm your email address first.',
    ],
    'authUserExists': [
      'Un compte existe déjà avec cette adresse e-mail.',
      'Für diese E-Mail-Adresse besteht bereits ein Konto.',
      'An account already exists for this email address.',
    ],
    'authRateLimit': [
      'Trop de tentatives. Attends quelques minutes puis réessaie.',
      'Zu viele Versuche. Warte einige Minuten und versuche es erneut.',
      'Too many attempts. Wait a few minutes and try again.',
    ],
    'authWeakPassword': [
      'Choisis un mot de passe plus sûr d’au moins 8 caractères.',
      'Wähle ein sichereres Passwort mit mindestens 8 Zeichen.',
      'Choose a stronger password with at least 8 characters.',
    ],
    'authExpiredLink': [
      'Ce lien a expiré ou a déjà été utilisé. Demande un nouveau lien.',
      'Dieser Link ist abgelaufen oder wurde bereits verwendet. Fordere einen neuen Link an.',
      'This link has expired or was already used. Request a new link.',
    ],
    'authGenericError': [
      'L’opération n’a pas abouti. Réessaie dans un instant.',
      'Der Vorgang konnte nicht abgeschlossen werden. Versuche es gleich erneut.',
      'The operation could not be completed. Try again in a moment.',
    ],
    'savedSearchDefaultName': ['Ma recherche', 'Meine Suche', 'My search'],
    'legalAttribution': [
      'Cartographie © contributeurs OpenStreetMap (ODbL). Offres publiques synchronisées depuis la Bundesagentur, Greenhouse et Lever.',
      'Kartenmaterial © OpenStreetMap-Mitwirkende (ODbL). Öffentliche Jobs werden von der Bundesagentur, Greenhouse und Lever synchronisiert.',
      'Map data © OpenStreetMap contributors (ODbL). Public jobs are synchronized from the Bundesagentur, Greenhouse and Lever.',
    ],
    'applicationFilePrefix': ['candidature', 'bewerbung', 'application'],
    'countryGermany': ['Allemagne', 'Deutschland', 'Germany'],
    'save': ['Enregistrer', 'Speichern', 'Save'],
    'cancel': ['Annuler', 'Abbrechen', 'Cancel'],
    'close': ['Fermer', 'Schließen', 'Close'],
  };

  String get(String key) {
    final values = _values[key];
    if (values == null) return key;
    return values[language.index];
  }

  String format(String key, Map<String, Object> replacements) {
    var value = get(key);
    for (final entry in replacements.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return value;
  }
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings(AppLanguageController.language.value);

  String tr(String key) => strings.get(key);

  String trFormat(String key, Map<String, Object> replacements) =>
      strings.format(key, replacements);
}
