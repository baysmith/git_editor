// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1

Rectangle {
    id: main
    width: 360
    height: 360
    property string font: "DejaVu Sans Mono"

    Text {
        id: dummy_text
        text: "WWWWWW"
        visible: false
        font.family: main.font
    }

    Component {
        id: commitDelegate
        Rectangle {
            id: commitDelegateBorder
            width: parent.width
            height: descriptionText.height
            MouseArea {
                id: dragArea
                anchors.fill: parent
                property int positionStarted: 0
                property int positionEnded: 0
                property int positionsMoved: Math.floor((positionEnded - positionStarted)/descriptionText.height)
                property int newPosition: index + positionsMoved
                property bool held: false
                drag.axis: Drag.YAxis
                onPressAndHold: {
                    commitDelegateBorder.z = 2;
                    positionStarted = commitDelegateBorder.y;
                    dragArea.drag.target = commitDelegateBorder;
                    commitDelegateBorder.opacity = 0.5;
                    commitList.interactive = false;
                    held = true;
                    drag.maximumY = (main.height - descriptionText.height - 1 + commitList.contentY);
                    drag.minimumY = 0;
                }
                onPositionChanged: {
                    positionEnded = commitDelegateBorder.y;
                }
                onReleased: {
                    if (Math.abs(positionsMoved) < 1 && held == true) {
                        commitDelegateBorder.y = positionStarted;
                        commitDelegateBorder.opacity = 1;
                        commitList.interactive = true;
                        dragArea.drag.target = null;
                        held = false;
                    } else {
                        if (held == true) {
                            if (newPosition < 1) {
                                commitDelegateBorder.z = 1;
                                commits.move(index,0);
                                commitDelegateBorder.opacity = 1;
                                commitList.interactive = true;
                                dragArea.drag.target = null;
                                held = false;
                            } else if (newPosition > commitList.count - 1) {
                                commitDelegateBorder.z = 1;
                                commits.move(index,commitList.count - 1);
                                commitDelegateBorder.opacity = 1;
                                commitList.interactive = true;
                                dragArea.drag.target = null;
                                held = false;
                            } else {
                                commitDelegateBorder.z = 1;
                                commits.move(index,newPosition);
                                commitDelegateBorder.opacity = 1;
                                commitList.interactive = true;
                                dragArea.drag.target = null;
                                held = false;
                            }
                        }
                    }
                }
                Row {
                    spacing: 5
                    Text {
                        text: index
                        width: 10
                        font.family: main.font
                    }
                    Text {
                        text: operation
                        width: dummy_text.width
                        font.family: main.font
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                commits.nextOperation(index);
                            }
                        }
                    }
                    Text {
                        text: sha
                        font.family: main.font
                        MouseArea {
                            id: dragArea2
                            anchors.fill: parent
                            property int positionStarted: 0
                            property int positionEnded: 0
                            property int positionsMoved: Math.floor((positionEnded - positionStarted)/descriptionText.height)
                            property int newPosition: index + positionsMoved
                            property bool held: false
                            drag.axis: Drag.YAxis
                            onPressed: {
                                commitDelegateBorder.z = 2;
                                positionStarted = commitDelegateBorder.y;
                                positionEnded = positionStarted
                                dragArea2.drag.target = commitDelegateBorder;
                                commitDelegateBorder.opacity = 0.5;
                                commitList.interactive = false;
                                held = true;
                                drag.maximumY = (main.height - descriptionText.height - 1 + commitList.contentY);
                                drag.minimumY = 0;
                            }
                            onDoubleClicked: {
                                commits.move(index,0);
                            }
                            onPositionChanged: {
                                positionEnded = commitDelegateBorder.y;
                            }
                            onReleased: {
                                if (Math.abs(positionsMoved) < 1 && held == true) {
                                    commitDelegateBorder.y = positionStarted;
                                    commitDelegateBorder.opacity = 1;
                                    commitList.interactive = true;
                                    dragArea2.drag.target = null;
                                    held = false;
                                } else {
                                    if (held == true) {
                                        if (newPosition < 1) {
                                            commitDelegateBorder.z = 1;
                                            commits.move(index,0);
                                            commitDelegateBorder.opacity = 1;
                                            commitList.interactive = true;
                                            dragArea2.drag.target = null;
                                            held = false;
                                        } else if (newPosition > commitList.count - 1) {
                                            commitDelegateBorder.z = 1;
                                            commits.move(index,commitList.count - 1);
                                            commitDelegateBorder.opacity = 1;
                                            commitList.interactive = true;
                                            dragArea2.drag.target = null;
                                            held = false;
                                        } else {
                                            commitDelegateBorder.z = 1;
                                            commits.move(index,newPosition);
                                            commitDelegateBorder.opacity = 1;
                                            commitList.interactive = true;
                                            dragArea2.drag.target = null;
                                            held = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item { width: 5; height: 1 }
                    Text {
                        id: descriptionText
                        text: description
                        font.family: main.font
                    }
                }
            }
        }
    }

    ListView {
        id: commitList
        model: commits
        delegate: commitDelegate
        clip: true
        anchors.right: parent.right
        anchors.rightMargin: 5
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.bottom: commentsText.top
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
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Qt.quit();
            }
        }
    }
}
