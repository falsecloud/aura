import QtQuick
import "fmt.js" as Fmt

Item {
    id: view

    property var d: backend.data
    property var cur: d && d.current ? d.current : ({})
    property var place: d && d.place ? d.place : ({})
    readonly property string units: backend.units
    property var saved: backend.savedPlaces

    signal requestSearch()

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.height + 34
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: parent.width
            spacing: 16

            Column {
                spacing: 2
                Text {
                    text: "PLACES"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }
                Text {
                    text: "Your skies around the world"
                    color: Qt.rgba(1, 1, 1, 0.9)
                    font.family: "Inter Display"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.letterSpacing: -0.3
                }
            }

            Panel {
                width: parent.width
                height: 196

                Item {
                    anchors.fill: parent
                    anchors.margins: 18

                    Column {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        spacing: 2

                        Row {
                            spacing: 7
                            Image {
                                width: 13
                                height: 13
                                anchors.verticalCenter: parent.verticalCenter
                                source: backend.asset("assets/nav/locate.png")
                                opacity: 0.7
                            }
                            Text {
                                text: "CURRENT LOCATION"
                                color: Qt.rgba(1, 1, 1, 0.5)
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.1
                            }
                        }

                        Text {
                            text: view.place.name ? view.place.name : "Locating…"
                            color: "#ffffff"
                            font.family: "Inter Display"
                            font.pixelSize: 27
                            font.weight: Font.Medium
                            font.letterSpacing: -0.6
                        }

                        Text {
                            text: [view.place.region, view.place.country].filter(function (v) { return !!v }).join(" · ")
                            color: Qt.rgba(1, 1, 1, 0.48)
                            font.family: "Inter"
                            font.pixelSize: 12
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 8

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: Qt.rgba(1, 1, 1, saveArea.containsMouse ? 0.18 : 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.2)
                            scale: saveArea.pressed ? 0.9 : saveArea.containsMouse ? 1.06 : 1
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                            Image {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                source: backend.asset(backend.currentSaved ? "assets/nav/star-fill.png" : "assets/nav/star.png")
                                opacity: 0.9
                            }

                            MouseArea {
                                id: saveArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.toggleCurrentPlace()
                            }
                        }

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: Qt.rgba(1, 1, 1, locateArea.containsMouse ? 0.18 : 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.2)
                            scale: locateArea.pressed ? 0.9 : locateArea.containsMouse ? 1.06 : 1
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                            Image {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                source: backend.asset("assets/nav/locate.png")
                                opacity: 0.9
                            }

                            MouseArea {
                                id: locateArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.useMyLocation()
                            }
                        }
                    }

                    Item {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        width: parent.width - 90
                        height: 56

                        Text {
                            id: placeTemp
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            text: Fmt.temp(view.cur.temp, view.units) + "°"
                            color: "#ffffff"
                            font.family: "Inter Display"
                            font.pixelSize: 52
                            font.weight: Font.Light
                            font.letterSpacing: -2
                        }

                        Column {
                            anchors.left: placeTemp.right
                            anchors.leftMargin: 14
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 7
                            spacing: 1
                            Text {
                                text: view.d && view.d.condition ? view.d.condition : "—"
                                color: Qt.rgba(1, 1, 1, 0.8)
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            Text {
                                text: "H " + Fmt.temp(view.d && view.d.today ? view.d.today.max : 0, view.units) + "°  L " +
                                      Fmt.temp(view.d && view.d.today ? view.d.today.min : 0, view.units) + "°"
                                color: Qt.rgba(1, 1, 1, 0.45)
                                font.family: "Inter"
                                font.pixelSize: 11
                            }
                        }
                    }

                    WeatherIcon {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        size: 72
                        kind: view.d && view.d.icon ? view.d.icon : "cloudy"
                    }
                }
            }

            Row {
                width: parent.width

                Text {
                    text: "SAVED PLACES"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }
            }

            Panel {
                width: parent.width
                height: Math.max(88, savedList.implicitHeight + 20)
                Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutQuint } }

                Column {
                    id: savedList
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 10

                    Repeater {
                        model: view.saved

                        Item {
                            width: savedList.width
                            height: 62
                            scale: selectArea.pressed ? 0.99 : 1
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: selectArea.containsMouse || modelData.name === view.place.name
                                    ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0)
                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 170
                                text: modelData.name
                                color: "#ffffff"
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 10
                                width: parent.width - 170
                                text: [modelData.region, modelData.country].filter(function (v) { return !!v }).join(" · ")
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.family: "Inter"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            WeatherIcon {
                                anchors.right: tempLabel.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                size: 26
                                kind: modelData.code !== null && modelData.code !== undefined
                                    ? Fmt.weatherIcon(modelData.code, modelData.isDay) : "cloudy"
                            }

                            Text {
                                id: tempLabel
                                anchors.right: removeButton.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                horizontalAlignment: Text.AlignRight
                                text: modelData.temp !== null && modelData.temp !== undefined
                                    ? Fmt.temp(modelData.temp, view.units) + "°" : "—"
                                color: "#ffffff"
                                font.family: "Inter Display"
                                font.pixelSize: 17
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: selectArea
                                anchors.fill: parent
                                anchors.rightMargin: 46
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.selectPlace(index)
                            }

                            Item {
                                id: removeButton
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                height: 34
                                scale: removeArea.pressed ? 0.85 : removeArea.containsMouse ? 1.08 : 1
                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: backend.asset("assets/nav/close.png")
                                    opacity: removeArea.containsMouse ? 0.95 : 0.42
                                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    id: removeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.removePlace(index)
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Qt.rgba(1, 1, 1, 0.06)
                                visible: index < view.saved.length - 1
                            }
                        }
                    }

                    Item {
                        width: savedList.width
                        height: view.saved.length ? 0 : 58

                        Text {
                            anchors.centerIn: parent
                            text: "No saved places yet"
                            color: Qt.rgba(1, 1, 1, 0.42)
                            font.family: "Inter"
                            font.pixelSize: 12
                            visible: view.saved.length === 0
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 50
                radius: 16
                scale: addArea.pressed ? 0.985 : 1
                color: addArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.16)
                Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Image {
                        width: 14
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter
                        source: backend.asset("assets/nav/plus.png")
                        opacity: 0.75
                    }
                    Text {
                        text: "Add a place"
                        color: Qt.rgba(1, 1, 1, 0.85)
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                }

                MouseArea {
                    id: addArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: view.requestSearch()
                }
            }
        }
    }
}
