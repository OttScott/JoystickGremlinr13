// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

ToolButton {
    property alias color: _icon.color
    property alias tooltip: _tooltip.text

    contentItem: Label {
        id: _icon

        text: parent.text

        font.family: "bootstrap-icons"
        font.pixelSize: 24

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    ToolTip {
        id: _tooltip

        visible: parent.hovered
        delay: 500
    }
}
