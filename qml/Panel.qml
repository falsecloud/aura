import QtQuick

Rectangle {
    id: root

    default property alias content: inner.data
    property real alpha: 0.07
    property real borderAlpha: 0.13

    radius: 22
    color: Qt.rgba(1, 1, 1, alpha)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, borderAlpha)
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.055) }
            GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.045) }
        }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
