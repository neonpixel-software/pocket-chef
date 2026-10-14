# Politique de confidentialité de Recipe Raccoon

Dernière mise à jour : 9 octobre 2026

Ceci est une traduction de la [version anglaise](PRIVACY.md), qui est l'original. En cas de
différence, la version anglaise fait foi.

Recipe Raccoon est une app de recettes pour iPhone, iPad et Mac, créée par NeonPixel. Elle ne
recueille aucune donnée vous concernant. Il n'y a ni compte, ni publicité, ni statistiques, ni
suivi, et rien de ce que vous faites dans l'app n'est envoyé à NeonPixel.

## Ce qui reste chez vous

- **Vos recettes, étiquettes et photos** sont enregistrées sur votre appareil. Si vous activez
  la synchronisation iCloud dans Réglages, elles sont aussi enregistrées dans votre propre base
  de données iCloud privée, que vous seul pouvez lire. NeonPixel n'y a pas accès.
- **La capture de recettes** (transformer un texte saisi ou collé en recette) s'effectue sur
  votre appareil avec Apple Intelligence. Le texte n'est envoyé nulle part.
- **Les réglages**, par exemple si vous avez vu le guide de bienvenue ou activé la
  synchronisation, restent sur l'appareil.

## Quand l'app se connecte

L'app ne se connecte à internet que pour :

- **Récupérer une recette à partir d'un lien que vous collez.** L'app télécharge cette page
  directement depuis le site web, comme le ferait un navigateur. Le site voit la visite et peut
  appliquer sa propre politique de confidentialité. Rien ne passe par NeonPixel.
- **Synchroniser via iCloud,** si vous l'activez. Apple s'en charge selon la
  [politique de confidentialité d'Apple](https://www.apple.com/fr/legal/privacy/).
- **Télécharger les densités d'ingrédients** depuis le serveur de Recipe Raccoon, utilisées pour
  convertir entre tasses et grammes. La requête ne contient aucune information sur vous ou vos
  recettes, et le serveur n'enregistre pas les requêtes. Il garde en mémoire l'adresse d'où
  vient une requête pendant environ une minute, pour empêcher qu'un même appelant le surcharge.
  Si une requête échoue sur le serveur, son journal d'erreurs peut noter cette adresse le temps
  de diagnostiquer l'erreur ; le journal est supprimé par la rotation habituelle.

## Supprimer vos données

Supprimer l'app efface tout ce qui est enregistré sur l'appareil. Les recettes synchronisées via
iCloud peuvent être supprimées dans l'app avant de la supprimer, ou dans Réglages → [votre nom]
→ iCloud → Gérer le stockage sur iPhone et iPad (Réglages Système → [votre nom] → iCloud sur un
Mac).

## Enfants

Recipe Raccoon ne recueille de données auprès de personne, y compris les enfants.

## Modifications

Si cette politique change un jour, la nouvelle version sera publiée ici avec une nouvelle date.
Son historique est conservé dans le [dépôt public](https://github.com/neonpixel-software/recipe-raccoon/commits/main/PRIVACY.md)
de l'app.

## Contact

Pour toute question sur la confidentialité, ou sur l'app en général, vous pouvez ouvrir un
[ticket sur GitHub](https://github.com/neonpixel-software/recipe-raccoon/issues/new).
