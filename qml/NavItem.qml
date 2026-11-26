import QtQuick

Item {
    id: root

    property string label: ""
    property string icon: "today"
    property bool active: false
    property bool showHighlight: true

    signal clicked()

    implicitHeight: 46
    implicitWidth: 180

    scale: mouse.pressed ? 0.98 : 1
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: root.active && root.showHighlight
            ? Qt.rgba(1, 1, 1, 0.15)
            : (mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0))
        border.width: root.active && root.showHighlight ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, 0.18)
        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Image {
            width: 19
            height: 19
            anchors.verticalCenter: parent.verticalCenter
            source: backend.asset("assets/nav/" + root.icon + ".png")
            opacity: root.active ? 1.0 : 0.62
            scale: root.active ? 1.06 : 1
            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.active ? "#ffffff" : Qt.rgba(1, 1, 1, 0.68)
            font.family: "Inter"
            font.pixelSize: 14
            font.weight: Font.Medium
            font.letterSpacing: 0.1
            Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
