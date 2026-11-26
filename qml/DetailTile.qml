import QtQuick

Panel {
    id: root

    property string label: ""
    property string value: ""
    property string sub: ""
    property real barValue: -1
    property color accent: "#8fd3ff"

    implicitHeight: 112
    scale: tileHover.hovered ? 1.012 : 1
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    HoverHandler { id: tileHover }

    Column {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 3

        Text {
            width: parent.width
            text: root.label.toUpperCase()
            color: Qt.rgba(1, 1, 1, 0.5)
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 1.1
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.value
            color: "#ffffff"
            font.family: "Inter Display"
            font.pixelSize: 25
            font.weight: Font.Medium
            font.letterSpacing: -0.6
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.sub
            color: Qt.rgba(1, 1, 1, 0.55)
            font.family: "Inter"
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Item {
            width: parent.width
            height: 7

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 4
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.11)
                visible: root.barValue >= 0

                Rectangle {
                    height: parent.height
                    radius: 2
                    width: Math.max(4, parent.width * Math.min(1, Math.max(0, root.barValue)))
                    color: root.accent
                    Behavior on width { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
