import QtQuick 1.1

TextEdit {
    id: textEdit
    anchors.fill: parent
    text: value
    font.family: "DejaVu Sans Mono"
    focus: true
    selectByMouse: true
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: {
        if (event.key === Qt.Key_Q && event.modifiers === Qt.ControlModifier) {
            Qt.quit();
        }
    }
}
