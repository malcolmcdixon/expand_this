# Expand This

**Expand This** is a lightweight plugin for the Godot Editor that automatically expands the Inspector sections you care about — saving time and repetitive clicks when working with nodes or resources that have collapsible property groups.

---

## ✨ Features

- Adds a custom **Auto Expand** panel to the Inspector.
- Lets you define **global rules** to auto-expand groups across all nodes/resources.
- Supports **per-category rules** that override the global rule for specific node types.
- Handles nested sections and sub-resource inspectors automatically.
- Stores your preferences in a simple `ConfigFile` — preferences persist across sessions.
- Lightweight, non-intrusive, and designed to feel native to the Godot Editor.

---

## ⚙️ How It Works

When you select any `Node` or `Resource`:
1. The plugin scans the Inspector’s sections and categories.
2. Sections are grouped into unique *category/group* combinations.
3. The Auto Expand panel shows toggle buttons for each group:
   - **Global toggle**: expands this group for all node/resource types.
   - **Group toggle**: expands this group for a specific category only, overriding the global rule.
   - Remove an override with a single click.
4. When rules match, sections unfold automatically — no more repeated manual expanding.

---

## 🔧 Installation

1. **Download or clone** this repository.
2. Copy the `addons/expand_this/` folder into your Godot project.
3. In Godot:
   - Open **Project > Project Settings > Plugins**.
   - Find **Expand This** in the list.
   - Click **Enable**.

---

## 📦 Usage

1. Select any supported `Node` or `Resource` in the Inspector.
2. Open the **Auto Expand** panel.
3. Toggle **Global** to expand the group for all objects.
4. Toggle **Group** to expand the group for the current category only.
5. Click the override icon to remove category-specific rules.

---

## 🗂️ Config File Location

Your preferences are stored in a platform-specific `ConfigFile`:

| OS | Location |
|-----------|-----------------------------------------------|
| **Windows** | `%APPDATA%\Godot\expand_this.cfg` |
| **macOS** | `~/Library/Application Support/Godot/expand_this.cfg` |
| **Linux** | `~/.local/share/godot/expand_this.cfg` |

To reset your rules, just delete `expand_this.cfg`.

---

## 💡 Example Use Cases

- Always expand **Parameters** in an `AnimationTree` node.
- Keep the **Transform** section of a `Node3D` open by default.
- Instantly unfold sections for `AnimationNodeStateMachineTransition` nodes.

---

## ✅ Compatibility

- ✔️ Designed for **Godot 4.3** and newer
- It is tested and works with the latest stable Godot releases. If you encounter any issues on newer versions, please report them!_

---

## 📄 License

MIT License — free to use, modify, and distribute.

---

## 🙋 Author

Created by **Malcolm Dixon**

---
