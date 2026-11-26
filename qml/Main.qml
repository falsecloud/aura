import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtMultimedia

Window {
    id: win

    width: 1180
    height: 820
    minimumWidth: 840
    minimumHeight: 620
    visible: true
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "Aura"

    property int page: 0
    property bool searchOpen: false
    property string shotPath: ""
    property var d: backend.data
    readonly property var place: d && d.place ? d.place : ({})
    readonly property string videoKey: d && d.video ? d.video : ""
    readonly property string videoUrl: videoKey ? backend.asset("media/loop-" + videoKey + ".mp4") : ""
    readonly property string posterUrl: videoKey ? backend.asset("media/poster-" + videoKey + ".jpg") : ""
    readonly property color mood: {
        if (videoKey.indexOf("night") >= 0) return "#081026"
        if (videoKey === "storm") return "#070c20"
        if (videoKey === "snow" || videoKey === "fog") return "#3d516a"
        if (videoKey.indexOf("clear") >= 0) return "#144a7d"
        if (videoKey === "rain" || videoKey === "drizzle") return "#102f4c"
        return "#173a58"
    }

    AudioOutput {
        id: audio
        muted: true
    }

    MediaPlayer {
        id: player
        source: ""
        autoPlay: true
        loops: MediaPlayer.Infinite
        audioOutput: audio
        videoOutput: bgOutput

        onMediaStatusChanged: {
            if (mediaStatus === MediaPlayer.LoadedMedia ||
                mediaStatus === MediaPlayer.BufferedMedia ||
                mediaStatus === MediaPlayer.BufferingMedia) {
                veil.opacity = 0
            }
        }
        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState) veil.opacity = 0
        }
        onErrorOccurred: console.log("Aura video:", errorString)
    }

    onVideoUrlChanged: {
        if (videoUrl === "") return
        veil.opacity = 1
        veilTimer.restart()
        player.source = videoUrl
        player.play()
    }

    Timer {
        id: veilTimer
        interval: 1800
        repeat: false
        onTriggered: veil.opacity = 0
    }

    Shortcut {
        sequence: "Ctrl+K"
        onActivated: win.searchOpen = true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: win.searchOpen = false
    }

    Rectangle {
        id: rootClip
        anchors.fill: parent
        radius: 26
        clip: true
        color: "#0a1322"

        Item {
            id: backdrop
            anchors.fill: parent

            Item {
                id: sharpLayer
                anchors.fill: parent

                AnimatedImage {
                    anchors.fill: parent
                    source: win.videoKey ? backend.asset("media/sharp-" + win.videoKey + ".webp") : ""
                    fillMode: Image.PreserveAspectCrop
                    playing: player.playbackState === MediaPlayer.PlayingState
                    loops: AnimatedImage.Infinite
                    cache: false
                    smooth: true
                    layer.enabled: true
                    layer.smooth: true
                }

                // Match the live backdrop's grade so the glass refracts the
                // scene as it actually appears behind it, not a brighter copy.
                Rectangle {
                    anchors.fill: parent
                    color: win.mood
                    opacity: 0.1
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0.015, 0.03, 0.07, 0.30) }
                        GradientStop { position: 0.34; color: Qt.rgba(0.015, 0.03, 0.07, 0.04) }
                        GradientStop { position: 0.72; color: Qt.rgba(0.015, 0.03, 0.07, 0.06) }
                        GradientStop { position: 1.0; color: Qt.rgba(0.015, 0.03, 0.07, 0.48) }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(0.01, 0.02, 0.05, 0.34) }
                        GradientStop { position: 0.34; color: Qt.rgba(0.01, 0.02, 0.05, 0.0) }
                    }
                }

                Image {
                    x: -140
                    y: -180
                    width: 760
                    height: 760
                    source: backend.asset("assets/sheen.png")
                    opacity: 0.12
                }
            }

            ShaderEffectSource {
                id: sharpSource
                anchors.fill: parent
                sourceItem: sharpLayer
                live: true
                hideSource: false
                smooth: true
                mipmap: true
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2b6fa8" }
                    GradientStop { position: 0.55; color: "#14314e" }
                    GradientStop { position: 1.0; color: "#070f1c" }
                }
            }

            VideoOutput {
                id: bgOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
            }

            Image {
                anchors.fill: parent
                source: win.posterUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                opacity: player.playbackState === MediaPlayer.PlayingState ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 750; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                id: veil
                anchors.fill: parent
                color: "#081120"
                opacity: 0
                Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                anchors.fill: parent
                color: win.mood
                opacity: 0.1
                Behavior on color { ColorAnimation { duration: 900 } }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0.015, 0.03, 0.07, 0.30) }
                    GradientStop { position: 0.34; color: Qt.rgba(0.015, 0.03, 0.07, 0.04) }
                    GradientStop { position: 0.72; color: Qt.rgba(0.015, 0.03, 0.07, 0.06) }
                    GradientStop { position: 1.0; color: Qt.rgba(0.015, 0.03, 0.07, 0.48) }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(0.01, 0.02, 0.05, 0.34) }
                    GradientStop { position: 0.34; color: Qt.rgba(0.01, 0.02, 0.05, 0.0) }
                }
            }

            Image {
                x: -140
                y: -180
                width: 760
                height: 760
                source: backend.asset("assets/sheen.png")
                opacity: 0.12
            }
        }

        Glass {
            id: sidebar

            x: 14
            y: 14
            width: 214
            height: rootClip.height - 28
            radius: 24
            refractionSource: sharpSource
            edgeWidth: 30
            refraction: 18
            dispersion: 1.2
            ambientDim: 0.0
            glassTint: Qt.rgba(0.82, 0.90, 1.0, 0.11)
            readonly property Item activeNavItem: win.page === 0 ? navToday
                : win.page === 1 ? navHourly
                : win.page === 2 ? navTenDay
                : win.page === 3 ? navDetails
                : navPlaces

            MouseArea {
                x: 0
                y: 0
                width: sidebar.width
                height: 52
                acceptedButtons: Qt.LeftButton
                onPressed: win.startSystemMove()
                onDoubleClicked: toggleMax()
            }

            TrafficLights {
                x: 20
                y: 19
                onCloseClicked: Qt.quit()
                onMinimizeClicked: win.showMinimized()
                onMaximizeClicked: toggleMax()
            }

            Column {
                x: 23
                y: 50
                spacing: 1

                Text {
                    text: "Aura"
                    color: "#ffffff"
                    font.family: "Inter Display"
                    font.pixelSize: 25
                    font.weight: Font.Light
                    font.letterSpacing: -0.7
                }

                Text {
                    text: "WEATHER"
                    color: Qt.rgba(1, 1, 1, 0.38)
                    font.family: "Inter"
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 3.2
                }
            }

            Rectangle {
                id: navPill
                x: navColumn.x
                y: navColumn.y + sidebar.activeNavItem.y
                width: navColumn.width
                height: sidebar.activeNavItem.height
                radius: 14
                color: Qt.rgba(1, 1, 1, 0.15)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)
                z: navColumn.z - 1

                Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
                Behavior on height { NumberAnimation { duration: 380; easing.type: Easing.OutQuint } }
            }

            Column {
                id: navColumn
                x: 12
                y: 116
                width: sidebar.width - 24
                spacing: 4

                NavItem {
                    id: navToday
                    width: parent.width
                    label: "Today"
                    icon: "today"
                    active: win.page === 0
                    showHighlight: false
                    onClicked: win.page = 0
                }
                NavItem {
                    id: navHourly
                    width: parent.width
                    label: "Hourly"
                    icon: "hourly"
                    active: win.page === 1
                    showHighlight: false
                    onClicked: win.page = 1
                }
                NavItem {
                    id: navTenDay
                    width: parent.width
                    label: "10-Day"
                    icon: "daily"
                    active: win.page === 2
                    showHighlight: false
                    onClicked: win.page = 2
                }
                NavItem {
                    id: navDetails
                    width: parent.width
                    label: "Details"
                    icon: "details"
                    active: win.page === 3
                    showHighlight: false
                    onClicked: win.page = 3
                }
                NavItem {
                    id: navPlaces
                    width: parent.width
                    label: "Places"
                    icon: "places"
                    active: win.page === 4
                    showHighlight: false
                    onClicked: win.page = 4
                }
            }

            Column {
                x: 12
                y: 386
                width: sidebar.width - 24
                spacing: 2
                visible: sidebar.height > 690

                Item {
                    width: parent.width
                    height: 22

                    Text {
                        x: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        text: "SAVED"
                        color: Qt.rgba(1, 1, 1, 0.35)
                        font.family: "Inter"
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 2
                    }
                }

                Repeater {
                    model: backend.savedPlaces.slice(0, 3)

                    Item {
                        width: parent.width
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: miniArea.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0)
                            Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 68
                            text: modelData.name
                            color: Qt.rgba(1, 1, 1, 0.7)
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.temp !== null && modelData.temp !== undefined
                                ? Math.round(modelData.temp * (backend.units === "imperial" ? 9 / 5 : 1) +
                                    (backend.units === "imperial" ? 32 : 0)) + "°"
                                : "—"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: "Inter Display"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: miniArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.selectPlace(index)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 30

                    Text {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: backend.savedPlaces.length === 0 ? "No saved places" : "Add a place"
                        color: Qt.rgba(1, 1, 1, 0.38)
                        font.family: "Inter"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.searchOpen = true
                    }
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 16
                spacing: 9

                Row {
                    spacing: 6

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: backend.loading ? "#8fd3ff" : "#77e3a1"
                        Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    }

                    Text {
                        text: backend.lastUpdated ? "Updated " + backend.lastUpdated : "Connecting…"
                        color: Qt.rgba(1, 1, 1, 0.38)
                        font.family: "Inter"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 12
                    scale: searchMini.pressed ? 0.985 : 1
                    color: searchMini.containsMouse ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Image {
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            source: backend.asset("assets/nav/search.png")
                            opacity: 0.55
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search"
                            color: Qt.rgba(1, 1, 1, 0.7)
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Ctrl K"
                        color: Qt.rgba(1, 1, 1, 0.26)
                        font.family: "Inter"
                        font.pixelSize: 9
                    }

                    MouseArea {
                        id: searchMini
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.searchOpen = true
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: 94
                        height: 32
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.13)

                        Rectangle {
                            width: 42
                            height: 24
                            y: 4
                            radius: 7
                            x: backend.units === "metric" ? 5 : 47
                            color: Qt.rgba(1, 1, 1, 0.18)
                            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 0

                            Rectangle {
                                width: 42
                                height: 24
                                radius: 7
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "°C"
                                    color: backend.units === "metric" ? "#ffffff" : Qt.rgba(1, 1, 1, 0.45)
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.setUnits("metric")
                                }
                            }

                            Rectangle {
                                width: 42
                                height: 24
                                radius: 7
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "°F"
                                    color: backend.units === "imperial" ? "#ffffff" : Qt.rgba(1, 1, 1, 0.45)
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    Behavior on color { ColorAnimation { duration: 240; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.setUnits("imperial")
                                }
                            }
                        }
                    }

                    Item {
                        width: 32
                        height: 32

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            scale: refreshMini.pressed ? 0.9 : refreshMini.containsMouse ? 1.06 : 1
                            color: refreshMini.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.13)
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                        }

                        Image {
                            id: refreshIcon
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            source: backend.asset("assets/nav/refresh.png")
                            opacity: 0.6

                            NumberAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 900
                                loops: Animation.Infinite
                                running: backend.loading
                            }
                        }

                        MouseArea {
                            id: refreshMini
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.refresh()
                        }
                    }
                }
            }
        }

        Glass {
            id: sheet

            x: sidebar.x + sidebar.width + 10
            y: 14
            width: rootClip.width - x - 14
            height: rootClip.height - 28
            radius: 28
            refractionSource: sharpSource
            edgeWidth: 40
            refraction: 26
            dispersion: 1.6
            ambientDim: 0.0
            glassTint: Qt.rgba(0.82, 0.90, 1.0, 0.09)

            Item {
                anchors.fill: parent

                Item {
                    id: header
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 92

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onPressed: win.startSystemMove()
                        onDoubleClicked: toggleMax()
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 26
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: win.place.name ? win.place.name : "Locating…"
                            color: "#ffffff"
                            font.family: "Inter Display"
                            font.pixelSize: 25
                            font.weight: Font.Medium
                            font.letterSpacing: -0.6
                        }

                        Text {
                            text: {
                                var parts = []
                                if (win.place.region) parts.push(win.place.region)
                                if (win.place.country) parts.push(win.place.country)
                                return parts.join(" · ")
                            }
                            color: Qt.rgba(1, 1, 1, 0.42)
                            font.family: "Inter"
                            font.pixelSize: 10
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            scale: refreshArea.pressed ? 0.9 : refreshArea.containsMouse ? 1.07 : 1
                            color: refreshArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.07)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                            Image {
                                id: headerRefresh
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                source: backend.asset("assets/nav/refresh.png")
                                opacity: 0.75

                                NumberAnimation on rotation {
                                    from: 0
                                    to: 360
                                    duration: 900
                                    loops: Animation.Infinite
                                    running: backend.loading
                                }
                            }

                            MouseArea {
                                id: refreshArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.refresh()
                            }
                        }

                        Rectangle {
                            width: 104
                            height: 34
                            radius: 17
                            scale: searchArea.pressed ? 0.96 : searchArea.containsMouse ? 1.025 : 1
                            color: searchArea.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.07)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 7

                                Image {
                                    width: 14
                                    height: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: backend.asset("assets/nav/search.png")
                                    opacity: 0.8
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search"
                                    color: "#ffffff"
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }

                            MouseArea {
                                id: searchArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.searchOpen = true
                            }
                        }
                    }
                }

                                Item {
                    id: pages
                    anchors.top: header.bottom
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 26
                    anchors.rightMargin: 26
                    anchors.bottomMargin: 22
                    clip: true

                    Today {
                        width: pages.width
                        height: pages.height
                        enabled: win.page === 0
                        x: (0 - win.page) * pages.width
                        scale: win.page === 0 ? 1 : 0.985
                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                        Behavior on scale { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                    }

                    Hourly {
                        width: pages.width
                        height: pages.height
                        enabled: win.page === 1
                        x: (1 - win.page) * pages.width
                        scale: win.page === 1 ? 1 : 0.985
                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                        Behavior on scale { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                    }

                    TenDay {
                        width: pages.width
                        height: pages.height
                        enabled: win.page === 2
                        x: (2 - win.page) * pages.width
                        scale: win.page === 2 ? 1 : 0.985
                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                        Behavior on scale { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                    }

                    Details {
                        width: pages.width
                        height: pages.height
                        enabled: win.page === 3
                        x: (3 - win.page) * pages.width
                        scale: win.page === 3 ? 1 : 0.985
                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                        Behavior on scale { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                    }

                    Places {
                        width: pages.width
                        height: pages.height
                        enabled: win.page === 4
                        x: (4 - win.page) * pages.width
                        scale: win.page === 4 ? 1 : 0.985
                        Behavior on x { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                        Behavior on scale { NumberAnimation { duration: 460; easing.type: Easing.OutQuint } }
                        onRequestSearch: win.searchOpen = true
                    }
                }

                Rectangle {
                    anchors.fill: pages
                    radius: 22
                    color: Qt.rgba(0.02, 0.05, 0.1, 0.28)
                    opacity: backend.loading && !backend.data.current ? 1 : 0
                    visible: opacity > 0.001
                    z: 10
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 12

                        Item {
                            width: 34
                            height: 34
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: 17
                                color: "transparent"
                                border.width: 2
                                border.color: Qt.rgba(1, 1, 1, 0.14)
                            }
                            Rectangle {
                                width: 2.5
                                height: 10
                                radius: 1.2
                                color: "#ffffff"
                                anchors.top: parent.top
                                anchors.topMargin: 3
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: true
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Finding your sky"
                            color: Qt.rgba(1, 1, 1, 0.85)
                            font.family: "Inter Display"
                            font.pixelSize: 19
                            font.weight: Font.Medium
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Pulling the latest forecast"
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.family: "Inter"
                            font.pixelSize: 12
                        }
                    }
                }

                Panel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 18
                    width: Math.min(430, parent.width - 80)
                    height: 56
                    opacity: backend.error.length > 0 ? 1 : 0
                    visible: opacity > 0.001
                    z: 20
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    alpha: 0.13
                    borderAlpha: 0.25

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 78
                            text: backend.error
                            color: Qt.rgba(1, 1, 1, 0.8)
                            font.family: "Inter"
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 62
                            height: 30
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            scale: retryArea.pressed ? 0.94 : retryArea.containsMouse ? 1.04 : 1
                            color: retryArea.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.2)
                            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Retry"
                                color: "#ffffff"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: retryArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.refresh()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 26
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.17)
            z: 90
        }

        SearchOverlay {
            opened: win.searchOpen
            refractionSource: sharpSource
            onDismissed: win.searchOpen = false
        }

        Item {
            x: 0
            y: 30
            width: 6
            height: rootClip.height - 60
            z: 100
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                onPressed: win.startSystemResize(Qt.LeftEdge)
            }
        }
        Item {
            x: rootClip.width - 6
            y: 30
            width: 6
            height: rootClip.height - 60
            z: 100
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeHorCursor
                onPressed: win.startSystemResize(Qt.RightEdge)
            }
        }
        Item {
            x: 30
            y: rootClip.height - 6
            width: rootClip.width - 60
            height: 6
            z: 100
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeVerCursor
                onPressed: win.startSystemResize(Qt.BottomEdge)
            }
        }
    }

    function toggleMax() {
        if (win.visibility === Window.Maximized)
            win.showNormal()
        else
            win.showMaximized()
    }

    Timer {
        interval: 9000
        running: win.shotPath !== ""
        onTriggered: {
            win.contentItem.grabToImage(function (result) {
                result.saveToFile(win.shotPath)
                Qt.quit()
            })
        }
    }
}
