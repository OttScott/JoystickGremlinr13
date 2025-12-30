// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

import Gremlin.Style

Rectangle {
    id: root
    property alias text: _notificationLabel.text

    implicitHeight: _notificationLabel.height
    implicitWidth: _notificationLabel.width
    color: Style.background
    border.color: Style.accent

    Label {
        id: _notificationLabel
        anchors.fill: parent
        anchors.margins: 8
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
