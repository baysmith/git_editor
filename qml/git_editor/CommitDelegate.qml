import QtQuick 1.1

Rectangle {
    id: commitDelegateBorder
    property variant listView
    property variant model
    property string fontFamily: "DejaVu Sans Mono"
    width: listView.width
    height: descriptionText.height

    Draggable {
        dragItem: parent
        listView: parent.listView
    }
    Row {
        spacing: 5
        Text {
            text: index
            width: 10
            font.family: fontFamily
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
            Draggable {
                dragItem: commitDelegateBorder
                activateOnPressed: true
                listView: commitDelegateBorder.listView
                onDoubleClicked: {
                    commits.move(index, 0);
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
        }
    }
}
