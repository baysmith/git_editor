import QtQuick 1.1

Rectangle {
    id: commitDelegateBorder
    property variant listView
    property variant mouseArea
    property variant model
    property string fontFamily: "DejaVu Sans Mono"
    width: listView.width
    height: item.height

    Item {
        id: item
        parent: loc
        x: commitDelegateBorder.x
        y: commitDelegateBorder.y - listView.contentY
        width: commitDelegateBorder.width
        height: Math.max(16, descriptionText.height)
    Row {
        spacing: 5
        Image {
            height: 16
            width: 16
            source: pushToIndex == index ? "server_from_client.png" : "";
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pushToIndex = (pushToIndex == index) ? -1 : index;
                }
            }
        }
        Text {
            text: index
            width: 10
            font.family: fontFamily
            MouseArea {
                anchors.fill: parent
                onClicked: {
                }
            }
        }
        Text {
            text: operation
            width: dummy_text.width
            font.family: fontFamily
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    commits.nextOperation(index);
                }
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
        Text {
            id: descriptionText
            text: description
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
    }
    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
    Behavior on y { enabled: item.state != "active"; NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
    states: State {
        name: "active"
        when: mouseArea.currentId == sha
        PropertyChanges {
            target: item
            x: commitDelegateBorder.x + 30
            y: Math.max(0, Math.min(mouseArea.mouseY - height/2,
                                    mouseArea.height - height))
            z: 10
        }
    }
    }
}
