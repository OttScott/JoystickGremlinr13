// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Universal


Item {
    height: _border.height

    Rectangle {
        id: _border

        width: parent.width
        height: _line.height + _line.anchors.topMargin + _line.anchors.bottomMargin

        Rectangle {
            id: _line

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.bottomMargin: 10

            height: 2

            color: Universal.accent
        }
    }
}