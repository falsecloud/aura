import QtQuick
import "fmt.js" as Fmt

Item {
    id: view

    property var d: backend.data
    property var cur: d && d.current ? d.current : ({})
    property var today: d && d.today ? d.today : ({})
    readonly property string units: backend.units

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
                    text: "WEATHER DETAILS"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }
                Text {
                    text: "Everything in the air right now"
                    color: Qt.rgba(1, 1, 1, 0.9)
                    font.family: "Inter Display"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.letterSpacing: -0.3
                }
            }

            Panel {
                width: parent.width
                height: 156

                Row {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 18

                    Column {
                        width: parent.width - 130
                        spacing: 4

                        Text {
                            text: "WIND"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }

                        Item {
                            width: parent.width
                            height: 48

                            Text {
                                id: windValue
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                text: Fmt.speed(view.cur.wind, view.units)
                                color: "#ffffff"
                                font.family: "Inter Display"
                                font.pixelSize: 42
                                font.weight: Font.Light
                                font.letterSpacing: -1.4
                            }
                            Text {
                                anchors.left: windValue.right
                                anchors.leftMargin: 8
                                anchors.bottom: windValue.bottom
                                anchors.bottomMargin: 9
                                text: Fmt.speedUnit(view.units)
                                color: Qt.rgba(1, 1, 1, 0.55)
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                        }

                        Text {
                            text: "From " + Fmt.compass(view.cur.windDir) + "  ·  gusts " +
                                  Fmt.speed(view.cur.gust, view.units) + " " + Fmt.speedUnit(view.units)
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font.family: "Inter"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Item {
                        width: 108
                        height: 108
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.16)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 5
                            text: "N"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 5
                            text: "S"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            text: "E"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            text: "W"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }

                        Item {
                            width: 2
                            height: parent.height * 0.6
                            anchors.centerIn: parent
                            rotation: (view.cur.windDir || 0) + 180
                            Behavior on rotation { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

                            Rectangle {
                                width: 2
                                height: parent.height / 2
                                radius: 1
                                color: "#ffd166"
                                anchors.top: parent.top
                            }
                            Rectangle {
                                width: 2
                                height: parent.height / 2
                                radius: 1
                                color: Qt.rgba(1, 1, 1, 0.25)
                                anchors.bottom: parent.bottom
                            }
                            Rectangle {
                                width: 9
                                height: 9
                                radius: 4.5
                                color: "#ffffff"
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 14
                rowSpacing: 14

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Feels like"
                    value: Fmt.temp(view.cur.feels, view.units) + "°"
                    sub: "High " + Fmt.temp(view.today.max, view.units) + "° · Low " + Fmt.temp(view.today.min, view.units) + "°"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Dew point"
                    value: Fmt.temp(view.cur.dew, view.units) + "°"
                    sub: (view.cur.dew !== undefined && view.cur.dew >= 18) ? "Muggy air" : "Comfortable air"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Humidity"
                    value: (view.cur.humidity !== undefined ? view.cur.humidity : "--") + "%"
                    sub: "Relative humidity"
                    barValue: (view.cur.humidity || 0) / 100
                    accent: "#7fd7e8"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Cloud cover"
                    value: (view.cur.cloud !== undefined ? view.cur.cloud : "--") + "%"
                    sub: view.cur.cloud > 70 ? "Mostly covered" : (view.cur.cloud > 30 ? "Partly covered" : "Mostly clear")
                    barValue: (view.cur.cloud || 0) / 100
                    accent: "#c9d7ea"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Visibility"
                    value: Fmt.visibility(view.cur.visibility, view.units) + " " + Fmt.visibilityUnit(view.units)
                    sub: "Horizontal range"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Pressure"
                    value: Fmt.pressure(view.cur.pressure, view.units) + " " + Fmt.pressureUnit(view.units)
                    sub: "Mean sea level"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "UV index"
                    value: (view.cur.uv !== undefined ? Math.round(view.cur.uv) : "--")
                    sub: Fmt.uvLabel(view.cur.uv) + " · max " + Math.round(view.today.uvMax || 0)
                    barValue: Math.min(1, (view.cur.uv || 0) / 11)
                    accent: Fmt.uvColor(view.cur.uv || 0)
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Rain today"
                    value: (view.today.precipProb || 0) + "%"
                    sub: Fmt.precip(view.today.precipSum, view.units) + " " + Fmt.precipUnit(view.units) + " expected"
                    barValue: (view.today.precipProb || 0) / 100
                    accent: "#8fd3ff"
                }
            }

            Panel {
                width: parent.width
                height: 158

                Column {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 9

                    Row {
                        width: parent.width
                        spacing: 8
                        Text {
                            text: "AIR QUALITY"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            anchors.verticalCenter: parent.verticalCenter
                            color: Fmt.aqiColor(view.cur.aqi)
                        }
                    }

                    Item {
                        width: parent.width
                        height: 44

                        Text {
                            id: aqiValue
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            text: (view.cur.aqi !== null && view.cur.aqi !== undefined) ? view.cur.aqi : "—"
                            color: "#ffffff"
                            font.family: "Inter Display"
                            font.pixelSize: 38
                            font.weight: Font.Light
                            font.letterSpacing: -1.2
                        }

                        Column {
                            anchors.left: aqiValue.right
                            anchors.leftMargin: 12
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3
                            Text {
                                text: Fmt.aqiLabel(view.cur.aqi)
                                color: Fmt.aqiColor(view.cur.aqi)
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "European AQI"
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.family: "Inter"
                                font.pixelSize: 10
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 5
                        radius: 2.5
                        color: Qt.rgba(1, 1, 1, 0.1)
                        Rectangle {
                            width: Math.max(4, parent.width * Fmt.aqiPercent(view.cur.aqi) / 100)
                            height: parent.height
                            radius: 2.5
                            color: Fmt.aqiColor(view.cur.aqi)
                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 18

                        Repeater {
                            model: [
                                { label: "PM2.5", value: view.cur.pm25 },
                                { label: "PM10", value: view.cur.pm10 },
                                { label: "O₃", value: view.cur.ozone },
                                { label: "NO₂", value: view.cur.no2 }
                            ]

                            Column {
                                width: (parent.width - 54) / 4
                                spacing: 1
                                Text {
                                    text: modelData.label
                                    color: Qt.rgba(1, 1, 1, 0.4)
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: modelData.value !== null && modelData.value !== undefined
                                        ? Math.round(modelData.value) + " µg/m³" : "—"
                                    color: Qt.rgba(1, 1, 1, 0.78)
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }
                    }
                }
            }

            Panel {
                width: parent.width
                height: 116

                Row {
                    anchors.fill: parent
                    anchors.margins: 17

                    Column {
                        width: parent.width / 2
                        spacing: 2
                        Text {
                            text: "SUNRISE"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }
                        Text {
                            text: Fmt.clock(view.today.sunrise)
                            color: "#ffffff"
                            font.family: "Inter Display"
                            font.pixelSize: 25
                            font.weight: Font.Light
                        }
                    }

                    Column {
                        width: parent.width / 2
                        spacing: 2
                        Text {
                            text: "SUNSET"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: "Inter"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1
                        }
                        Text {
                            text: Fmt.clock(view.today.sunset)
                            color: "#ffffff"
                            font.family: "Inter Display"
                            font.pixelSize: 25
                            font.weight: Font.Light
                        }
                    }
                }
            }
        }
    }
}
