import QtQuick 2.5
import QtQuick.Controls 1.4

Item {
    id: commitDelegateBorder
    property variant listView
    property variant mouseArea
    property variant model
    property string fontFamily: "DejaVu Sans Mono"
    width: listView.width
    height: item.height
    implicitWidth: commitDelegateBorder.x + row.implicitWidth
    implicitHeight: descriptionText.implicitHeight

    focus: true
    Keys.onPressed: {
        if (event.key === Qt.Key_P) {
            commits.setOperation(index, "pick");
        } else if (event.key === Qt.Key_R) {
            commits.setOperation(index, "reword");
        } else if (event.key === Qt.Key_E) {
            commits.setOperation(index, "edit");
        } else if (event.key === Qt.Key_S) {
            commits.setOperation(index, "squash");
        } else if (event.key === Qt.Key_F) {
            commits.setOperation(index, "fixup");
        } else if (event.key === Qt.Key_D) {
            commits.setOperation(index, "DELETE");
        } else if (event.key === Qt.Key_T) {
            model.move(index, 0);
        }
    }

    Rectangle {
        id: item
        parent: loc
        x: commitDelegateBorder.x
        y: commitDelegateBorder.y - listView.contentY
        width: commitDelegateBorder.width
        height: descriptionText.implicitHeight
        color: hoverArea.containsMouse ? "#e8eff3" : "transparent"

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onPressed: {
                mouse.accepted = false;
            }
            onEntered: {
                commitDelegateBorder.forceActiveFocus();
            }
        }
        Row {
            id: row
            spacing: 5
            width: parent.width
            property int implicitWidth: rowPart1.width + spacing + descriptionText.implicitWidth
            Row {
                id: rowPart1
                spacing: 5
                Item {
                    // Graphical line-dot for commits
                    width: 8
                    height: commitDelegateBorder.height
                    Rectangle {
                        x: 2.5
                        width: 2.5
                        // If last item, only show top part of line.
                        height: (index+1 != listView.count)
                                ? commitDelegateBorder.height
                                : 3
                        color: "black"
                    }
                    Rectangle {
                        y: 2
                        width: 7
                        height: 7
                        radius: 3.5
                        color: "yellow"
                        border.color: "#0000ff"
                    }
                }
                Text {
                    text: index
                    width: index_text.width
                    font.family: fontFamily
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                        }
                    }
                    Text {
                        id: index_text
                        text: "000"
                        font.family: fontFamily
                        visible: false
                    }
                }
                Text {
                    text: operation
                    width: op_text.width
                    font.family: fontFamily
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            commits.nextOperation(index);
                        }
                    }
                    Text {
                        id: op_text
                        text: "WWWWWW"
                        font.family: fontFamily
                        visible: false
                    }
                }
                Text {
                    text: sha
                    font.family: fontFamily
                    MouseArea {
                        anchors.fill: parent
                        onDoubleClicked: {
                            if (index != 0) {
                                commits.move(index, 0);
                            }
                        }
                        onPressed: {
                            mouse.accepted = false;
                        }
                    }
                }
                Item {
                    width: 5
                    height: 1
                }
            }
            Text {
                id: descriptionText
                text: description
                font.family: fontFamily
                width: parent.width - rowPart1.width - parent.spacing
                wrapMode: Text.WordWrap
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                        if (index != 0) {
                            commits.move(index, 0);
                        }
                    }
                    onPressed: {
                        mouse.accepted = false;
                    }
                }
            }
        }
        Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Behavior on y {
            enabled: main.ready && item.state != "active"
            NumberAnimation { duration: 400; easing.type: Easing.OutBack }
        }
        states: State {
            name: "active"
            when: mouseArea.currentId == sha
            PropertyChanges {
                target: item
                color: "transparent"
                x: commitDelegateBorder.x + 30
                y: Math.max(0, Math.min(mouseArea.mouseY - height/2,
                                        mouseArea.height - height))
                z: 10
            }
        }
    }
}
