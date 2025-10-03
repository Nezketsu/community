# TrustFactor - Guide d'Intégration

## 🔌 Intégrer le Widget TrustFactor dans un Realm Externe

Le widget TrustFactor est conçu pour être facilement intégrable dans n'importe quel realm Gno.

### 📋 Design du Widget (Noir & Blanc)

- **Bordure**: Noire (#000000), 3px, coins arrondis (15px)
- **Fond**: Blanc (#FFFFFF)
- **Texte**: Dégradés de noir/gris (#000, #333, #666)
- **Indicateur de confiance** (cercle):
  - ⚫ Noir (#000000) = Haute confiance (≥80%)
  - 🔘 Gris foncé (#666666) = Confiance moyenne (≥50%)
  - ⚪ Gris clair (#CCCCCC) = Faible confiance (<50%)

### 🚀 Utilisation Simple

#### Exemple 1: Widget du Visiteur (Origin Caller) - POUR HOME REALMS ⭐

```go
package home

import "gno.land/r/greg007/trustfactor"

func Render(path string) string {
    result := "# Bienvenue\n\n"

    // Widget du visiteur (origin caller) - Parfait pour home realms!
    result += trustfactor.RenderOriginCallerWidget()

    return result
}
```

#### Exemple 2: Widget du Realm Appelant

```go
package myapp

import "gno.land/r/greg007/trustfactor"

func Render(path string) string {
    result := "# Mon Application\n\n"

    // Widget du realm appelant (previous realm)
    result += trustfactor.RenderCallerWidget()

    return result
}
```

#### Exemple 3: Widget d'une Adresse Spécifique

```go
package myapp

import (
    "std"
    "gno.land/r/greg007/trustfactor"
)

func Render(path string) string {
    userAddr := std.Address("g1...")

    result := "# Mon Application\n\n"
    result += trustfactor.RenderWidget(userAddr)

    return result
}
```

#### Exemple 4: Intégration dans un Profil

```go
package userprofile

import (
    "std"
    "gno.land/r/greg007/trustfactor"
)

func RenderProfile(username string) string {
    // Récupérer l'adresse depuis le username
    addr := getUserAddress(username)

    result := "# Profil de " + username + "\n\n"

    // Widget TrustFactor
    result += "## Score de Confiance\n\n"
    result += trustfactor.RenderWidget(addr) + "\n\n"

    // Autres infos du profil
    result += "## Informations\n"
    // ...

    return result
}
```

#### Exemple 5: Marché avec Trust Score

```go
package marketplace

import (
    "std"
    "gno.land/r/greg007/trustfactor"
)

func ListSellers() string {
    result := "# Vendeurs\n\n"

    for _, seller := range sellers {
        result += "## " + seller.Name + "\n\n"

        // Afficher le trust score du vendeur
        result += trustfactor.RenderWidget(seller.Address) + "\n\n"

        result += "**Produits:** " + seller.ProductCount + "\n\n"
        result += "---\n\n"
    }

    return result
}
```

### 📊 API Publiques Disponibles

#### 1. `RenderOriginCallerWidget() string` ⭐ RECOMMANDÉ POUR HOME REALMS
Génère le widget pour le visiteur (origin caller) - Parfait pour les home realms!

```go
widget := trustfactor.RenderOriginCallerWidget()
// Retourne: ![TrustFactor Widget](data:image/svg+xml;base64,...)
```

#### 2. `RenderCallerWidget() string`
Génère le widget pour le realm appelant (previous realm).

```go
widget := trustfactor.RenderCallerWidget()
// Retourne: ![TrustFactor Widget](data:image/svg+xml;base64,...)
```

#### 3. `RenderWidget(addr std.Address) string`
Génère un widget SVG pour une adresse spécifique.

```go
widget := trustfactor.RenderWidget(addr)
// Retourne: ![TrustFactor Widget](data:image/svg+xml;base64,...)
```

#### 4. `QueryTrustScore(addr std.Address) (float64, bool)`
Récupère uniquement le score de trust (sans widget).

```go
score, exists := trustfactor.QueryTrustScore(addr)
if exists {
    // Utiliser le score
}
```

#### 5. `QueryUserDetails(addr std.Address) (float64, int, float64, bool)`
Récupère les détails complets: score, total votes, confiance.

```go
score, votes, confidence, exists := trustfactor.QueryUserDetails(addr)
```

#### 6. `IsTrustedUser(addr std.Address, minScore float64) bool`
Vérifie si un utilisateur atteint un seuil de confiance.

```go
if trustfactor.IsTrustedUser(addr, 7.0) {
    // Utilisateur de confiance (score ≥ 7.0)
}
```

### 🎯 Cas d'Usage Recommandés

1. **Marketplaces** - Afficher la réputation des vendeurs
2. **Forums/Blogs** - Montrer la crédibilité des auteurs
3. **DAO/Governance** - Identifier les membres de confiance
4. **NFT Platforms** - Trust score des créateurs
5. **P2P Trading** - Vérifier la fiabilité des traders
6. **Social Networks** - Badge de confiance sur les profils

### ⚙️ Configuration Minimale Requise

```go
import "gno.land/r/greg007/trustfactor"
```

C'est tout! Aucune configuration supplémentaire nécessaire.

### 📐 Dimensions du Widget

- **Largeur**: 300px
- **Hauteur**: 150px
- **Format**: SVG responsive (s'adapte à la taille du conteneur)
- **Rendu**: Base64 encodé pour compatibilité Markdown

### ✅ Avantages

- ✨ Design minimaliste noir & blanc
- 🚀 Facile à intégrer (1 ligne de code)
- 📦 Aucune dépendance externe
- 🔄 Mise à jour en temps réel depuis la blockchain
- 🎨 SVG scalable (pas de perte de qualité)
- 🌐 Compatible tous renderers Markdown Gno

### 📝 Notes Importantes

1. L'utilisateur doit être enregistré dans TrustFactor pour avoir un widget
2. Si l'utilisateur n'existe pas, le widget affichera un score de 0.0
3. Le widget reflète toujours l'état actuel sur la blockchain
4. Les couleurs sont en niveaux de gris pour un design neutre

### 🔗 Liens Utiles

- Realm TrustFactor: `gno.land/r/greg007/trustfactor`
- Package SVG: `gno.land/p/demo/svg`
- Documentation complète: Voir FEATURES.md et WIDGET.md
