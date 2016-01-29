import QtQuick 2.5
import QtQuick.Window 2.2
import QtQuick.Controls 1.1

Window {
    visible: true
    width: 800
    height: 800
    x: Screen.width / 2 - width / 2
    y: Screen.height / 2 - height / 2

    function updateWindowSize() {
        height = Math.min(commitList.contentHeight + commentsText.height + 30, 1000);
        width = Math.min(commitList.implicitWidth + 30, 1000);
    }

    Component.onCompleted: {
        initTimer.start();
    }

    Rectangle {
        id: main
        anchors.fill: parent
        property string font: "DejaVu Sans Mono"
        property bool ready: false

        focus: true
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: {
            if (event.key === Qt.Key_Q && event.modifiers === Qt.ControlModifier) {
                Qt.quit();
            }
        }

        Timer {
            id: initTimer
            interval: 10
            running: false
            repeat: false
            onTriggered: {
                main.ready = true;
                updateWindowSize();
            }
        }

        ListView {
            id: commitList
            model: commits
            property int implicitWidth: 0
            delegate: CommitDelegate {
                listView: commitList
                model: commits
                fontFamily: main.font
                mouseArea: loc
                Component.onCompleted: {
                    if (implicitWidth > commitList.implicitWidth) {
                        commitList.implicitWidth = implicitWidth;
                    }
                }
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
                onPositionChanged: {
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
}
