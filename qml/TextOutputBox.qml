// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal

Rectangle {
    id: root
    property alias text: _notificationLabel.text

    implicitHeight: _notificationLabel.height
    implicitWidth: _notificationLabel.width
    color: Universal.background
    border.color: Universal.accent

    Label {
        id: _notificationLabel
        anchors.fill: parent
        anchors.margins: 8
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
