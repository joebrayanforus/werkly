# Werkly

Werkly est une application Flutter mobile et web qui aide les étudiants à trouver et suivre des postes de Werkstudent en Allemagne.

## Fonctionnalités disponibles

- navigation immédiate sans compte ;
- tutoriel de première ouverture en quatre étapes, multilingue et rejouable depuis le profil ;
- offres réelles lues depuis Supabase, recherche, filtres de salaire, flexibilité et source ;
- favoris et suivi des candidatures persistants sur l’appareil en mode invité ;
- synchronisation des favoris, candidatures et du profil après connexion ;
- statuts de candidature modifiables ;
- profil professionnel, compétences, préférences et analyse structurée du CV ;
- score de compatibilité explicable fondé uniquement sur les critères réellement évaluables (compétences, mission, langue, études, expérience, salaire, distance, disponibilité et fraîcheur) ;
- dossier de candidature PDF en deux pages, prévisualisable, imprimable et partageable ;
- entraînement d’entretien personnalisé avec réponses et progression sauvegardées ;
- recherches sauvegardées, alertes de nouvelles offres et rappels de candidature ;
- carte OpenStreetMap avec offres et filtre de distance ;
- estimation réelle du trajet par OpenStreetMap/OSRM, avec cache local et lien d’itinéraire ;
- recherches intelligentes vers LinkedIn, Indeed et StepStone ;
- formulaire permettant aux entreprises de proposer une offre, avec vérification avant publication ;
- espace de modération réservé aux administrateurs ;
- assistant local pour CV, lettre de motivation et entretien, avec IA Gemini gratuite optionnelle ;
- interface principale disponible en français, allemand et anglais, avec choix mémorisé ;
- suppression du compte et des données personnelles.

## Sources d’offres

L’application synchronise gratuitement des offres réelles de Werkstudent publiées par la Bundesagentur für Arbeit, par [Arbeitnow](https://www.arbeitnow.com/blog/job-board-api) et par les pages carrières publiques d’entreprises utilisant Greenhouse, Lever ou SmartRecruiters. Les anciennes offres de démonstration sont désactivées dès la première synchronisation réussie.

Arbeitnow est interrogé sans clé API, sur une fenêtre volontairement limitée à trois pages par synchronisation. L’intégration SmartRecruiters utilise uniquement la Posting API publique et une liste explicite d’employeurs vérifiés : Redcare Pharmacy, AbbVie, Scalable Capital, Vattenfall et Robert Bosch Krankenhaus. Werkly ne découvre ni ne parcourt automatiquement d’autres identifiants d’entreprise.

Adzuna est également intégré. Pour l’activer, créez des identifiants gratuits sur le portail développeur Adzuna et enregistrez-les uniquement comme secrets Supabase sous les noms `ADZUNA_APP_ID` et `ADZUNA_APP_KEY`.

Le cron Supabase lance deux synchronisations quotidiennes à 03:17 et 15:17 UTC. L’application peut demander un rafraîchissement supplémentaire, mais le serveur réutilise le dernier résultat pendant 20 minutes. Les requêtes sont limitées, les offres de plus de 120 jours sont écartées et le dernier cache valide est conservé lorsqu’une source est indisponible ou renvoie une réponse invalide.

Chaque annonce conserve le nom de sa source et un lien vers sa page publique d’origine. Ce lien assure notamment l’attribution demandée par Arbeitnow et permet à l’étudiant de vérifier l’annonce avant de postuler.

Les entreprises connectées peuvent proposer directement une annonce. Elle reste au statut `pending` jusqu’à sa vérification dans la table `employer_job_submissions`. Le passage au statut `approved` la publie automatiquement dans `jobs` ; un rejet ou retrait la désactive.

Le point d’ingestion Supabase protégé `ingest-jobs` reste disponible pour de futurs flux partenaires. LinkedIn, Indeed et StepStone ne proposent pas de catalogue public de recherche réutilisable gratuitement : leurs intégrations officielles nécessitent une approbation ou un contrat partenaire. Werkly n’extrait donc jamais leurs pages ni leurs résultats par scraping et ne contourne aucun contrôle d’accès. L’application ouvre à la place une recherche ciblée sur la plateforme choisie ; un futur import devra passer par un flux officiel et autorisé.

Voir [docs/provider-integrations.md](docs/provider-integrations.md) pour le format attendu.

## IA générative gratuite

Sans configuration, Nia fonctionne localement avec des recommandations déterministes. Pour activer la génération de réponses personnalisées, créez une clé gratuite dans Google AI Studio puis ajoutez-la uniquement dans les secrets Supabase sous le nom `GEMINI_API_KEY`. La clé ne doit jamais être copiée dans le code Flutter.

L’IA générative est réservée aux comptes connectés afin de protéger le quota gratuit. Les fonctions serveur appliquent aussi une taille maximale, un délai d’expiration et des quotas par utilisateur. Aucun contenu du CV ou des conversations n’est enregistré dans la table de suivi des quotas. La navigation, les offres, la carte, les favoris et l’assistant local restent accessibles sans connexion.

## Lancer l’application

```powershell
flutter pub get
flutter run -d chrome
```

Pour Android, démarrez un émulateur dans Android Studio puis sélectionnez-le comme appareil Flutter.

## Vérifications

```powershell
dart analyze
flutter test
flutter build web --release
```

Sous Windows, `flutter test` nécessite le **Mode développeur Windows** afin que les plugins Flutter puissent créer leurs liens symboliques.

## Version Android Play Store

Le script suivant vérifie la signature et produit l’Android App Bundle :

```powershell
powershell -ExecutionPolicy Bypass -File .\tooling\build_android_release.ps1
```

Le fichier final est généré dans `build/app/outputs/bundle/release/app-release.aab`.

Ne partagez jamais le keystore ni ses mots de passe. La clé publique Supabase présente dans l’application est une clé client ; la sécurité des données repose sur les règles RLS de la base.
