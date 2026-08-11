import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import QtQuick.LocalStorage

PlasmoidItem {
    id: root

    compactRepresentation: Item {
        PlasmaComponents.ToolButton {
            anchors.centerIn: parent
            icon.name: "checkbox"
            onClicked: root.expanded = !root.expanded
        }
    }

    preferredRepresentation: fullRepresentation
    fullRepresentation: Item {
        id: widgetContainer
        implicitWidth: 320
        implicitHeight: 400
        Layout.minimumWidth: 240
        Layout.minimumHeight: 200

        property int activeCount: 0
        property int completedCount: 0

        function getDb() {
            return LocalStorage.openDatabaseSync("DesktopTodo", "1.0", "Desktop Todo List", 100000);
        }

        function initDb() {
            var db = getDb();
            db.transaction(function(tx) {
                tx.executeSql("CREATE TABLE IF NOT EXISTS todos(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT NOT NULL, done INTEGER DEFAULT 0, created_at TEXT DEFAULT (datetime('now')))");
            });
            loadTodos();
        }

        function loadTodos() {
            todoModel.clear();
            var db = getDb();
            db.transaction(function(tx) {
                var rs = tx.executeSql("SELECT id, text, done FROM todos ORDER BY done ASC, created_at DESC");
                var active = 0, completed = 0;
                for (var i = 0; i < rs.rows.length; i++) {
                    var item = rs.rows.item(i);
                    todoModel.append({todoId: item.id, todoText: item.text, todoDone: item.done === 1});
                    if (item.done === 1) completed++;
                    else active++;
                }
                widgetContainer.activeCount = active;
                widgetContainer.completedCount = completed;
            });
        }

        function addTodo(text) {
            text = text.trim();
            if (!text.length) return;
            var db = getDb();
            db.transaction(function(tx) { tx.executeSql("INSERT INTO todos (text) VALUES (?)", [text]); });
            loadTodos();
        }

        function toggleTodo(id, currentDone) {
            var db = getDb();
            db.transaction(function(tx) { tx.executeSql("UPDATE todos SET done = ? WHERE id = ?", [currentDone ? 0 : 1, id]); });
            loadTodos();
        }

        function deleteTodo(id) {
            var db = getDb();
            db.transaction(function(tx) { tx.executeSql("DELETE FROM todos WHERE id = ?", [id]); });
            loadTodos();
        }

        function editTodo(id, newText) {
            newText = newText.trim();
            if (!newText.length) { deleteTodo(id); return; }
            var db = getDb();
            db.transaction(function(tx) { tx.executeSql("UPDATE todos SET text = ? WHERE id = ?", [newText, id]); });
            loadTodos();
        }

        Component.onCompleted: initDb()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing * 2
            spacing: Kirigami.Units.smallSpacing

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Heading {
                    level: 2
                    text: "📋 Desktop Todo"
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                PlasmaComponents.ToolButton {
                    icon.name: "entry-clear"
                    QQC2.ToolTip { text: "Clear completed"; visible: parent.hovered }
                    onClicked: {
                        var db = getDb();
                        db.transaction(function(tx) { tx.executeSql("DELETE FROM todos WHERE done = 1"); });
                        loadTodos();
                    }
                }
            }

            // Add input
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.TextField {
                    id: inputField
                    Layout.fillWidth: true
                    placeholderText: "Add a new task..."
                    onAccepted: { addTodo(text); text = ""; }
                    Keys.onEscapePressed: { text = ""; focus = false; }
                }
                PlasmaComponents.Button {
                    icon.name: "list-add"
                    enabled: inputField.text.trim().length > 0
                    onClicked: { addTodo(inputField.text); inputField.text = ""; inputField.focus = true; }
                }
            }

            // Todo list
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: ListModel { id: todoModel }
                spacing: 2
                currentIndex: -1

                // Empty state
                Item {
                    anchors.centerIn: parent
                    visible: todoModel.count === 0
                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: "No tasks yet\nType something above to get started"
                        opacity: 0.5
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                delegate: Item {
                    id: delegate
                    required property int todoId
                    required property string todoText
                    required property bool todoDone

                    width: ListView.view.width
                    height: Math.max(36, todoLabel.implicitHeight + Kirigami.Units.smallSpacing * 2)
                    visible: true

                    property bool hovered: false

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallRadius
                        color: {
                            if (delegate.todoDone) return "transparent";
                            if (delegate.hovered || mouseArea.containsMouse) return Kirigami.Theme.highlightColor;
                            return "transparent";
                        }
                        opacity: delegate.todoDone ? 0.6 : 1.0
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: delegate.hovered = true
                        onExited: delegate.hovered = false
                        onDoubleClicked: {
                            editField.text = delegate.todoText;
                            editField.visible = true;
                            editField.forceActiveFocus();
                            labelContainer.visible = false;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        // Checkbox
                        Item {
                            width: 24; height: 24
                            Layout.alignment: Qt.AlignVCenter
                            Rectangle {
                                anchors.centerIn: parent
                                width: 20; height: 20; radius: 4
                                color: delegate.todoDone ? Kirigami.Theme.highlightColor : "transparent"
                                border.color: delegate.todoDone ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                                border.width: 2
                                opacity: delegate.todoDone ? 0.7 : 0.5
                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: delegate.todoDone ? Kirigami.Theme.highlightedTextColor : "transparent"
                                    font.bold: true
                                    font.pixelSize: 14
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toggleTodo(delegate.todoId, delegate.todoDone)
                            }
                        }

                        // Text label
                        Item {
                            id: labelContainer
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !editField.visible
                            PlasmaComponents.Label {
                                id: todoLabel
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                text: delegate.todoText
                                elide: Text.ElideRight
                                color: delegate.todoDone ? Kirigami.Theme.disabledTextColor : Kirigami.Theme.textColor
                                font.strikeout: delegate.todoDone
                            }
                        }

                        // Edit field
                        PlasmaComponents.TextField {
                            id: editField
                            Layout.fillWidth: true
                            visible: false
                            text: delegate.todoText
                            onAccepted: { editTodo(delegate.todoId, text); visible = false; labelContainer.visible = true; }
                            onActiveFocusChanged: { if (!activeFocus && visible) { editTodo(delegate.todoId, text); visible = false; labelContainer.visible = true; } }
                            Keys.onEscapePressed: { visible = false; labelContainer.visible = true; }
                        }

                        // Delete button (on hover)
                        PlasmaComponents.ToolButton {
                            icon.name: "window-close"
                            opacity: delegate.hovered ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 22; implicitHeight: 22
                            QQC2.ToolTip { text: "Delete this task"; visible: parent.hovered }
                            onClicked: deleteTodo(delegate.todoId)
                        }
                    }
                }
            }

            // Footer
            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.6
                text: {
                    var parts = [];
                    if (widgetContainer.activeCount > 0) parts.push(widgetContainer.activeCount + " active");
                    if (widgetContainer.completedCount > 0) parts.push(widgetContainer.completedCount + " completed");
                    return parts.length > 0 ? parts.join(" · ") : "No tasks";
                }
            }
        }
    }
}