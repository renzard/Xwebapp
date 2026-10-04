import QtQuick 2.9
import Lomiri.Components 1.3

// Κυμαινόμενο "+" που ξεπροβάλλει από το κάτω άκρο. Όταν το πατάς, ανεβαίνει
// απαλά και οι επιλογές ανοίγουν σε βεντάλια, η μία μετά την άλλη.
Item {
  id: root

  property bool expanded: false
  property color accentColor: "#1D9BF0"
  property bool canGoBack: true
  signal navigate(string target)

  readonly property real btnSize: units.gu(7)
  readonly property real itemSize: units.gu(5)
  readonly property real arcRadius: units.gu(18)
  readonly property real liftDistance: units.gu(4)   // πόσο ανεβαίνει το κουμπί
  readonly property real staggerFrac: 0.4            // πόσο "αργά" ξεκινά η κάθε επιλογή

  // lift: κίνηση του κουμπιού (με ελαφρύ "ελατήριο")
  property real lift: expanded ? 1 : 0
  Behavior on lift {
    NumberAnimation {
      duration: root.expanded ? 380 : 260
      easing.type: root.expanded ? Easing.OutBack : Easing.InOutCubic
      easing.overshoot: 1.3
    }
  }

  // progress: γραμμικός "ρυθμιστής" για τις επιλογές και το σκούρο φόντο
  property real progress: expanded ? 1 : 0
  Behavior on progress {
    NumberAnimation {
      duration: root.expanded ? 520 : 260
      easing.type: Easing.Linear
    }
  }

  readonly property var entries: [
    { key: "back",    label: i18n.tr("Back"),          icon: "back" },
    { key: "home",    label: i18n.tr("Home"),          icon: "home" },
    { key: "explore", label: i18n.tr("Explore"),       icon: "find" },
    { key: "notifs",  label: i18n.tr("Notifications"), icon: "notification" },
    { key: "inbox",   label: i18n.tr("Messages"),      icon: "message" },
    { key: "post",    label: i18n.tr("Post"),          icon: "edit" },
    { key: "reload",  label: i18n.tr("Refresh"),       icon: "reload" }
  ]

  // Σκούρο scrim πίσω από το μενού· πατώντας οπουδήποτε αλλού κλείνει.
  Rectangle {
    anchors.fill: parent
    color: "black"
    opacity: root.progress * 0.4
    visible: opacity > 0
  }
  MouseArea {
    anchors.fill: parent
    enabled: root.expanded
    onClicked: root.expanded = false
  }

  Item {
    id: origin
    width: root.btnSize
    height: root.btnSize
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    // Το κέντρο του origin ακολουθεί το κέντρο του ΟΡΑΤΟΥ μέρους του κουμπιού
    anchors.bottomMargin: -root.btnSize / 4 + root.lift * root.liftDistance

    Repeater {
      model: root.entries

      delegate: Item {
        id: entry

        readonly property real angle: Math.PI * (1 - index / (root.entries.length - 1))

        // Το "Back" είναι ανενεργό όταν δεν υπάρχει προηγούμενη σελίδα
        readonly property bool active: modelData.key !== "back" || root.canGoBack

        // Προσωπική πρόοδος της επιλογής (0..1), με καθυστέρηση ανά θέση
        readonly property real t: {
          var start = (index / (root.entries.length - 1)) * root.staggerFrac;
          var v = (root.progress - start) / (1 - root.staggerFrac);
          return Math.max(0, Math.min(1, v));
        }
        // easeOutBack: βγαίνει λίγο παραπάνω και "κάθεται" στη θέση του
        readonly property real eased: {
          var c1 = 1.5, c3 = c1 + 1, u = t - 1;
          return t <= 0 ? 0 : (t >= 1 ? 1 : 1 + c3 * u * u * u + c1 * u * u);
        }

        width: root.itemSize
        height: root.itemSize
        x: (origin.width - width) / 2 + Math.cos(angle) * root.arcRadius * eased
        y: (origin.height - height) / 2 - Math.sin(angle) * root.arcRadius * eased
        opacity: Math.min(1, t * 2.5) * (active ? 1 : 0.35)
        scale: 0.3 + 0.7 * Math.min(1, eased)
        visible: opacity > 0

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: "#262626"
          border.color: root.accentColor
          border.width: units.dp(2)

          Icon {
            anchors.centerIn: parent
            width: units.gu(3)
            height: units.gu(3)
            name: modelData.icon
            color: "white"
          }
        }

        Label {
          anchors.top: parent.bottom
          anchors.topMargin: units.gu(0.4)
          anchors.horizontalCenter: parent.horizontalCenter
          text: modelData.label
          textSize: Label.XSmall
          color: "white"
          opacity: entry.t   // οι ετικέτες εμφανίζονται λίγο πιο αργά
        }

        MouseArea {
          anchors.fill: parent
          enabled: root.expanded && entry.t > 0.6 && entry.active
          onClicked: {
            root.expanded = false
            root.navigate(modelData.key)
          }
        }
      }
    }
  }

  // Το κύριο κουμπί: μισός κύκλος στο κάτω άκρο· όταν πατιέται ανεβαίνει και
  // το "+" γυρίζει 45° και γίνεται "×".
  Rectangle {
    id: mainBtn
    width: root.btnSize
    height: root.btnSize
    radius: width / 2
    // Μαύρο κουμπί με μπλε περίγραμμα, στο στυλ του X
    color: "black"
    border.color: root.accentColor
    border.width: units.dp(2)
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: -root.btnSize / 2 + root.lift * root.liftDistance

    // Το εικονίδιο κατεβαίνει στο κέντρο του κουμπιού όσο αυτό ανεβαίνει
    Item {
      id: iconBox
      width: units.gu(3.4)
      height: units.gu(3.4)
      anchors.horizontalCenter: parent.horizontalCenter
      y: (root.btnSize / 4 - height / 2) + root.lift * (root.btnSize / 4)

      // Το λογότυπο "X" όταν το μενού είναι κλειστό
      Label {
        anchors.centerIn: parent
        text: "X"
        font.bold: true
        font.pixelSize: units.gu(3.4)
        color: "white"
        opacity: 1 - root.progress
        rotation: 90 * root.progress
        visible: opacity > 0
      }

      // "×" όταν το μενού είναι ανοιχτό
      Icon {
        anchors.fill: parent
        name: "close"
        color: "white"
        opacity: root.progress
        rotation: -90 * (1 - root.progress)
        visible: opacity > 0
      }
    }

    // Μεγαλύτερη περιοχή αφής προς τα πάνω, αφού φαίνεται μόνο το μισό κουμπί
    MouseArea {
      anchors {
        fill: parent
        topMargin: -units.gu(1.5)
      }
      onClicked: root.expanded = !root.expanded
    }
  }
}
