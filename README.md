<div align="center">
  <h1>Yoko-Fantasy</h1>
  <p><strong>A systems-heavy fantasy expansion for Brotato, combining content with mechanics attached to existing game systems.</strong></p>
  <p>Jobs · Souls · Holy · Erosion · Combat · Enemies · Worlds · UI</p>
  <p>
    <a href="https://github.com/CYoJkoY/Yoko-Fantasy/releases"><img src="https://img.shields.io/github/v/release/CYoJkoY/Yoko-Fantasy?display_name=tag&sort=semver&style=flat-square&label=release" alt="Latest release"></a>
    <a href="https://github.com/CYoJkoY/Yoko-Fantasy/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/CYoJkoY/Yoko-Fantasy/release.yml?style=flat-square&label=build" alt="Build status"></a>
    <img src="https://img.shields.io/badge/Brotato-1.1.15.4-478CBF?style=flat-square" alt="Brotato 1.1.15.4">
    <img src="https://img.shields.io/badge/Mod%20Loader-6.3.0-5965FF?style=flat-square" alt="Mod Loader 6.3.0">
    <a href="LICENSE"><img src="https://img.shields.io/github/license/CYoJkoY/Yoko-Fantasy?style=flat-square" alt="MIT License"></a>
  </p>
  <p><a href="#what-it-is">Overview</a> · <a href="#systems">Systems</a> · <a href="#architecture">Architecture</a> · <a href="#installation">Install</a> · <a href="#development--support">Development</a></p>
</div>

> **Core boundary:** Godot resources define fantasy content, NewContentLoader handles common registration, and focused extensions integrate only the Brotato systems that need custom behavior.

## <img src="assets/readme/icons/overview.svg" width="20" height="20" alt=""> What it is

Yoko-Fantasy is a content and gameplay expansion for Brotato. It targets mechanics that need more than a resource definition but do not justify a separate gameplay framework.

```text
Content resources → NewContent registration → Targeted extensions → Brotato runtime
```

## <img src="assets/readme/icons/features.svg" width="20" height="20" alt=""> Systems

| System | Scope |
| :--- | :--- |
| Jobs | Job resources, registration, run integration, menu flow, end-of-run handling |
| Soul | Soul stats, consumables, drops, player / run integration |
| Holy | Holy stats, item interactions, enemy behavior |
| Erosion | Erosion-focused items and effects |
| Limited Items | Restricted pools and progression bonuses |
| Combat | Kill progression, reload triggers, weapon switching, lightning chains, hit effects, reflection, critical interactions |
| Enemies | Custom enemies, cursed behavior, targeting, spawning, healing, world interactions |
| Entities | Pets, turrets, gardens, wandering bots, special entities |
| Shop & Waves | Shop interactions, rerolls, synthesis, extra enemies, elites, wave behavior |
| World | Fantasy zones, backgrounds, title-screen resources, map behavior |
| UI & Localization | Menu integration, focus handling, descriptions, translations |

Representative content includes Holy and Blazing Path variants, Prism Tower, Healing Star, Soul Link, Crow, fantasy pets, and plant-themed enemies.

## <img src="assets/readme/icons/architecture.svg" width="20" height="20" alt=""> Architecture

`mod_main.gd` installs the explicit integrations used by the expansion. `FantasyNewContent.gd` connects the project to [Yoko-NewContentLoader](https://github.com/CYoJkoY/Yoko-NewContentLoader) and supplies project-specific registration hooks.

| Resource | Role |
| :--- | :--- |
| `NewContentData.tres` | Primary content registration |
| `NewContentDataDLC1.tres` | Additional content registration |
| `FantasyNewContent.gd` | Custom registration and content hooks |

The architecture keeps content inspectable while attaching deeper behavior to the owning Brotato subsystem.

## <img src="assets/readme/icons/installation.svg" width="20" height="20" alt=""> Installation

Requirements: **Brotato 1.1.15.4**, **Brotato Mod Loader 6.3.0**, [Yoko-NewContentLoader](https://github.com/CYoJkoY/Yoko-NewContentLoader), and [Yoko-MoreStatsContainer](https://github.com/CYoJkoY/Yoko-MoreStatsContainer).

1. Install Brotato and the required Mod Loader version.
2. Install both required Yoko dependencies.
3. Download the latest `Fantasy-*.zip` from [Releases](https://github.com/CYoJkoY/Yoko-Fantasy/releases).
4. Place the ZIP in the Mod Loader `mods` directory.
5. Launch Brotato and verify the dependency chain loads.

## <img src="assets/readme/icons/development.svg" width="20" height="20" alt=""> Development & support

When adding a mechanic, identify the owning Brotato system first and add the smallest required extension.

```text
New mechanic
   ├── Content / resource → content/
   ├── Runtime behavior   → extensions/
   ├── Registration       → mod_main.gd / NewContentData*.tres
   └── Localization       → translations/
```

`manifest.json` is authoritative for version **1.1.0**, dependencies, and compatibility. The release workflow rejects tags that do not match the manifest.

<a href="https://cyojkoy.github.io/Payment/"><img src="assets/readme/support-cta.svg" alt="Support Yoko-Fantasy" width="900" style="max-width:100%;height:auto;"></a>

Development support: **https://cyojkoy.github.io/Payment/**

## License

Yoko-Fantasy is distributed under the [Custom License](LICENSE).
