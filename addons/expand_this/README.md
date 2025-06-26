# Expand This

**Expand This** is a lightweight plugin that automatically expands the property sections of selected node or resource types in the Godot Inspector.

This is especially useful for frequently-used nodes like `AnimationNodeStateMachineTransition`, `Node3D`, or any object whose collapsible sections you'd like to see expanded by default — saving time and reducing clicks.

---

## ✨ Features

- Adds an **"Auto Expand"** toggle to the top of the Inspector for supported objects.
- Automatically triggers the built-in **"Expand All"** inspector action when enabled.
- Remembers your preferences using a simple `ConfigFile` (`user://expand_this.cfg`).
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

## 🗃️ Preferences

- Preferences are stored in `user://expand_this.cfg` under an `[objects]` section.
- Only enabled types are stored; collapsed or default types are not saved.

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

Created by [Your Name]  
