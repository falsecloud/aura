import QtQuick
import "fmt.js" as Fmt

Item {
    id: view

    property var d: backend.data
    property var days: d && d.daily ? d.daily : []
    readonly property string units: backend.units
    property int expanded: -1

    property real globalMin: {
        if (!days.length) return 0
        var m = days[0].min
        for (var i = 1; i < days.length; i++) if (days[i].min < m) m = days[i].min
        return m
    }
    property real globalMax: {
        if (!days.length) return 1
        var m = days[0].max
        for (var i = 1; i < days.length; i++) if (days[i].max > m) m = days[i].max
        return m
    }
    property real globalSpan: Math.max(1, globalMax - globalMin)

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
                    text: "10-DAY FORECAST"
                    color: Qt.rgba(1, 1, 1, 0.5)
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.1
                }
                Text {
                    text: "Plan the week ahead"
                    color: Qt.rgba(1, 1, 1, 0.9)
                    font.family: "Inter Display"
                    font.pixelSize: 21
                    font.weight: Font.Normal
                    font.letterSpacing: -0.3
                }
            }

            Panel {
                width: parent.width
                height: list.implicitHeight + 28
                Behavior on height { NumberAnimation { duration: 340; easing.type: Easing.OutQuint } }

                Column {
                    id: list
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 14

                    Repeater {
                        model: view.days

                        Item {
                            id: rowItem
                            width: list.width
                            height: view.expanded === index ? 148 : 58

                            Behavior on height { NumberAnimation { duration: 340; easing.type: Easing.OutQuint } }

                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: view.expanded === index
                                    ? Qt.rgba(1, 1, 1, 0.07)
                                    : (dayArea.containsMouse ? Qt.rgba(1, 1, 1, 0.045) : Qt.rgba(1, 1, 1, 0))
                                Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            }

                            Item {
                                id: mainRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                height: 58

                                Text {
                                    id: dayText
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 72
                                    text: Fmt.relativeDay(modelData.date, index)
                                    color: "#ffffff"
                                    font.family: "Inter"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 76
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 44
                                    text: Fmt.dateLabel(modelData.date)
                                    color: Qt.rgba(1, 1, 1, 0.42)
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                }

                                WeatherIcon {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 124
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 28
                                    kind: modelData.icon
                                }

                                Text {
                                    id: precipText
                                    anchors.left: parent.left
                                    anchors.leftMargin: 158
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 38
                                    text: modelData.precipProb > 0 ? modelData.precipProb + "%" : ""
                                    color: "#8fd3ff"
                                    font.family: "Inter"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }

                                Item {
                                    id: barArea
                                    anchors.left: parent.left
                                    anchors.leftMargin: 202
                                    anchors.right: tempText.left
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 6

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 5
                                        radius: 2.5
                                        color: Qt.rgba(1, 1, 1, 0.1)
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 5
                                        radius: 2.5
                                        x: Math.max(0, (modelData.min - view.globalMin) / view.globalSpan * barArea.width)
                                        width: Math.max(
                                            8,
                                            ((modelData.max - modelData.min) / view.globalSpan) * barArea.width
                                        )
                                        Behavior on x { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                                        Behavior on width { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "#7cc4ff" }
                                            GradientStop { position: 1.0; color: "#ffd166" }
                                        }
                                    }
                                }

                                Row {
                                    id: tempText
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 7

                                    Text {
                                        width: 34
                                        horizontalAlignment: Text.AlignRight
                                        text: Fmt.temp(modelData.min, view.units) + "°"
                                        color: Qt.rgba(1, 1, 1, 0.5)
                                        font.family: "Inter Display"
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        width: 36
                                        horizontalAlignment: Text.AlignRight
                                        text: Fmt.temp(modelData.max, view.units) + "°"
                                        color: "#ffffff"
                                        font.family: "Inter Display"
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: dayArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: view.expanded = view.expanded === index ? -1 : index
                                }
                            }

                            Item {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: mainRow.bottom
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                height: 84
                                opacity: view.expanded === index ? 1 : 0
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                                Row {
                                    anchors.fill: parent
                                    anchors.topMargin: 4
                                    spacing: 22

                                    Column {
                                        width: (parent.width - 66) / 4
                                        spacing: 3
                                        Text {
                                            text: "WIND"
                                            color: Qt.rgba(1, 1, 1, 0.4)
                                            font.family: "Inter"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.8
                                        }
                                        Text {
                                            text: Fmt.speed(modelData.windMax, view.units) + " " + Fmt.speedUnit(view.units)
                                            color: "#ffffff"
                                            font.family: "Inter Display"
                                            font.pixelSize: 14
                                        }
                                        Text {
                                            text: Fmt.compass(modelData.windDir)
                                            color: Qt.rgba(1, 1, 1, 0.45)
                                            font.family: "Inter"
                                            font.pixelSize: 10
                                        }
                                    }

                                    Column {
                                        width: (parent.width - 66) / 4
                                        spacing: 3
                                        Text {
                                            text: "SUNRISE"
                                            color: Qt.rgba(1, 1, 1, 0.4)
                                            font.family: "Inter"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.8
                                        }
                                        Text {
                                            text: Fmt.clock(modelData.sunrise)
                                            color: "#ffffff"
                                            font.family: "Inter Display"
                                            font.pixelSize: 14
                                        }
                                    }

                                    Column {
                                        width: (parent.width - 66) / 4
                                        spacing: 3
                                        Text {
                                            text: "SUNSET"
                                            color: Qt.rgba(1, 1, 1, 0.4)
                                            font.family: "Inter"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.8
                                        }
                                        Text {
                                            text: Fmt.clock(modelData.sunset)
                                            color: "#ffffff"
                                            font.family: "Inter Display"
                                            font.pixelSize: 14
                                        }
                                    }

                                    Column {
                                        width: (parent.width - 66) / 4
                                        spacing: 3
                                        Text {
                                            text: "UV / RAIN"
                                            color: Qt.rgba(1, 1, 1, 0.4)
                                            font.family: "Inter"
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 0.8
                                        }
                                        Text {
                                            text: Math.round(modelData.uvMax) + "  ·  " + Fmt.precip(modelData.precipSum, view.units) + " " + Fmt.precipUnit(view.units)
                                            color: "#ffffff"
                                            font.family: "Inter Display"
                                            font.pixelSize: 14
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: "Tap a day for wind, sun and UV details."
                color: Qt.rgba(1, 1, 1, 0.35)
                font.family: "Inter"
                font.pixelSize: 11
            }
        }
    }
}
