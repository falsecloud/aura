import QtQuick

Row {
    id: root

    spacing: 8
    signal closeClicked()
    signal minimizeClicked()
    signal maximizeClicked()

    Repeater {
        model: [
            { tone: "#ff5f57", glyph: "×", action: 0 },
            { tone: "#febc2e", glyph: "–", action: 1 },
            { tone: "#28c840", glyph: "+", action: 2 }
        ]

        Item {
            width: 13
            height: 13
            scale: area.pressed ? 0.88 : area.containsMouse ? 1.16 : 1
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
            Rectangle {
                anchors.fill: parent
                radius: 6.5
                color: modelData.tone
                border.width: 0.5
                border.color: Qt.rgba(0, 0, 0, 0.22)
                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    color: Qt.rgba(0, 0, 0, 0.55)
                    font.pixelSize: 10
                    font.bold: true
                    opacity: area.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (modelData.action === 0) root.closeClicked()
                    else if (modelData.action === 1) root.minimizeClicked()
                    else root.maximizeClicked()
                }
            }
        }
    }
}
