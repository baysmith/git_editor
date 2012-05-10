import QtQuick 1.1

Rectangle {
    id: main
    width: 360
    height: 360
    property string font: "DejaVu Sans Mono"
    property int pushToIndex: -1

    focus: true
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: {
        if (event.key === Qt.Key_Q && event.modifiers === Qt.ControlModifier) {
            Qt.quit();
        }
    }

    Text {
        id: dummy_text
        text: "WWWWWW"
        visible: false
        font.family: main.font
    }

    ListView {
        id: commitList
        model: commits
        delegate: CommitDelegate {
            listView: commitList
            model: commits
            fontFamily: main.font
            mouseArea: loc
        }
        clip: true
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.bottom: commentsText.top

        MouseArea {
            id: loc
            // Original position in model
            property string currentId: "none"
            // Current Position in model
            property int newIndex
            // Item underneath cursor
            property int index: -1
            drag.target: loc
            drag.axis: Drag.YAxis
            anchors.fill: parent
            function updateIndex() {
                index = commitList.indexAt(mouseX, mouseY + commitList.contentY);
            }
            function updateCurrentId() {
                currentId = commits.get(newIndex = index).sha;
            }
            onPressed: {
                updateIndex();
            }
            onPressAndHold: {
                updateIndex();
                updateCurrentId();
            }
            onReleased: {
                currentId = "none";
            }
            onMousePositionChanged: {
                if (drag.active && currentId == "none") {
                    updateCurrentId();
                }
                if (currentId != "none") {
                    updateIndex();
                    if (index != -1 && index != newIndex) {
                        commits.move(newIndex, newIndex = index);
                    }
                }
            }
        }
    }
    Text {
        id: commentsText
        text: comments
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
    }
}
