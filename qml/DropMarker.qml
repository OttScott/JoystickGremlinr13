// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls.Universal


Rectangle {
    property bool showMarker: false

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    height: 15

    opacity: showMarker ? 1.0 : 0.0
    color: Universal.accent
    border.color: Qt.darker(Universal.accent, 1.2)
    border.width: 2
}