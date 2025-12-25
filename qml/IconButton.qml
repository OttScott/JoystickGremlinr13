// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

Button {
    property alias backgroundColor: _bg.color

    font.family: "bootstrap-icons"
    font.pixelSize: 17

    background: Rectangle {
        id: _bg

        anchors.fill: parent
        color: "transparent"
    }
}