<p align="center">
  <img src="Logo.png" width="128" height="128" alt="PhotoClean Icon">
</p>

<h1 align="center">PhotoClean</h1>

<p align="center">
  App de iOS para limpiar tu biblioteca de fotos deslizando. Estilo Tinder para triagear tu Carrete.
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.zh-Hant.md">繁體中文</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.es.md">Español</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS%2017.0%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/liquid%20glass-iOS%2026-black" alt="Liquid Glass">
  <img src="https://img.shields.io/badge/license-PolyForm%20NC%201.0-green" alt="License">
</p>

## Características

- **Gestos de deslizar** — Desliza a la izquierda para desechar, a la derecha para conservar. Funciona con fotos y vídeos.
- **Tira de vista previa** — Ve las siguientes 6 fotos al pie de la pantalla. Toca para saltar, pulsa y mantén para previsualizar.
- **Eliminación en dos pasos** — Las fotos van primero a una papelera interna; después una sola confirmación las envía en lote a «Eliminadas recientemente» de iOS.
- **Deshacer** — El último deslizamiento siempre es reversible.
- **Reproducción de vídeo integrada** — Toca el botón de reproducción en cualquier tarjeta de vídeo para abrir el reproductor AVKit a pantalla completa.
- **Liquid Glass** — Efectos de cristal nativos de iOS 26, con retroceso a `.ultraThinMaterial` en iOS 17–25.
- **Diseño solo modo oscuro** — Fondo negro y cromo mínimo, optimizado para visualizar fotos.
- **Multilenguaje** — Inglés, chino tradicional, chino simplificado, japonés y español, con cambio automático según el idioma del dispositivo.
- **100 % offline** — Sin servidores, sin cuentas, sin telemetría. Todo queda en tu dispositivo.

## Requisitos

- iOS 17.0 o superior (iOS 26+ para el efecto Liquid Glass completo)
- Xcode 16+ (se recomienda Xcode 26+)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Compilación

```bash
git clone https://github.com/Kazzx9921/PhotoClean.git
cd PhotoClean
xcodegen generate
open PhotoClean.xcodeproj
```

En Xcode:
1. Selecciona el destino `PhotoClean` → **Signing & Capabilities**
2. Activa *Automatically manage signing* y elige tu Team
3. Conecta tu iPhone y elígelo como destino de ejecución
4. Pulsa ⌘R

Si usas un Apple ID gratuito (Personal Team), las apps caducan a los 7 días y solo puedes tener 3 instaladas a la vez. Una cuenta Apple Developer de pago ($99/año) elimina estos límites.

## Arquitectura

```
PhotoClean/
├─ App/                  @main y enrutamiento raíz
├─ Core/                 PhotoLibraryService, TrashStore, UndoStack, Models, FormatHelper
├─ Features/
│  ├─ Home/              Vista de deslizar + view model + tira de vista previa + tarjeta + reproductor
│  ├─ Trash/             Cuadrícula de eliminación por lotes + flujo de confirmación
│  ├─ Onboarding/        Bienvenida de 3 páginas + solicitud de permisos
│  └─ Settings/          Estadísticas + información + enlace a GitHub
├─ UI/                   Haptics, LiquidGlass (modificador iOS 26)
├─ Resources/            Localizable.xcstrings (5 idiomas)
└─ Assets.xcassets/      AppIcon + AccentColor
```

## Decisiones de diseño

| Decisión | Motivo |
|---|---|
| Eliminación por lotes, no por desliz | iOS requiere una confirmación del sistema cada vez que se llama a `PHAssetChangeRequest.deleteAssets`. Un diálogo por foto interrumpiría el ritmo — agruparlos hace que solo aparezca uno. |
| Sin índice propio de assets | `PHAsset.fetchAssets(withLocalIdentifiers:)` hace búsquedas O(1) usando el índice nativo de Photos. Ahorra ~5 MB de RAM en bibliotecas de 50 000 fotos. |
| `PHPhotoLibraryChangeObserver` | iOS notifica los cambios de biblioteca activamente, así que los cambios de fase de escena no fuerzan recarga. |
| LRU de miniaturas tope 50 | Coincide con el conjunto de trabajo de la tira — huella de memoria predecible. |
| Barras superior/inferior en overlay | Liquid Glass refracta contenido visible debajo. Las barras flotan sobre la foto para que el cristal cobre vida. |

## Historial de estrellas

<a href="https://www.star-history.com/#Kazzx9921/PhotoClean&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Kazzx9921/PhotoClean&type=date&legend=top-left" />
 </picture>
</a>

## Licencia

[PolyForm Noncommercial 1.0.0](LICENSE) — libre para clonar, modificar e instalar en tu propio dispositivo. **Prohibido** revender o republicar en cualquier tienda de apps.

Para licencias comerciales, contacta con <geekaz.net@gmail.com>.

## Créditos

- Apple SwiftUI, Photos, AVKit, PhotosUI
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
