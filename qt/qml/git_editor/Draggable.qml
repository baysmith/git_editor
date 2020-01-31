import QtQuick 2.5

MouseArea {
    id: dragArea
    property variant dragItem
    property variant listView
    property bool activateOnPressed: false
    anchors.fill: parent
    property int positionStarted: 0
    property int positionEnded: 0
    property int positionsMoved: Math.floor((positionEnded - positionStarted)/dragItem.height)
    property int newPosition: index + positionsMoved
    property bool held: false
    drag.axis: Drag.YAxis
    function startDrag() {
        dragItem.z = 2;
        positionStarted = dragItem.y;
        positionEnded = positionStarted
        dragArea.drag.target = dragItem;
        dragItem.opacity = 0.5;
        listView.interactive = false;
        held = true;
        drag.maximumY = (listView.height - listView.delegate.height - 1 + listView.contentY);
        drag.minimumY = listView.contentY;
    }
    onPressed: {
        if (activateOnPressed) {
            startDrag();
        }
    }
    onPressAndHold: {
        if (!activateOnPressed) {
            startDrag();
        }
    }
    onPositionChanged: {
        positionEnded = dragItem.y;
    }
    onReleased: {
        if (Math.abs(positionsMoved) < 1 && held == true) {
            dragItem.y = positionStarted;
        } else {
            if (held == true) {
                if (newPosition < 1) {
                    model.move(index, 0);
                } else if (newPosition > listView.count - 1) {
                    model.move(index, listView.count - 1);
                } else {
                    model.move(index, newPosition);
                }
            }
        }
        dragItem.z = 1;
        dragItem.opacity = 1;
        listView.interactive = true;
        dragArea.drag.target = null;
        held = false;
    }
}
