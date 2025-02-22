// -*- coding: utf-8; -*-
//
// Copyright (C) 2025 Lionel Ott
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal


ProgressBar {
    id: control

    enum Orientation {
        Horizontal,
        Vertical
    }

    value: 0
    padding: 2

    property int barSize: 20
    property int orientation: BetterProgressBar.Orientation.Horizontal

    // Private indicator property
    property bool __isHorizontal: orientation === BetterProgressBar.Orientation.Horizontal

    background: Rectangle {
        implicitHeight: __isHorizontal ? barSize : height
        implicitWidth: __isHorizontal ? width : barSize

        radius: 3
        color: control.Universal.baseLowColor
    }

    contentItem: Item {
        implicitHeight: __isHorizontal ? barSize - 2 : height
        implicitWidth: __isHorizontal ? width : barSize - 2

        Rectangle {
            anchors.bottom: parent.bottom

            height: __isHorizontal ? parent.height : control.visualPosition * parent.height
            width: __isHorizontal ? control.visualPosition * parent.width : parent.width
            radius: 2
            color: control.Universal.accent
        }
    }
}