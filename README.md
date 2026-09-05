<div align="center">

  <div style="background-color: #1E1E1E; padding: 40px 20px; border-radius: 28px;">
    <div style="background: #2A2A2A; border-radius: 36px; padding: 42px 18px; margin-bottom: 28px;">
      <h1 style="color: #E6DED6; font-weight: 350; letter-spacing: 2px; margin: 18px 0 8px;">Yoko Fantasy</h1>
      <p style="color: #BEB8AE; font-size: 1.2em; max-width: 700px; margin: 0 auto;">A content expansion mod for Brotato, focused on new gameplay systems, combat mechanics, enemies, items, weapons, and UI extensions.</p>
      <p style="color: #8A9E8B; font-size: 0.95em; margin-top: 12px;">GDScript • Godot • Brotato Mod Loader 6.0.0</p>
    </div>

    <p>
      <img src="https://img.shields.io/badge/GDScript-Godot-8A9E8B?style=flat-square" alt="GDScript / Godot">
      <img src="https://img.shields.io/badge/Mod_Loader-6.0.0-7A8E8E?style=flat-square" alt="Mod Loader 6.0.0">
      <img src="https://img.shields.io/badge/Version-0.0.1-9E8F7E?style=flat-square" alt="Version 0.0.1">
      <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-8A9E8B?style=flat-square" alt="MIT License"></a>
    </p>

    <p style="word-spacing: 6px; margin-top: 20px;">
      <a href="#-overview">Overview</a> &nbsp;•&nbsp;
      <a href="#-features">Features</a> &nbsp;•&nbsp;
      <a href="#-installation">Installation</a> &nbsp;•&nbsp;
      <a href="#-architecture">Architecture</a> &nbsp;•&nbsp;
      <a href="#-development">Development</a> &nbsp;•&nbsp;
      <a href="#-license">License</a>
    </p>
  </div>

</div>

---

## 📖 Overview

**Yoko Fantasy** is a Godot/GDScript-based content mod for **Brotato**. It extends the base game through Mod Loader script extensions and custom resource definitions, adding new gameplay systems, combat behavior, enemies, items, weapons, consumables, UI behavior, and special effects.

The project is designed as a modular expansion rather than a standalone Godot game. Its runtime entry point registers targeted script extensions, while `.tres` resources and content files provide the corresponding game data.

> **Development Status**
> The project is currently under active development. The current manifest version is `0.0.1` and the declared Mod Loader compatibility version is `6.0.0`.

## ✨ Features

### 🧩 Gameplay Systems

Yoko Fantasy introduces several interconnected gameplay systems:

- **Job system** — integrates job-related behavior into run data, menus, and the end-of-run flow.
- **Soul mechanics** — adds soul-related statistics and consumable interactions across player and run data.
- **Holy mechanics** — introduces holy-related effects and enemy interactions.
- **Erosion mechanics** — provides erosion-themed items and effects.
- **Limited-item mechanics** — adds progression rules tied to restricted item pools.

### ⚔️ Combat & Weapons

The combat layer extends both melee and ranged weapons with additional behavior, including:

- Kill-based stat progression.
- Reload triggers from shooting and critical hits.
- Conditional weapon switching.
- Lightning-chain hit effects.
- Weapon hit procs.
- Critical-damage overflow handling.
- Additional stat scaling for structures and related entities.
- Damage clamping and reflection behavior.
- Consumable-triggered combat and stat effects.

### 👾 Enemies & World Content

The project also adds or modifies enemy and world behavior:

- Plant-themed enemy content.
- World Tree interactions and damage restrictions.
- Cursed enemy mechanics.
- Additional enemy spawning rules.
- Kill-triggered buffs and healing.
- Conditional enemy stat changes.
- Target detection behavior.
- Lootworm-related extensions.
- Special interactions between enemies and world entities.

### 🛒 Shop & Run Systems

Shop and run-data extensions add additional progression and economy rules:

- Stat-based curses when entering or rerolling the shop.
- Tier-specific weapon upgrades.
- Converting selected weapons into items.
- Limited-item bonuses.
- Weapon-set bonuses.
- Shop synthesis behavior.
- Additional elite and enemy spawning rules.

### 🖥️ UI & Localization

The mod extends several gameplay and menu UI entry points and provides reusable localized descriptions for entity statistics. Translation resources are stored separately under `translations/`.

## 🚀 Installation

Yoko Fantasy is intended to be installed as a **Brotato Mod Loader** package.

### Requirements

- **Brotato**
- **Brotato Mod Loader 6.0.0** or a compatible version
- **Yoko-NewContentLoader**
- **Yoko-MoreStatsContainer**

The current `manifest.json` explicitly declares `Yoko-NewContentLoader` and `Yoko-MoreStatsContainer` as dependencies and specifies Mod Loader `6.0.0`.

### From a Release Package

1. Install Brotato and a compatible Brotato Mod Loader version.
2. Install the required dependencies:
   - `Yoko-NewContentLoader`
   - `Yoko-MoreStatsContainer`
3. Download a Yoko Fantasy release package.
4. Extract the mod into the Mod Loader mods directory.
5. Launch Brotato and allow Mod Loader to load the mod.

### From Source

Clone the repository:

```bash
git clone https://github.com/CYoJkoY/Yoko-Fantasy.git
cd Yoko-Fantasy
```

Deploy the repository through your normal Brotato Mod Loader development workflow.

> **Note**
> This repository is a Brotato mod project, not a standalone Godot game. It is therefore expected to contain Mod Loader scripts, `.tres` resources, content data, and extension files without a root `project.godot`.

## ⚙️ Architecture

Yoko Fantasy uses **Mod Loader script extensions** as its primary integration mechanism. The root `mod_main.gd` establishes the mod directory and registers extension scripts with `ModLoaderMod.install_script_extension()`.

The architecture is organized around the responsibility of each extension rather than a single monolithic gameplay script.

| Component | Role |
|---|---|
| `mod_main.gd` | Mod entry point and script-extension registration |
| `FantasyNewContent.gd` | New-content integration entry point |
| `NewContentData.tres` | Main content resource definitions |
| `NewContentDataDLC1.tres` | Additional content resource definitions |
| `content/` | Content resources and supporting data |
| `extensions/` | Base-game script extensions |
| `translations/` | Localization resources |
| `manifest.json` | Mod metadata, dependencies, and compatibility information |

## 🧠 Implementation Highlights

The extension architecture keeps modifications close to the systems they affect. The current extension set hooks into areas such as:

- Player and player-run data.
- Run data and linked statistics.
- Melee and ranged weapons.
- Enemies and neutral entities.
- Entity spawning and entity services.
- Wave management.
- Shops and shop-related progression.
- Turrets, gardens, and wandering bots.
- Gameplay and menu UI.
- Music management.

This structure provides several practical advantages:

- **Localized changes** — each extension targets a specific base-game responsibility.
- **Composable mechanics** — independent systems can interact without requiring a monolithic implementation.
- **Maintainability** — individual gameplay areas can be updated independently.
- **Explicit integration points** — `mod_main.gd` provides a clear registry of installed extensions.

## 📁 Project Structure

```text
Yoko-Fantasy/
├── 📁 .github/
├── 📁 content/
├── 📁 extensions/
├── 📁 translations/
├── 📄 FantasyNewContent.gd
├── ⚙️ NewContentData.tres
├── ⚙️ NewContentDataDLC1.tres
├── ⚙️ manifest.json
├── 📄 mod_main.gd
├── 📄 .editorconfig
├── 📄 .gitattributes
├── 📄 .gitignore
├── 📄 LICENSE
└── 📄 README.md
```

## 🛠️ Development

The project is written primarily in **GDScript** and is structured for Brotato Mod Loader development.

When adding a new mechanic:

1. Identify the base-game system that needs to be extended.
2. Add or update the corresponding script under `extensions/`.
3. Register the extension in `mod_main.gd`.
4. Place new content definitions in the appropriate `.tres` resources or `content/` directory.
5. Add localization entries under `translations/` for user-facing text.
6. Verify the implementation against the declared Mod Loader and dependency versions.

For larger systems, preserve the existing separation between gameplay logic, content definitions, UI integration, and localization.

## 📋 Compatibility & Dependencies

The current manifest declares the following:

| Component | Requirement |
|---|---|
| Mod Loader | `6.0.0` |
| Dependency | `Yoko-NewContentLoader` |
| Dependency | `Yoko-MoreStatsContainer` |
| Current Version | `0.0.1` |
| Author | `Yoko` |
| Compatible Game Versions | Not specified in the manifest |

The manifest currently leaves the compatible Brotato game-version list empty. Users should therefore verify compatibility with their installed game and Mod Loader versions before deployment.

## 🤝 Contributing

Bug reports, gameplay feedback, and code contributions are welcome.

When reporting an issue, include:

- Brotato version.
- Mod Loader version.
- Yoko Fantasy version.
- Versions of the required Yoko dependencies.
- A clear description of the problem.
- Reproduction steps and relevant logs when available.

For code contributions, keep changes focused and preserve the existing Mod Loader extension architecture.

## 📄 License

Yoko Fantasy is released under the **MIT License**. Copyright © 2025 CYoJkoY.

See [`LICENSE`](LICENSE) for the complete license text.

---

<div align="center">
  <sub>Yoko Fantasy • A Brotato content expansion project by Yoko</sub>
</div>
