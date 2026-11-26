import QtQuick
import "fmt.js" as Fmt

Item {
    id: view

    property var d: backend.data
    property var hours: d && d.hourly ? d.hourly : []
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

            Row {
                width: parent.width

                Column {
                    spacing: 2
                    Text {
                        text: "HOURLY FORECAST"
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.1
                    }
                    Text {
                        text: "The next 24 hours, hour by hour"
                        color: Qt.rgba(1, 1, 1, 0.9)
                        font.family: "Inter Display"
                        font.pixelSize: 21
                        font.weight: Font.Normal
                        font.letterSpacing: -0.3
                    }
                }
            }

            Panel {
                width: parent.width
                height: 288

                Canvas {
                    id: chart
                    anchors.fill: parent
                    anchors.margins: 14

                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    Connections {
                        target: backend
                        function onDataChanged() { chart.requestPaint() }
                        function onUnitsChanged() { chart.requestPaint() }
                    }

                    onPaint: {
                        var ctx = getContext("2d")
                        var items = view.hours
                        ctx.clearRect(0, 0, width, height)
                        if (!items || items.length < 2) return

                        var n = items.length
                        var left = 8
                        var right = 8
                        var top = 30
                        var bottom = 42
                        var innerW = width - left - right
                        var innerH = height - top - bottom

                        var temps = []
                        var lo = 999
                        var hi = -999
                        for (var i = 0; i < n; i++) {
                            var t = items[i].temp
                            temps.push(t)
                            if (t < lo) lo = t
                            if (t > hi) hi = t
                        }
                        if (hi - lo < 4) {
                            var mid = (hi + lo) / 2
                            lo = mid - 2
                            hi = mid + 2
                        }
                        var span = hi - lo

                        function px(i) { return left + innerW * i / (n - 1) }
                        function py(v) { return top + innerH * (hi - v) / span }

                        // precipitation bars
                        for (var b = 0; b < n; b++) {
                            var prob = items[b].precipProb || 0
                            if (prob > 0) {
                                var bh = Math.max(2, (prob / 100) * 18)
                                ctx.fillStyle = "rgba(143, 211, 255, 0.22)"
                                ctx.fillRect(px(b) - 7, height - bottom + 6, 14, bh)
                            }
                        }

                        function drawPath() {
                            ctx.beginPath()
                            ctx.moveTo(px(0), py(temps[0]))
                            for (var k = 1; k < n; k++) {
                                var xc = (px(k - 1) + px(k)) / 2
                                ctx.bezierCurveTo(xc, py(temps[k - 1]), xc, py(temps[k]), px(k), py(temps[k]))
                            }
                        }

                        drawPath()
                        ctx.lineTo(px(n - 1), height - bottom)
                        ctx.lineTo(px(0), height - bottom)
                        ctx.closePath()
                        var grad = ctx.createLinearGradient(0, top, 0, height - bottom)
                        grad.addColorStop(0, "rgba(143, 211, 255, 0.30)")
                        grad.addColorStop(1, "rgba(143, 211, 255, 0.00)")
                        ctx.fillStyle = grad
                        ctx.fill()

                        drawPath()
                        ctx.strokeStyle = "rgba(230, 246, 255, 0.82)"
                        ctx.lineWidth = 2
                        ctx.lineJoin = "round"
                        ctx.stroke()

                        // points + values
                        ctx.textAlign = "center"
                        for (var p = 0; p < n; p += 3) {
                            ctx.beginPath()
                            ctx.arc(px(p), py(temps[p]), 2.4, 0, Math.PI * 2)
                            ctx.fillStyle = "rgba(255, 255, 255, 0.9)"
                            ctx.fill()

                            ctx.fillStyle = "rgba(255, 255, 255, 0.92)"
                            ctx.font = "600 11px Inter"
                            ctx.fillText(
                                Fmt.temp(temps[p], view.units) + "°",
                                px(p),
                                py(temps[p]) - 12
                            )
                        }

                        // hour labels
                        ctx.fillStyle = "rgba(255, 255, 255, 0.46)"
                        ctx.font = "500 10px Inter"
                        for (var h = 0; h < n; h += 3) {
                            ctx.fillText(Fmt.hourLabel(items[h].time), px(h), height - 8)
                        }
                    }
                }
            }

            Panel {
                width: parent.width
                height: rows.implicitHeight + 26

                Column {
                    id: rows
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.topMargin: 13

                    Repeater {
                        model: view.hours

                        Item {
                            width: rows.width
                            height: 52

                            Text {
                                id: hourText
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 54
                                text: index === 0 ? "Now" : Fmt.hourLabel(modelData.time)
                                color: index === 0 ? "#ffffff" : Qt.rgba(1, 1, 1, 0.6)
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: index === 0 ? Font.DemiBold : Font.Medium
                            }

                            WeatherIcon {
                                anchors.left: parent.left
                                anchors.leftMargin: 60
                                anchors.verticalCenter: parent.verticalCenter
                                size: 27
                                kind: modelData.icon
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 96
                                anchors.right: precipText.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.condition
                                color: Qt.rgba(1, 1, 1, 0.5)
                                font.family: "Inter"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            Text {
                                id: precipText
                                anchors.right: tempText.left
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 42
                                horizontalAlignment: Text.AlignRight
                                text: modelData.precipProb > 0 ? modelData.precipProb + "%" : ""
                                color: "#8fd3ff"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }

                            Text {
                                id: tempText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 48
                                horizontalAlignment: Text.AlignRight
                                text: Fmt.temp(modelData.temp, view.units) + "°"
                                color: "#ffffff"
                                font.family: "Inter Display"
                                font.pixelSize: 17
                                font.weight: Font.Medium
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Qt.rgba(1, 1, 1, 0.06)
                                visible: index < view.hours.length - 1
                            }
                        }
                    }
                }
            }
        }
    }
}
