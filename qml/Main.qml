/* 
 * Copyright (C) 2026 renzard politakis
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * notes is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import Lomiri.Components 1.3
import QtQuick.Window 2.2
import Morph.Web 0.1
import QtWebEngine 1.7
import Qt.labs.settings 1.0
import QtSystemInfo 5.5
import Lomiri.Content 1.3
import QtQuick.Controls.Suru 2.2


MainView {
  id: mainView

  objectName: "mainView"

  // Το X (πρώην Twitter) είναι πλέον μαύρο-themed by design, οπότε
  // χρησιμοποιούμε το ίδιο μαύρο και στα δύο themes.
  property color b_color: "#000000"
  property color b_colorDark: "#000000"

  readonly property color headerColor: Suru.theme === 0 ? b_color : b_colorDark
  // Το χαρακτηριστικό μπλε του Twitter/X για κουμπιά, progress bar κ.λπ.
  readonly property color accentColor: "#1D9BF0"

  width: units.gu(45)
  height: units.gu(75)

  applicationName: "x.unofficial"
  backgroundColor: "black"

  anchors {
    fill: parent
    bottomMargin: LomiriApplication.inputMethod.visible ? LomiriApplication.inputMethod.keyboardRectangle.height/(units.gridUnit / 8) : 0
  }

  // FIX: Το "Behavior on X" πρέπει να δηλώνεται ΕΚΤΟΣ του grouped property
  // block (anchors {...}). Μέσα στο group επιτρέπονται μόνο απλές τιμές
  // ιδιοτήτων, όχι δηλώσεις αντικειμένων σαν το Behavior - όπως ήταν πριν,
  // το animation ποτέ δεν εφαρμοζόταν στην πραγματικότητα.
  Behavior on anchors.bottomMargin {
    NumberAnimation {
      duration: 175
      easing.type: Easing.OutQuad
    }
  }

  PageStack {
    id: mainPageStack
    anchors.fill: parent
    Component.onCompleted: mainPageStack.push(pageMain)

    Page {
      id: pageMain
      anchors.fill: parent

      // ---- Μοντέρνο, branded top bar πάνω από το webview ----
      header: PageHeader {
        id: mainHeader
        title: i18n.tr("X")

        leadingActionBar.actions: [
          Action {
            iconName: "back"
            text: i18n.tr("Πίσω")
            enabled: webview.canGoBack
            onTriggered: webview.goBack()
          }
        ]

        trailingActionBar.actions: [
          Action {
            iconName: "reload"
            text: i18n.tr("Ανανέωση")
            onTriggered: webview.reload()
          }
        ]

        StyleHints {
          foregroundColor: "white"
          backgroundColor: mainView.headerColor
          dividerColor: mainView.headerColor
        }
      }

      WebEngineView {
        id: webview
        anchors {
          top: mainHeader.bottom
          left: parent.left
          right: parent.right
          bottom: parent.bottom
        }
        focus: true

        settings.pluginsEnabled: true
        settings.accelerated2dCanvasEnabled: true
        settings.webGLEnabled: true
        settings.showScrollBars: false
        settings.playbackRequiresUserGesture: false

        // Κρατάμε ένα flag για να ξέρουμε αν η τελευταία φόρτωση απέτυχε
        // (π.χ. δεν υπάρχει σύνδεση στο ίντερνετ), ώστε να δείξουμε τη δική
        // μας, μοντέρνα οθόνη σφάλματος αντί για την άσχημη προεπιλεγμένη
        // του Chromium.
        property bool hasError: false

        profile: WebEngineProfile {
          id: webContext
          httpUserAgent: "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.163 Mobile Safari/537.36"
          storageName: "x.unofficial"
          persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
          httpCacheType: WebEngineProfile.DiskHttpCache
          httpCacheMaximumSize: 157286400 // 150MB - λιγότερα ξαναφορτώματα σε επόμενα ανοίγματα
        }

        userScripts: WebEngineScript {
          injectionPoint: WebEngineScript.DocumentReady
          worldId: WebEngineScript.MainWorld
          name: "scrollbartheme"
          sourceUrl: "scrollBarTheme.js"
        }

        url: "https://x.com/"

        // Δικαιώματα για Ειδοποιήσεις, Μικρόφωνο και Κάμερα
        onFeaturePermissionRequested: function(securityOrigin, feature) {
            if (feature === WebEngineView.Notifications ||
                feature === WebEngineView.MediaAudioCapture ||
                feature === WebEngineView.MediaVideoCapture ||
                feature === WebEngineView.MediaAudioVideoCapture) {
                grantFeaturePermission(securityOrigin, feature, true);
            }
        }

        // Επιλογή και αποστολή φωτογραφίας/βίντεο σε νέο tweet/DM
        onFileDialogRequested: function(request) {
          request.accepted = true;
          var importPage = mainPageStack.push(Qt.resolvedUrl("ImportPage.qml"), {
            "contentType": ContentType.All,
            "handler": ContentHandler.Source,
            "pageStack": mainPageStack
          })
          importPage.imported.connect(function(fileUrl) {
            request.dialogAccept([String(fileUrl).replace("file://", "")]);
            mainPageStack.pop();
          })
          importPage.canceled.connect(function() {
            request.dialogReject();
            mainPageStack.pop();
          })
        }

        onNewViewRequested: {
            request.action = WebEngineNavigationRequest.IgnoreRequest
            if (request.userInitiated) {
                Qt.openUrlExternally(request.requestedUrl)
            }
        }

        onLoadingChanged: function(loadRequest) {
          if (loadRequest.status === WebEngineView.LoadFailedStatus) {
            webview.hasError = true;
          } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
            webview.hasError = false;
          }
        }
      }

      // ---- Λεπτή μπάρα προόδου φόρτωσης, κάτω από το header ----
      Rectangle {
        anchors { top: mainHeader.bottom; left: parent.left }
        height: units.gu(0.3)
        width: parent.width * (webview.loadProgress / 100)
        color: mainView.accentColor
        visible: webview.loadProgress > 0 && webview.loadProgress < 100 && !webview.hasError
        Behavior on width { NumberAnimation { duration: 120 } }
      }

      // ---- Δική μας οθόνη "χωρίς σύνδεση", αντί για το προεπιλεγμένο,
      // άσχημο error page του Chromium ----
      Rectangle {
        anchors { top: mainHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        color: theme.palette.normal.background
        visible: webview.hasError

        Column {
          anchors.centerIn: parent
          spacing: units.gu(2)
          width: parent.width * 0.8

          Rectangle {
            width: units.gu(9)
            height: units.gu(9)
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(mainView.accentColor.r, mainView.accentColor.g, mainView.accentColor.b, 0.15)

            Label {
              anchors.centerIn: parent
              text: "⚠"
              textSize: Label.XLarge
              color: mainView.accentColor
            }
          }

          Label {
            text: i18n.tr("Δεν υπάρχει σύνδεση στο διαδίκτυο")
            textSize: Label.Large
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.WordWrap
          }

          Label {
            text: i18n.tr("Έλεγξε τη σύνδεσή σου και δοκίμασε ξανά.")
            textSize: Label.Small
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.WordWrap
            opacity: 0.7
          }

          Button {
            text: i18n.tr("Δοκίμασε ξανά")
            anchors.horizontalCenter: parent.horizontalCenter
            color: mainView.accentColor
            onClicked: {
              webview.hasError = false;
              webview.reload();
            }
          }
        }
      }

      // ---- Splash screen κατά το πρώτο άνοιγμα ----
      // Απλό μαύρο φόντο με το μονόχρωμο "X" λογότυπο, όπως το σημερινό
      // branding του X - και σβήνει μόλις φορτώσει η πρώτη σελίδα.
      Rectangle {
        id: splashScreen
        anchors.fill: parent
        z: 1000
        color: mainView.headerColor
        opacity: 1
        visible: opacity > 0

        Behavior on opacity {
          NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
        }

        Column {
          anchors.centerIn: parent
          spacing: units.gu(2)

          Label {
            text: "X"
            textSize: Label.XLarge
            font.bold: true
            font.pixelSize: units.gu(9)
            color: "white"
            anchors.horizontalCenter: parent.horizontalCenter
          }
        }

        Connections {
          target: webview
          onLoadingChanged: function(loadRequest) {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
              splashScreen.opacity = 0;
            }
          }
        }

        Timer {
          interval: 6000
          running: true
          onTriggered: splashScreen.opacity = 0
        }
      }
    }
  }
}
