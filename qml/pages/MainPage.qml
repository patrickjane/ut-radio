import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3
import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtMultimedia 5.12
import Qt.labs.settings 1.0

import "../net"
import "../util"
import "../notify"
import "../colors"

Rectangle {
   id: mainPage
   anchors.fill: parent
   property var padding: units.gu(3)
   property bool netReady: false
   property bool resumeAfterSuspend: false
   property bool resumeAfterNetworkError: false
   property bool isReconnecting: false
   property var lastStation

   color: Colors.backgroundColor

   Component.onCompleted: init()

   ListModel {
      id: favouriteModel
   }

   Settings {
      id: settings
      property string lastStation: "{}"
   }

   Timer {
      id: reconnectTimer
      interval: 15000
      repeat: false
      running: false

      onTriggered: onReconnectTimer()
   }

   Connections {
      target: Qt.application

      onAboutToQuit: {
         audioPlayer.stop()
      }

      onStateChanged: {
         switch (Qt.application.state) {
         case Qt.ApplicationActive:
         case Qt.ApplicationInactive:
         case Qt.ApplicationSuspended:
            break;
         case Qt.ApplicationHidden:
            if (!audioPlayer.isPlaying() && resumeAfterSuspend)
               audioPlayer.play()

            break;
         }
      }
   }

   MediaPlayer {
      id: audioPlayer
      audioRole: MediaPlayer.MusicRole
      source: lastStation && lastStation.url || ""

      metaData.onMetaDataChanged: {
         if (metaData.title) {
            stationTitleText.displayText = metaData.title
            stationTitleText.color = Colors.accentText
         } else {
            stationTitleText.displayText = textForStatus()
            stationTitleText.color = Colors.detailText
         }
      }

      onPlaybackStateChanged: mainPage.onPlaybackStateChanged()
      onStatusChanged: mainPage.onStatusChanged(status)
      onError: {
         Notify.error(i18n.tr("Error"), audioPlayer.errorString)
      }
   }

   Column {
      id: playerControls
      anchors.top: parent.top
      anchors.topMargin: mainPage.padding
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width * 0.9
      spacing: mainPage.padding

      Column {
         id: playerTitles
         anchors.horizontalCenter: parent.horizontalCenter
         width: parent.width
         spacing: units.gu(1)

            ScrollableText {
               id: stationText
               font.bold: true
               color: Colors.mainText
               width: playerTitles.width

               displayText: lastStation && lastStation.name || i18n.tr("No station")
            }
         ScrollableText {
            id: stationTitleText
            width: playerTitles.width

            displayText: mainPage.textForStatus()
         }
      }

      Rectangle {
         width: mainPage.width * 0.6
         height: mainPage.width * 0.6
         anchors.horizontalCenter: parent.horizontalCenter
         color: Colors.backgroundColor

         border.width: 1
         border.color: Colors.borderColor

         Icon {
            anchors.fill: parent
            name: "stock_music"
            visible: !lastStation || !lastStation.image
         }

         Image {
            anchors.fill: parent
            visible: lastStation && lastStation.image || false
            source: lastStation && lastStation.image || ""
            asynchronous: true
         }
      }

      Row {
         anchors.horizontalCenter: parent.horizontalCenter
         spacing: mainPage.padding

         Button {
            width: units.gu(4)
            height: units.gu(4)
            anchors.verticalCenter: parent.verticalCenter

            color: Colors.surfaceColor
            iconName: "toolkit_input-search"
            enabled: mainPage.netReady

            onClicked: {
               var p = pageStack.push(Qt.resolvedUrl("./SearchPage.qml"))
               p.stationChanged.connect(setLastStation)
            }
         }

         Button {
            width: units.gu(6)
            height: units.gu(6)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: "media-playback-start"
            enabled: !!lastStation

            onClicked: mainPage.playStream()
         }

         Button {
            id: favIcon
            width: units.gu(4)
            height: units.gu(4)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: lastStation.favourite ? "starred" : "non-starred"
            enabled: !!lastStation

            onClicked: {
               lastStation.favourite = !lastStation.favourite
               favIcon.iconName = lastStation.favourite ? "starred" : "non-starred"

               if (!lastStation.favourite)
                  Functions.removeFavourite(lastStation.stationID)
               else
                  Functions.saveFavourite(lastStation)
            }
         }

         Button {
            width: units.gu(6)
            height: units.gu(6)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: "media-playback-stop"
            enabled: !!lastStation

            onClicked: mainPage.stopStream()
         }

         Button {
            width: units.gu(4)
            height: units.gu(4)
            anchors.verticalCenter: parent.verticalCenter
            color: Colors.surfaceColor
            iconName: "stock_link"

            onClicked: {
               var p = pageStack.push(Qt.resolvedUrl("./UrlPage.qml"))
               p.stationChanged.connect(mainPage.setLastStation)
            }
         }
      }

      Row {
         anchors.horizontalCenter: parent.horizontalCenter
         spacing: mainPage.padding

         Rectangle {
            height: units.gu(2)
            width: units.gu(2)
            color: "transparent"
         }

         Text {
            anchors.verticalCenter: parent.verticalCenter
            text: i18n.tr("Favourites")
            color: Colors.mainText
            font.bold: true
            visible: favouriteModel.count
         }

         Icon {
            id: settingsIcon
            height: units.gu(2)
            width: units.gu(2)
            anchors.verticalCenter: parent.verticalCenter

            name: "settings"

            MouseArea {
               anchors.fill: parent
               onClicked: {
                  var p = pageStack.push(Qt.resolvedUrl("./SettingsPage.qml"))
               }
            }
         }
      }
   }

   ListView {
      id: favList
      anchors.top: playerControls.bottom
      anchors.topMargin: padding/2
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      clip: true

      model: favouriteModel

      delegate: ListItem {
         height: layout.height + (divider.visible ? divider.height : 0)
         color: Colors.surfaceColor
         divider.colorFrom: Colors.borderColor
         divider.colorTo: Colors.borderColor
         highlightColor: Colors.highlightColor

         onClicked: mainPage.setLastStation(JSON.parse(JSON.stringify(favouriteModel.get(index))))

         leadingActions: ListItemActions {
            actions: [
               Action {
                  iconName: "delete"
                  onTriggered: {
                     Functions.removeFavourite(stationID)
                  }
               }
            ]
         }

         trailingActions: ListItemActions {
            actions: [
               Action {
                  iconName: "edit-copy"
                  onTriggered: {
                     Clipboard.push(url)
                  }
               }
            ]
         }

         SlotsLayout {
            id: layout
            mainSlot: Label {
               text: name
               color: Colors.mainText
            }
            Image {
               source: image
               SlotsLayout.position: SlotsLayout.Leading;
               width: units.gu(4)
               height: units.gu(4)
               asynchronous: true
            }
         }
      }
   }

   // *******************************************************************
   // Init
   // *******************************************************************

   function init() {
      Network.init(function(err) {
         netReady = !err

         if (err)
            Notify.error(i18n.tr("Radio Browser"), i18n.tr("Failed to lookup hostname for radio-browser.info. Searching for web streams might be unavailable. Check internet connection and restart app.") + "\n" + err)
      })

      Functions.favouriteModel = favouriteModel
      Functions.init()

      var s
      try {
         s = JSON.parse(settings.value("lastStation"))
         lastStation = s
         lastStation.favourite = Functions.hasFavourite(s.stationID)
         favIcon.iconName = s.favourite ? "starred" : "non-starred"
      } catch (e) {}
   }

   // *******************************************************************
   // Player Controls
   // *******************************************************************

   function playStream() {
      stopReconnecting()
      audioPlayer.play()
      mainPage.resumeAfterSuspend = true
      mainPage.resumeAfterNetworkError = true

      if (!lastStation.manual)
         Network.countClick(lastStation)
   }

   function stopStream() {
      stopReconnecting()
      mainPage.resumeAfterSuspend = false
      mainPage.resumeAfterNetworkError = false
      audioPlayer.stop()
   }

   function setLastStation(station) {
      audioPlayer.stop()
      mainPage.lastStation = station
      favIcon.iconName = lastStation.favourite ? "starred" : "non-starred"
      settings.setValue("lastStation", JSON.stringify(mainPage.lastStation))
      audioPlayer.play()
      mainPage.resumeAfterSuspend = true
      mainPage.resumeAfterNetworkError = true

      Notify.info(i18n.tr("Playing"), station.name || i18n.tr("Web stream"))
   }

   // *******************************************************************
   // Connection recovery
   // *******************************************************************

   function reconnectLater() {
      console.log("Connection broken, trying to reconnect in " + (reconnectTimer.interval/1000) + "s ...")
      reconnectTimer.start()
      resumeAfterNetworkError = false

      Notify.warning(i18n.tr("Reconnecting"), i18n.tr("Connection broken, trying to reconnect ..."))
   }

   function stopReconnecting() {
      isReconnecting = false
      reconnectTimer.stop()
   }

   function onReconnectTimer() {
      console.log("Trying to reconnect ...")

      isReconnecting = true
      var ls = mainPage.lastStation
      mainPage.lastStation = null
      audioPlayer.stop()
      mainPage.lastStation = ls
      audioPlayer.play()
   }

   // *******************************************************************
   // SLOTS
   // *******************************************************************

   function onPlaybackStateChanged() {
      stationTitleText.displayText = textForPlaybackStatus()
      stationTitleText.color = Colors.detailText

      if (audioPlayer.playbackState === MediaPlayer.PlayingState
            && audioPlayer.status > 0 && audioPlayer.status < 4) {
         stopReconnecting()
      }

      if (audioPlayer.playbackRate === MediaPlayer.PausedState && isReconnecting) {
         audioPlayer.play()
      }
   }

   function onStatusChanged(status) {
      stationTitleText.displayText = textForStatus()
      stationTitleText.color = Colors.detailText

      if (resumeAfterNetworkError &&
            (status === MediaPlayer.EndOfMedia
             || status === MediaPlayer.InvalidMedia
             || status === MediaPlayer.UnknownStatus)) {
         reconnectLater();
      }
      else if (status === MediaPlayer.EndOfMedia)
         audioPlayer.play()
   }

   // *******************************************************************
   // Util
   // *******************************************************************

   function textForPlaybackStatus() {
      switch (audioPlayer.playbackState) {
      case MediaPlayer.PlayingState: return i18n.tr("Playing")
      case MediaPlayer.StoppedState: return i18n.tr("Stopped")
      case MediaPlayer.PausedState:  return i18n.tr("Paused")
      }
   }

   function textForStatus() {
      switch (audioPlayer.status) {
      case MediaPlayer.NoMedia:       return i18n.tr("NoMedia")
      case MediaPlayer.Loading:       return i18n.tr("Loading")
      case MediaPlayer.Loaded:        return textForPlaybackStatus()
      case MediaPlayer.Buffering:     return i18n.tr("Buffering")
      case MediaPlayer.Stalled:       return i18n.tr("Stalled")
      case MediaPlayer.Buffered:      return i18n.tr("Buffered")
      case MediaPlayer.EndOfMedia:    return i18n.tr("End of media")
      case MediaPlayer.InvalidMedia:  return i18n.tr("Invalid media")
      case MediaPlayer.UnknownStatus: return i18n.tr("Unknown status")
      }

      return ""
   }

   function isPlaying() {
      return audioPlayer.playbackState == MediaPlayer.PlayingState
   }
}
