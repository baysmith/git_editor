import QtQuick 2.5
import QtQuick.Window 2.2
import QtQuick.Controls 1.1

Window {
    visible: true
    width: textEdit.implicitWidth + 10
    height: 360
    TextEdit {
        id: textEdit
        objectName: "textEdit"
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
    Button {
        text: "Abort"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        onClicked: {
            commits.abort = true;
            Qt.quit();
        }
    }
}
