# ReddSave Media

Application iOS SwiftUI qui télécharge localement les médias publiquement affichés dans les publications d’un profil Reddit.

## Confidentialité et fonctionnement

- aucune API Reddit, aucun endpoint JSON Reddit ;
- aucune connexion, aucun mot de passe, cookie, jeton ou client ID ;
- l’app lit uniquement les pages HTML publiques `reddit.com/user/<nom>/submitted/` ;
- une analyse est limitée à 20 pages publiques pour éviter un parcours illimité.

Les fichiers sont enregistrés dans `Fichiers > Sur mon iPhone > ReddSave Media`. Pour les images, l’app privilégie l’original `i.redd.it`. Pour les vidéos Reddit exposées sur la page, elle choisit le flux MP4 `DASH` ayant la plus grande hauteur disponible.

Les publications privées, supprimées, masquées, les favoris/sauvegardes, et tout contenu nécessitant un compte restent volontairement hors périmètre.

## Développement

Ouvrez `ReddSaveMedia.xcodeproj` dans Xcode 15 ou plus récent, sélectionnez une équipe de signature, puis lancez sur iOS 17 ou plus récent.

## GitHub Actions et LiveContainer

1. Poussez ce dossier dans un dépôt GitHub.
2. Créez puis poussez un tag, par exemple `v1.0.0`.
3. Le workflow construit un IPA non signé, crée une release, puis y joint `ReddSaveMedia.ipa` et un `repo.json` de type AltStore/SideStore.
4. Ajoutez cette URL dans SideStore/AltStore :

```
https://github.com/Leboxis/ReddSaveMedia/releases/latest/download/repo.json
```

Une signature est nécessaire pour l’installation initiale avec SideStore/AltStore. LiveContainer peut ensuite importer l’IPA depuis Fichiers. Le `repo.json` à la racine est un modèle ; celui ajouté à la release reçoit automatiquement le dépôt et la version du tag.

## Droits d’utilisation

Téléchargez uniquement des contenus que vous avez le droit de conserver. Respectez les droits d’auteur, les règles des communautés et les conditions de Reddit.
