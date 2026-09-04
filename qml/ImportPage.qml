/* 
 * Copyright (C) 2026 renzard politakis
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ImportPage.qml - Επιλογέας αρχείων/συλλογής για Lomiri / Ubuntu Touch
 */

import QtQuick 2.9
import Lomiri.Components 1.3
import Lomiri.Content 1.3
import QtQuick.Controls.Suru 2.2

Page {
    id: importPage
    objectName: "importPage"

    // Ίδια λογική χρωμάτων με το Main.qml, ώστε το header εδώ να ταιριάζει
    // οπτικά με την υπόλοιπη εφαρμογή, ΚΑΙ να προσαρμόζεται στο light/dark
    // θέμα της συσκευής αντί να μένει πάντα στο ίδιο, φωναχτό μωβ.
    property color b_color: "#501644"
    property color b_colorDark: "#1b0e17"
    readonly property color headerColor: Suru.theme === 0 ? b_color : b_colorDark
    readonly property color accentColor: Suru.theme === 0 ? b_color : "#d99fc9"

    // Signals για ενημέρωση του Main.qml
    signal imported(var fileUrl)
    signal canceled()

    property var contentType: ContentType.All
    property var handler: ContentHandler.Source
    property var activeTransfer: null

    // FIX: αυτή η σελίδα φορτώνεται δυναμικά από άλλο αρχείο (Main.qml) μέσω
    // Qt.resolvedUrl(), άρα ΔΕΝ βλέπει τα id του Main.qml (π.χ. mainPageStack).
    // Το page stack περνάει τώρα ρητά ως property κατά το push() - πριν, το
    // κουμπί "Πίσω" και το "Cancel" προσπαθούσαν να καλέσουν ένα id που δεν
    // υπήρχε καν σε αυτό το scope.
    property var pageStack: null

    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Επιλογή Αρχείου")

        leadingActionBar.actions: [
            Action {
                iconName: "close"
                text: i18n.tr("Ακύρωση")
                onTriggered: {
                    importPage.canceled();
                    if (importPage.pageStack) importPage.pageStack.pop();
                }
            }
        ]

        StyleHints {
            foregroundColor: "white"
            backgroundColor: importPage.headerColor
            dividerColor: importPage.headerColor
        }
    }

    // Ελαφρύ, θεματικό φόντο πίσω από τη λίστα επιλογής, ώστε η σελίδα να
    // μη φαίνεται σαν "γυμνό" system dialog.
    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.background
    }

    Column {
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
        }
        anchors.margins: units.gu(2)
        spacing: units.gu(0.5)

        Label {
            text: i18n.tr("Από πού θέλεις να προσθέσεις το αρχείο;")
            textSize: Label.Medium
            font.bold: true
            wrapMode: Text.WordWrap
            width: parent.width
        }

        Label {
            text: i18n.tr("Διάλεξε μια από τις παρακάτω πηγές.")
            textSize: Label.Small
            opacity: 0.6
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }

    ContentPeerPicker {
        id: peerPicker
        anchors {
            top: pageHeader.bottom
            topMargin: units.gu(9)
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        contentType: importPage.contentType
        handler: importPage.handler

        onPeerSelected: {
            peer.selectionType = ContentTransfer.Single;
            importPage.activeTransfer = peer.request();

            if (importPage.activeTransfer) {
                importPage.activeTransfer.stateChanged.connect(function() {
                    if (importPage.activeTransfer.state === ContentTransfer.Charged) {
                        if (importPage.activeTransfer.items.length > 0) {
                            var fileUrl = importPage.activeTransfer.items[0].url;
                            importPage.imported(fileUrl);
                        } else {
                            // FIX: αν ο μεταφορέας ολοκληρώθηκε αλλά δεν έφερε
                            // κανένα αρχείο, ενημέρωνε ξανά ως "canceled" ώστε
                            // το Main.qml να απορρίψει το αίτημα αντί να μείνει
                            // κρεμασμένο περιμένοντας ένα imported που δεν θα έρθει ποτέ.
                            importPage.canceled();
                        }
                    } else if (importPage.activeTransfer.state === ContentTransfer.Aborted) {
                        importPage.canceled();
                    }
                });
            }
        }

        onCancelPressed: {
            importPage.canceled();
            if (importPage.pageStack) importPage.pageStack.pop();
        }
    }
}
