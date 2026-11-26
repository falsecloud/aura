import QtQuick

Item {
    id: root

    property string kind: "cloudy"
    property real size: 48
    property bool front: true
    property bool ready: false

    implicitWidth: size
    implicitHeight: size

    function iconSource(k) {
        return backend.asset("assets/icons/weather/" + k + ".png")
    }

    Image {
        id: iconA
        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: false
        opacity: root.front ? 1 : 0
        scale: root.front ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
    }

    Image {
        id: iconB
        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: false
        opacity: root.front ? 0 : 1
        scale: root.front ? 0.9 : 1
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
    }

    Component.onCompleted: {
        iconA.source = iconSource(root.kind)
        root.front = true
        root.ready = true
    }

    onKindChanged: {
        if (!root.ready)
            return
        if (root.front)
            iconB.source = iconSource(root.kind)
        else
            iconA.source = iconSource(root.kind)
        root.front = !root.front
    }
}
