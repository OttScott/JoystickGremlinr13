// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal


Item {
    implicitHeight: _layout.height
    implicitWidth: _layout.width

    property alias pressChecked: _press.checked
    property alias releaseChecked: _release.checked

    RowLayout {
        id: _layout

        spacing: 4

        Text {
            id: _description

            text: "Activation"
            font.pointSize: 10
        }

        CompactSwitch {
            id: _press

            text: "Press"
            font: _description.font
        }
        CompactSwitch {
            id: _release

            text: "Release"
            font: _description.font
        }
    }
}
