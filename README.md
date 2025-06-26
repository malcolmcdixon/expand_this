# Expand This

**Expand This** is a lightweight plugin that automatically expands the property sections of selected node or resource types in the Godot Inspector.

This is especially useful for frequently-used nodes like `AnimationNodeStateMachineTransition`, `Node3D`, or any object whose collapsible sections you'd like to see expanded by default — saving time and reducing clicks.

---

## ✨ Features

- Adds an **"Auto Expand"** toggle to the top of the Inspector for supported objects.
- Automatically triggers the built-in **"Expand All"** inspector action when enabled.
- Remembers your preferences using a simple `ConfigFile`.
- Supports both `Node` and `Resource` types (e.g. `AnimationNodeStateMachineTransition`).
- Works across editor sessions — no need to re-toggle every time.
- Minimal and non-intrusive UI.

---

## 🔧 Installation

1. **Download or clone** this repository.
2. Copy the `addons/expand_this/` folder into your Godot project.
3. In Godot:
   - Go to **Project > Project Settings > Plugins** tab.
   - Find **Expand This** in the list.
   - Click **Enable**.

---

## 📦 Usage

1. Select any supported object in the Inspector (e.g. a `Node3D`, `Sprite2D`, or a state machine transition).
2. You'll see a small **"Auto Expand"** checkbox at the top of the Inspector.
3. Toggle it **on** to auto-expand the properties whenever this type of object is selected.

---

## 📁 Where is the config file stored?

| OS        | Location |
|-----------|----------|
| **Windows** | `%APPDATA%\Godot\expand_this.cfg` |
| **macOS**   | `~/Library/Application Support/Godot/expand_this.cfg` |
| **Linux**   | `~/.local/share/godot/expand_this.cfg` |

> If you ever need to **reset** the plugin’s preferences completely, just delete `expand_this.cfg` from the appropriate folder above.

---

## 💡 Example Use Case

When editing state machine transitions (`AnimationNodeStateMachineTransition`), Godot collapses most sections by default.  
With this plugin enabled, every transition you select is automatically fully expanded — no more repetitive clicking!

---

## 🧪 Compatibility

- ✅ Tested with Godot 4.3 and newer
- ❌ Not compatible with Godot 3.x

---

## 📄 License

MIT License — feel free to modify, distribute, or include in your own projects.

---

## 🙋 Author

Created by Malcolm Dixon
