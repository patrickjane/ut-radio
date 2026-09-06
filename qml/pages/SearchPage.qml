import Lomiri.Components 1.3
import Lomiri.Components.ListItems 1.3
import QtQuick 2.7
import QtQuick.Layouts 1.3
import QtMultimedia 5.12
import Qt.labs.settings 1.0

import "../net"
import "../util"
import "../colors"

Rectangle {
   id: searchPage
   anchors.fill: parent
   signal stationChanged(var station)

   property var searchCategories: [
      i18n.tr("Name"),
      i18n.tr("Tag"),
      i18n.tr("Country"),
      i18n.tr("Language")
   ]
   property string searchCategory: searchCategories[0]

   property var sortCategories: [
      i18n.tr("Name"),
      i18n.tr("Tags"),
      i18n.tr("Country"),
      i18n.tr("Language"),
      i18n.tr("Votes"),
      i18n.tr("Click count"),
      i18n.tr("Random")
   ]
   property string sortCategory: sortCategories[0]
   property bool resultListReversed: false

   color: Colors.backgroundColor

   ThemedHeader {
      id: header
      title: i18n.tr("Search")
   }

   ListModel {
      id: searchResultsModel
   }

   ListItem {
      id: searchType
      anchors.top: header.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      color: Colors.surfaceColor
      divider.colorFrom: Colors.borderColor
      divider.colorTo: Colors.borderColor
      highlightColor: Colors.highlightColor

      height: layoutSearchType.height + (divider.visible ? divider.height : 0)

      SlotsLayout {
         id: layoutSearchType
         mainSlot: OptionSelector {
            selectedIndex: 0
            model:searchCategories

            onDelegateClicked: {
               searchCategory = searchCategories[index]

               if (searchInputField.text.length)
                  startSearch()
            }
         }
         Text {
            width: units.gu(10)
            SlotsLayout.overrideVerticalPositioning: true
            anchors.verticalCenter: parent.verticalCenter
            text: i18n.tr("Search by:")
            color: Colors.mainText
            SlotsLayout.position: SlotsLayout.Leading
         }
      }
   }

   ListItem {
      id: sortType
      anchors.top: searchType.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      color: Colors.surfaceColor
      divider.colorFrom: Colors.borderColor
      divider.colorTo: Colors.borderColor
      highlightColor: Colors.highlightColor

      height: layoutSortType.height + (divider.visible ? divider.height : 0)

      SlotsLayout {
         id: layoutSortType
         mainSlot: OptionSelector {
            selectedIndex: 0
            model: sortCategories

            onDelegateClicked: {
               sortCategory = sortCategories[index]

               if (searchInputField.text.length)
                  startSearch()
            }
         }
         Text {
            width: units.gu(10)
            SlotsLayout.overrideVerticalPositioning: true
            anchors.verticalCenter: parent.verticalCenter
            text: i18n.tr("Sort by:")
            color: Colors.mainText
            SlotsLayout.position: SlotsLayout.Leading
         }
         Icon {
            width: units.gu(3)
            height: units.gu(3)
            SlotsLayout.position: SlotsLayout.Trailing;
            SlotsLayout.overrideVerticalPositioning: true
            anchors.verticalCenter: parent.verticalCenter
            name: "sort-listitem"

            MouseArea {
               anchors.fill: parent
               onClicked: {
                  resultListReversed = !resultListReversed

                  if (searchInputField.text.length)
                     startSearch()
               }
            }
         }
      }
   }

   ListItem {
      id: searchInput
      anchors.top: sortType.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      color: Colors.surfaceColor
      divider.colorFrom: Colors.borderColor
      divider.colorTo: Colors.borderColor
      highlightColor: Colors.highlightColor

      height: layoutSearchInput.height + (divider.visible ? divider.height : 0)

      SlotsLayout {
         id: layoutSearchInput
         mainSlot: TextField {
            id: searchInputField
            placeholderText: i18n.tr("Enter search term")
            onAccepted: startSearch()
         }
         Button {
            text: i18n.tr("Search")
            enabled: searchInputField.text.length
            SlotsLayout.position: SlotsLayout.Trailing;
            onClicked: {
               busySearching.running = true
               startSearch()
            }
         }
      }
   }

   function startSearch() {
      searchResultsModel.clear()

      Network.searchStation(searchInputField.text, searchCategory, sortCategory, resultListReversed, function(err, results) {
         if (err)
            Notify.error(i18n.tr("Radio Browser"), i18n.tr("Failed to search for stations at radio-browser.info. Check internet connection.") + "\n" + err)
         else
            (results || []).forEach(function(r) { searchResultsModel.append(r) })
            busySearching.running = false
      })
   }

   ActivityIndicator {
      id: busySearching
      anchors.centerIn: parent
      running: false
   }

   ListView {
      id: searchResults
      anchors.top: searchInput.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      clip: true

      model: searchResultsModel

      delegate: ListItem {
         height: resultRowLayout.height + (divider.visible ? divider.height : 0)
         color: Colors.surfaceColor
         divider.colorFrom: Colors.borderColor
         divider.colorTo: Colors.borderColor
         highlightColor: Colors.highlightColor

         trailingActions: ListItemActions {
            actions: [
               Action {
                  iconName: "edit-copy"
                  onTriggered: {
                     Clipboard.push(searchResultsModel.get(index).url)
                  }
               }
            ]
         }

         onClicked: {
            pageStack.pop()
            emit: stationChanged(JSON.parse(JSON.stringify(searchResultsModel.get(index))))
         }

         SlotsLayout {
            id: resultRowLayout
            mainSlot: Rectangle {
               Column {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: units.gu(0.5)
                  Text {
                     anchors.left: parent.left
                     width: parent.width
                     clip: true

                     text: name
                     color: Colors.mainText
                     font.pixelSize: units.gu(1.5)
                  }
                  Row {
                     anchors.left: parent.left
                     anchors.right: parent.right
                     anchors.rightMargin: units.gu(1)
                     spacing: units.gu(1)
                     clip: true

                     Text {
                        text: i18n.tr("Votes") + ": " + votes
                        font.pixelSize: units.gu(1)
                        color: Colors.mainText
                     }
                     Text {
                        text: i18n.tr("Click count") + ": " + clickcount
                        font.pixelSize: units.gu(1)
                        color: Colors.mainText
                     }
                     Text {
                        text: countryCode && language
                              ? (countryCode + "/" + language)
                              : (countryCode || language || "" )
                        font.pixelSize: units.gu(1)
                        color: Colors.mainText
                        clip: true
                     }
                  }
               }
            }

            Image {
               source: image
               SlotsLayout.position: SlotsLayout.Leading;
               width: units.gu(4)
               height: units.gu(4)
               asynchronous: true
            }
            Icon {
               id: favButton
               width: units.gu(4)
               height: units.gu(4)
               SlotsLayout.position: SlotsLayout.Trailing;
               name: favourite ? "starred" : "non-starred"

               MouseArea {
                  anchors.fill: parent
                  onClicked: {
                     searchResultsModel.setProperty(index, "favourite", !favourite)

                     if (!favourite) {
                        Functions.removeFavourite(stationID)
                     } else {
                        Functions.saveFavourite(searchResultsModel.get(index))
                     }
                  }
               }
            }
         }
      }
   }
}
