import QtQuick
import "fmt.js" as Fmt

Item {
    id: view

    property var d: backend.data
    property var cur: d && d.current ? d.current : ({})
    property var today: d && d.today ? d.today : ({})
    property var place: d && d.place ? d.place : ({})
    property var hours: d && d.hourly ? d.hourly.slice(0, 12) : []
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

            Item {
                width: parent.width
                height: 224

                Column {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.topMargin: 6
                    spacing: 1

                    Text {
                        text: view.cur.time ? Fmt.clock(view.cur.time) + "  ·  " + (view.cur.isDay ? "Daytime" : "Night") : "Right now"
                        color: Qt.rgba(1, 1, 1, 0.56)
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        font.letterSpacing: 0.8
                    }

                    Item {
                        width: tempText.implicitWidth + 26
                        height: tempText.implicitHeight

                        Text {
                            id: tempText
                            text: Fmt.temp(view.cur.temp, view.units)
                            color: "#ffffff"
                            font.family: "Inter Display"
                            font.pixelSize: 120
                            font.weight: Font.Light
                            font.letterSpacing: -7
                            lineHeight: 0.95
                        }

                        Text {
                            text: "°"
                            x: tempText.implicitWidth - 16
                            y: 12
                            color: Qt.rgba(1, 1, 1, 0.82)
                            font.family: "Inter Display"
                            font.pixelSize: 52
                            font.weight: Font.Light
                        }
                    }

                    Text {
                        text: view.d && view.d.condition ? view.d.condition : "Loading weather"
                        color: Qt.rgba(1, 1, 1, 0.92)
                        font.family: "Inter Display"
                        font.pixelSize: 23
                        font.weight: Font.Normal
                        font.letterSpacing: -0.4
                    }

                    Row {
                        spacing: 14

                        Text {
                            text: "H " + Fmt.temp(view.today.max, view.units) + "°"
                            color: Qt.rgba(1, 1, 1, 0.62)
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: "L " + Fmt.temp(view.today.min, view.units) + "°"
                            color: Qt.rgba(1, 1, 1, 0.62)
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: "Feels " + Fmt.temp(view.cur.feels, view.units) + "°"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: "Inter"
                            font.pixelSize: 14
                        }
                    }
                }

                WeatherIcon {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    anchors.rightMargin: 4
                    size: Math.min(196, view.width * 0.33)
                    kind: view.d && view.d.icon ? view.d.icon : "cloudy"
                }
            }

            Panel {
                width: parent.width
                height: 146

                Column {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 8

                    Text {
                        text: "NEXT 12 HOURS"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                    }

                    Flickable {
                        width: parent.width
                        height: 96
                        contentWidth: hourRow.width
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentWidth > width

                        Row {
                            id: hourRow
                            spacing: 2

                            Repeater {
                                model: view.hours

                                Item {
                                    width: 57
                                    height: 96

                                    Column {
                                        anchors.fill: parent
                                        spacing: 2

                                        Text {
                                            width: parent.width
                                            text: index === 0 ? "Now" : Fmt.hourLabel(modelData.time)
                                            color: index === 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.55)
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            font.weight: index === 0 ? Font.DemiBold : Font.Medium
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        WeatherIcon {
                                            width: parent.width
                                            height: 34
                                            size: 34
                                            kind: modelData.icon
                                        }

                                        Text {
                                            width: parent.width
                                            text: Fmt.temp(modelData.temp, view.units) + "°"
                                            color: "#ffffff"
                                            font.family: "Inter Display"
                                            font.pixelSize: 16
                                            font.weight: Font.Medium
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.precipProb > 0 ? modelData.precipProb + "%" : ""
                                            color: "#8fd3ff"
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                            horizontalAlignment: Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: "TODAY'S HIGHLIGHTS"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Grid {
                width: parent.width
                columns: 2
                columnSpacing: 14
                rowSpacing: 14

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Wind"
                    value: Fmt.speed(view.cur.wind, view.units) + " " + Fmt.speedUnit(view.units)
                    sub: Fmt.compass(view.cur.windDir) + "  ·  gusts " + Fmt.speed(view.cur.gust, view.units)
                    barValue: Math.min(1, (view.cur.wind || 0) / 50)
                    accent: "#8fd3ff"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Humidity"
                    value: (view.cur.humidity !== undefined ? view.cur.humidity : "--") + "%"
                    sub: "Dew point " + Fmt.temp(view.cur.dew, view.units) + "°"
                    barValue: (view.cur.humidity || 0) / 100
                    accent: "#7fd7e8"
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "UV index"
                    value: (view.cur.uv !== undefined ? Math.round(view.cur.uv) : "--")
                    sub: Fmt.uvLabel(view.cur.uv) + "  ·  max " + Math.round(view.today.uvMax || 0)
                    barValue: Math.min(1, (view.cur.uv || 0) / 11)
                    accent: Fmt.uvColor(view.cur.uv || 0)
                }

                DetailTile {
                    width: (parent.width - 14) / 2
                    label: "Air quality"
                    value: (view.cur.aqi !== null && view.cur.aqi !== undefined) ? view.cur.aqi : "—"
                    sub: Fmt.aqiLabel(view.cur.aqi)
                    barValue: Fmt.aqiPercent(view.cur.aqi) / 100
                    accent: Fmt.aqiColor(view.cur.aqi)
                }
            }

            Panel {
                width: parent.width
                height: 132

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Row {
                        width: parent.width
                        Text {
                            text: "SUN"
                            color: Qt.rgba(1, 1, 1, 0.5)
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.1
                        }
                    }

                    Item {
                        width: parent.width
                        height: 44

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 2
                            radius: 1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.rgba(0.55, 0.75, 1, 0.22) }
                                GradientStop { position: 0.5; color: Qt.rgba(1, 0.85, 0.45, 0.9) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 0.55, 0.35, 0.22) }
                            }
                        }

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: "#ffd166"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                radius: 14
                                color: Qt.rgba(1, 0.82, 0.4, 0.18)
                            }
                        }
                    }

                    Row {
                        width: parent.width

                        Column {
                            width: parent.width / 2
                            Text {
                                text: "Sunrise"
                                color: Qt.rgba(1, 1, 1, 0.48)
                                font.family: "Inter"
                                font.pixelSize: 11
                            }
                            Text {
                                text: Fmt.clock(view.today.sunrise)
                                color: "#ffffff"
                                font.family: "Inter Display"
                                font.pixelSize: 19
                                font.weight: Font.Medium
                            }
                        }

                        Column {
                            width: parent.width / 2
                            Text {
                                text: "Sunset"
                                color: Qt.rgba(1, 1, 1, 0.48)
                                font.family: "Inter"
                                font.pixelSize: 11
                            }
                            Text {
                                text: Fmt.clock(view.today.sunset)
                                color: "#ffffff"
                                font.family: "Inter Display"
                                font.pixelSize: 19
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }
        }
    }
}
