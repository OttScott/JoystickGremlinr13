// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls.Universal


Rectangle {
    property int spacing: 10
    property int lineWidth: 1
    property bool dividerVisible: true
    property color dividerColor: Universal.accent

    height: spacing
    z: -1

    color: Universal.background

    Loader {
        active: dividerVisible

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        sourceComponent: Rectangle {
            height: lineWidth
            color: dividerColor
        }
    }
}