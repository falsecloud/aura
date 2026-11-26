import QtQuick

Item {
    id: root

    property bool opened: false
    property var backdrop: null
    property var refractionSource: null

    signal dismissed()

    anchors.fill: parent
    visible: opacity > 0
    opacity: opened ? 1 : 0
    z: 60

    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    function focusInput() {
        input.forceActiveFocus()
    }

    onOpenedChanged: {
        if (opened) {
            input.text = ""
            backend.clearSearch()
            focusInput()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.015, 0.03, 0.07, 0.46)

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Glass {
        id: card

        width: Math.min(540, root.width - 72)
        height: 472
        anchors.centerIn: parent
        radius: root.opened ? 28 : 22
        refractionSource: root.refractionSource
        edgeWidth: 30
        refraction: 24
        ambientDim: 0.30
        glassTint: Qt.rgba(0.82, 0.90, 1.0, 0.12)
        scale: root.opened ? 1 : 0.86

        Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.06 } }
        Behavior on radius { NumberAnimation { duration: 360; easing.type: Easing.OutQuint } }

        transform: Translate {
            y: root.opened ? 0 : 20
            Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.OutQuint } }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Item {
                width: parent.width
                height: 30

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search places"
                    color: "#ffffff"
                    font.family: "Inter Display"
                    font.pixelSize: 21
                    font.weight: Font.Medium
                    font.letterSpacing: -0.4
                }

                Item {
                    width: 28
                    height: 28
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    scale: closeArea.pressed ? 0.86 : closeArea.containsMouse ? 1.08 : 1
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                    Image {
                        anchors.centerIn: parent
                        width: 13
                        height: 13
                        source: backend.asset("assets/nav/close.png")
                        opacity: closeArea.containsMouse ? 0.95 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissed()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 50
                radius: 15
                color: Qt.rgba(1, 1, 1, 0.1)
                border.width: 1
                border.color: input.activeFocus ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(1, 1, 1, 0.18)
                Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Image {
                    x: 15
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    source: backend.asset("assets/nav/search.png")
                    opacity: 0.55
                }

                Text {
                    x: 41
                    anchors.verticalCenter: parent.verticalCenter
                    text: "City, region or airport"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font.family: "Inter"
                    font.pixelSize: 14
                    opacity: input.text.length === 0 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                TextInput {
                    id: input
                    anchors.left: parent.left
                    anchors.leftMargin: 41
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#ffffff"
                    font.family: "Inter"
                    font.pixelSize: 14
                    selectionColor: "#3d8fd6"
                    selectedTextColor: "#ffffff"
                    clip: true

                    onTextChanged: backend.search(text)
                    onAccepted: {
                        if (backend.searchResults.length > 0) {
                            backend.chooseSearchResult(0)
                            root.dismissed()
                        }
                    }

                    Keys.onEscapePressed: root.dismissed()
                }
            }

            Item {
                width: parent.width
                height: 330

                ListView {
                    id: results
                    anchors.fill: parent
                    clip: true
                    spacing: 2
                    model: backend.searchResults
                    boundsBehavior: Flickable.StopAtBounds

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 240; easing.type: Easing.OutCubic }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 240; easing.type: Easing.OutCubic }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
                    }

                    delegate: Item {
                        width: results.width
                        height: 60

                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            color: rowArea.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0)
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.name
                                color: "#ffffff"
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: [modelData.region, modelData.country].filter(function (v) { return !!v }).join(" · ")
                                color: Qt.rgba(1, 1, 1, 0.42)
                                font.family: "Inter"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                backend.chooseSearchResult(index)
                                root.dismissed()
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Type at least two letters"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font.family: "Inter"
                    font.pixelSize: 12
                    opacity: input.text.length < 2 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Searching…"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Inter"
                    font.pixelSize: 12
                    opacity: input.text.length >= 2 && backend.searching ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "No places found"
                    color: Qt.rgba(1, 1, 1, 0.35)
                    font.family: "Inter"
                    font.pixelSize: 12
                    opacity: input.text.length >= 2 && !backend.searching && backend.searchResults.length === 0 ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                width: parent.width
                text: "Press ↵ to choose the first result  ·  Esc to close"
                color: Qt.rgba(1, 1, 1, 0.3)
                font.family: "Inter"
                font.pixelSize: 10
            }
        }
    }
}
