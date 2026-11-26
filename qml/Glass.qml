import QtQuick

Item {
    id: root

    default property alias content: contentArea.data
    property var refractionSource: null
    property real radius: 28
    property real edgeWidth: 36
    property real refraction: 26
    property real dispersion: 2.2
    property real ambientDim: 0.0
    property real blurRadius: 2.4
    property color glassTint: Qt.rgba(0.82, 0.90, 1.0, 0.10)
    property bool hoverGlow: true

    property Item winItem: Window.window ? Window.window.contentItem : null
    property point origin: Qt.point(0, 0)
    property bool hovered: false
    property real sheenX: -999
    property real sheenY: -999
    property real clock: 0

    function updateOrigin() {
        if (winItem) {
            var p = mapToItem(winItem, 0, 0)
            origin = Qt.point(p.x, p.y)
        }
    }

    Component.onCompleted: updateOrigin()
    onXChanged: updateOrigin()
    onYChanged: updateOrigin()
    onWidthChanged: updateOrigin()
    onHeightChanged: updateOrigin()
    onParentChanged: updateOrigin()

    Connections {
        target: root.winItem
        function onWidthChanged() { root.updateOrigin() }
        function onHeightChanged() { root.updateOrigin() }
    }

    Rectangle {
        x: -12
        y: 8
        width: root.width + 24
        height: root.height + 20
        radius: root.radius + 12
        color: Qt.rgba(0, 0, 0, 0.16)
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        clip: true
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: Qt.rgba(1, 1, 1, 0.035)
        }

        ShaderEffect {
            id: glassShader
            anchors.fill: parent
            visible: root.refractionSource !== null
            fragmentShader: "shaders/glass.frag.qsb"

            property variant source: root.refractionSource
            property real itemW: root.width
            property real itemH: root.height
            property real winW: root.winItem ? root.winItem.width : 1
            property real winH: root.winItem ? root.winItem.height : 1
            property real originX: root.origin.x
            property real originY: root.origin.y
            property real radius: root.radius
            property real edgeWidth: root.edgeWidth
            property real refraction: root.refraction
            property real dispersion: root.dispersion
            property real ambientDim: root.ambientDim
            property real blurRadius: root.blurRadius
            property real pointerX: root.sheenX
            property real pointerY: root.sheenY
            property real hover: root.hovered ? 1.0 : 0.0
            property real clock: root.clock
            property color tint: root.glassTint
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, root.hovered ? 0.26 : 0.13)
            Behavior on border.color { ColorAnimation { duration: 260 } }
        }

        Item {
            id: contentArea
            anchors.fill: parent
        }
    }

    HoverHandler {
        id: hover
        onPointChanged: {
            root.sheenX = hover.point.position.x
            root.sheenY = hover.point.position.y
        }
        onHoveredChanged: root.hovered = hovered
    }

    Timer {
        interval: 40
        repeat: true
        running: true
        onTriggered: root.clock += 0.04
    }
}
