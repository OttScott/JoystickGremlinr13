// -*- coding: utf-8; -*-
//
// Copyright (C) 2015 - 2025 Lionel Ott
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
import QtQuick.Controls.Universal

import "render_helpers.js" as RH


Rectangle {
    id: _control

    readonly property int offset: 5
    property Repeater repeater

    width: offset * 2
    height: offset * 2
    radius: offset

    color: "#66808080"
    border.color: "#66000000"
    border.width: 1

    x: map2u(modelData.center.x)
    y: map2v(modelData.center.y)

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        onReleased: (evt) => {
            let new_x = RH.clamp(map2x(parent.x, null), -1.0, 1.0)
            let new_y = RH.clamp(map2y(parent.y, null), -1.0, 1.0)
            action.setControlPoint(new_x, new_y, index)
        }

        onPositionChanged: (evt) => {
            let coord = updateControlPoint(parent, evt, index)
            if(coord !== null) {
                action.setControlPoint(coord[0], coord[1], index)
            }
        }
    }
}