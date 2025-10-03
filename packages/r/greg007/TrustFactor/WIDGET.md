# TrustFactor SVG Widget

## 📊 Widget de Trust Score

Le TrustFactor inclut maintenant un widget SVG élégant qui affiche le score de confiance d'un utilisateur.

### 🎨 Caractéristiques du Widget

- **Dimensions**: 300x150 pixels
- **Style**: Bordure arrondie avec coins de 15px de rayon
- **Bordure**: Bleue (#007BFF), 3px d'épaisseur
- **Fond**: Blanc

### 📐 Éléments du Widget

1. **Adresse** (en haut)
   - Texte gris (#666)
   - Taille: 12px
   - Format raccourci: `g1abc...xyz` (si > 20 caractères)

2. **Score de Trust** (au centre)
   - Texte bleu (#007BFF)
   - Taille: 48px, gras
   - Format: Score avec 1 décimale (ex: "7.5")

3. **Label "Trust Score"** (en bas)
   - Texte gris clair (#999)
   - Taille: 14px

4. **Indicateur de Confiance** (cercle en haut à droite)
   - 🟢 Vert (#28A745) si confiance ≥ 0.8
   - 🟡 Jaune (#FFC107) si confiance ≥ 0.5
   - 🔴 Rouge (#DC3545) si confiance < 0.5

### 🚀 Utilisation

#### Affichage Automatique
Le widget s'affiche automatiquement en haut de chaque page de profil utilisateur.

#### Fonction Publique
Pour utiliser le widget dans un autre contexte :

```go
import "gno.land/r/greg007/trustfactor"

func ShowWidget(addr std.Address) string {
    return trustfactor.RenderWidget(addr)
}
```

### 🔧 Packages Utilisés

- `gno.land/p/demo/svg` - Bibliothèque SVG de Gno
- `gno.land/p/nt/ufmt` - Formatage de texte

### 📦 Exemple de SVG Généré

Le widget génère un SVG encodé en base64 au format :
```
![TrustFactor Widget](data:image/svg+xml;base64,...)
```

### 🎯 Avantages

- ✅ Léger et performant (SVG pur)
- ✅ Responsive et scalable
- ✅ Pas de dépendances externes
- ✅ Indicateur visuel de confiance
- ✅ Affichage compact de l'information essentielle
- ✅ Compatible avec tous les renderers Markdown

### 🖼️ Apparence

```
┌──────────────────────────────────────┐
│  g1abc...xyz                    ● 🟢 │
│                                      │
│                                      │
│              7.5                     │
│                                      │
│                                      │
│          Trust Score                 │
└──────────────────────────────────────┘
```

Le cercle coloré (●) indique le niveau de confiance :
- Vert = Haute confiance (≥80%)
- Jaune = Confiance moyenne (≥50%)
- Rouge = Faible confiance (<50%)
