# Desktop Todo — KDE Plasma 6 Widget

A simple, native todo list that lives on your KDE Plasma desktop.

Click **Show Desktop** → it's right there. Add, check off, edit, or delete tasks without ever opening another app.

## Features

- **Add tasks** — type in the input, press Enter or click **+**
- **Toggle done** — click the checkbox square
- **Edit tasks** — double-click the text, edit inline, press Enter
- **Delete tasks** — hover the row → **×** button appears
- **Clear all completed** — header button (broom icon)
- **Theme aware** — dark/light mode follows Plasma theme automatically
- **Data persists** — SQLite local storage, survives reboot
- **Panel mode** — compact icon when pinned to panel, expands on click
- **Resizable** — drag the edges of the desktop widget

## Install

```bash
# From the root of this project
kpackagetool6 --type Plasma/Applet --install .
```

Then:
1. Right-click your desktop → **Add Widgets**
2. Search for "Desktop Todo"
3. Drag it onto your desktop

After pulling updates, re-run the same command to re-install.

### Remove

```bash
kpackagetool6 --type Plasma/Applet --remove com.hermes.desktoptodo
```

## File Structure

```
plasma-todo-widget/
├── README.md
├── metadata.json          # Plasma applet metadata
└── contents/
    └── ui/
        └── main.qml       # The widget itself
```

## Data

Tasks are stored in `~/.local/share/plasma_plasmoids/DesktopTodo/` as a SQLite database. Safe to delete that directory to wipe all tasks.