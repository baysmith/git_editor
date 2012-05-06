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

    ListView {
        id: commitList
        model: commits
        delegate: CommitDelegate {
            listView: commitList
            model: commits
            fontFamily: main.font
        }
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
