# Intégrations d’offres Werkly

Werkly n’extrait pas les pages LinkedIn, Indeed ou StepStone par scraping. Plusieurs sources publiques gratuites sont activées et les sources commerciales doivent arriver par une intégration partenaire autorisée.

## Sources gratuites actives

La fonction Supabase `sync-free-jobs` lit, normalise et enregistre dans `jobs` :

- la Jobsuche de la Bundesagentur für Arbeit ;
- l’[API publique Arbeitnow](https://www.arbeitnow.com/blog/job-board-api), sans clé, limitée aux annonces étudiantes récentes du tableau allemand ;
- les pages carrières publiques Greenhouse de SumUp et Celonis ;
- les pages carrières publiques Lever de JustWatch, QuantCo, Netlight, Sport Alliance, Packmatic, Octopus Energy et FINN ;
- la [Posting API publique SmartRecruiters](https://developers.smartrecruiters.com/docs/posting-api), uniquement pour l’allowlist Redcare Pharmacy, AbbVie, Scalable Capital, Vattenfall et Robert Bosch Krankenhaus ;
- Adzuna, dès que les secrets `ADZUNA_APP_ID` et `ADZUNA_APP_KEY` sont configurés.

L’allowlist SmartRecruiters contient uniquement des identifiants constatés sur les pages carrières publiques officielles de ces employeurs. Werkly ne tente pas d’énumérer, de deviner ou de parcourir automatiquement les identifiants d’autres entreprises. Ajouter un employeur exige donc une vérification manuelle de sa page carrière et une modification explicite de l’allowlist.

## Attribution et liens d’origine

Chaque ligne enregistrée conserve un libellé `source` et une URL publique `source_url`. L’interface affiche un lien vers la fiche originale afin que l’étudiant puisse vérifier les informations et poursuivre sa candidature auprès de la source ou de l’employeur.

Pour Arbeitnow, ce lien vers la fiche Arbeitnow fournit le retour vers le site demandé par les conditions du flux gratuit. Pour SmartRecruiters, Werkly conserve l’URL publique de l’annonce ou, à défaut, son URL publique de candidature. Les annonces ne sont jamais présentées comme ayant été publiées par Werkly.

## Cadence et limites prudentes

- Le cron Supabase `werkly-daily-job-sync` exécute la synchronisation deux fois par jour, à 03:17 et 15:17 UTC.
- Une ouverture ou un rafraîchissement de l’application peut demander une synchronisation supplémentaire, mais le cache serveur interdit un nouveau téléchargement pendant 20 minutes après une exécution réussie.
- Arbeitnow est limité à trois pages par exécution. Cette fenêtre fournit des annonces récentes sans parcourir tout le catalogue ni surcharger l’API gratuite.
- SmartRecruiters charge des pages de 100 résultats jusqu’à cinq pages par recherche et par employeur. Les employeurs sont interrogés successivement et les lectures de détails sont plafonnées à six requêtes simultanées.
- Seules les offres allemandes correspondant à un rôle étudiant et publiées depuis moins de 120 jours sont conservées.
- Si une source échoue ou renvoie une réponse invalide/incomplète, le dernier cache valide reste disponible. Un résultat vide explicitement valide désactive en revanche les anciennes annonces de cette source.

Ces garde-fous protègent les services publics partagés. Ils ne constituent pas une garantie de disponibilité : les fournisseurs peuvent modifier leur format, leurs quotas ou leurs conditions. Avant d’augmenter la fréquence, le nombre de pages ou l’allowlist, il faut relire leur documentation et leurs conditions d’utilisation.

L’API Arbeitnow convient à ce MVP gratuit avec un lien retour. Avant toute monétisation ou redistribution à grande échelle, Werkly doit obtenir une confirmation écrite d’Arbeitnow afin de lever l’ambiguïté entre la permission décrite pour l’API et les conditions générales du site.

## Publications directes

Un employeur connecté peut proposer une offre dans l’application. La table `employer_job_submissions` protège les données par RLS : chaque employeur ne voit que ses propres propositions. Une annonce approuvée est publiée automatiquement dans `jobs` par un déclencheur de base de données.

## Accès nécessaires

- LinkedIn : statut LinkedIn Talent Solutions Partner et accès à l’API Job Posting.
- Indeed : intégration partenaire ATS approuvée. La Job Sync API sert à publier et gérer des annonces, pas à télécharger librement les résultats de recherche.
- StepStone : contrat de coopération/JobFeed et identifiants fournis par StepStone.

Ces accès ne sont pas nécessaires au fonctionnement gratuit de Werkly. Les boutons de recherche ouvrent une requête ciblée sur chaque plateforme, et de futurs flux partenaires pourront être ajoutés via `ingest-jobs` sans modifier l’application cliente.

## Interdiction du scraping

Werkly ne télécharge, ne parse et ne reproduit pas les pages de résultats LinkedIn, Indeed ou StepStone. Il ne contourne ni authentification, ni CAPTCHA, ni limitation technique. Tant qu’un accès partenaire officiel n’est pas accordé, l’application se limite à ouvrir une recherche ciblée sur la plateforme choisie.

Toute future intégration de ces trois services doit utiliser un contrat ou une API officiellement autorisée, respecter les droits de redistribution et arriver par le point d’ingestion protégé. Une clé récupérée dans le navigateur, un endpoint interne ou un robot de scraping ne constitue pas une intégration acceptable.

## Format normalisé

La fonction accepte un objet `jobs` contenant au maximum 500 annonces. Chaque annonce contient `externalId`, `title`, `company`, `location`, `source`, `sourceUrl` et, si disponibles, `latitude`, `longitude`, `remoteType`, salaires, tags et dates.

L’appel doit porter l’en-tête privé `x-werkly-ingest-token`. Le secret Supabase `JOB_INGEST_TOKEN` doit être configuré avant l’activation du point d’entrée. Les URL sont limitées aux domaines officiels de la source annoncée.

## OpenStreetMap

Werkly utilise `flutter_map` et les tuiles standard OpenStreetMap. Aucune clé API ni facturation Google n’est nécessaire. La carte affiche les coordonnées des offres, les marqueurs interactifs et le rayon de recherche.

L’application respecte les règles du serveur de tuiles avec l’identifiant `de.werkly.app`, une attribution visible `© OpenStreetMap contributors`, le cache HTTP normal et aucun téléchargement anticipé ou hors ligne. Pour une utilisation importante en production, remplace le serveur communautaire par un fournisseur de tuiles OpenStreetMap disposant d’un contrat et d’un SLA.

## Assistant gratuit

La fonction `ai-assistant` appelle Gemini uniquement pour un utilisateur connecté et uniquement après son accord dans l’application. Elle reçoit une question et un contexte professionnel anonymisé ; le nom, l’e-mail et le fichier du CV ne sont pas transmis. La clé `GEMINI_API_KEY` est un secret Supabase et ne doit jamais être distribuée dans l’application.
