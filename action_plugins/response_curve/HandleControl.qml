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
import QtQuick.Shapes

import "render_helpers.js" as RH


Rectangle {
    id: _control

    readonly property int offset: 5
    property Repeater repeater

    property alias leftHandle: _handleLeft
    property alias rightHandle: _handleRight

    width: offset * 2
    height: offset * 2
    radius: offset

    color: "#66808080"
    border.color: "#66000000"
    border.width: 1

    function updateHandle(handle, evt, side) {
        // Compute new data values
        let new_x = RH.clamp(map2x(_control.x + handle.x, evt.x), -1.0, 1.0)
        let new_y = RH.clamp(map2y(_control.y + handle.y, evt.y), -1.0, 1.0)

        // Compute new visual values
        let new_u = ((new_x - modelData.center.x) / 2.0) * _vis.size
        let new_v = -((new_y - modelData.center.y) / 2.0) * _vis.size

        // Handle symmetry mode, no need to update model as
        // the code does this behind the scenes with the
        // model update below
        if (_root.action.isSymmetric) {
            let mirror = repeater.itemAt(repeater.count - index - 1).item
            let dx = new_u - handle.x
            let dy = new_v - handle.y

            if(side === "left") {
                mirror.rightHandle.x -= dx
                mirror.rightHandle.y += dy
            }
            else if(side === "right") {
                mirror.leftHandle.x -= dx
                mirror.leftHandle.y += dy
            }
        }

        // Move the actual marker then update data model
        handle.x = new_u
        handle.y = new_v
        action.setControlHandle(new_x, new_y, index, side)
    }

    x: map2u(modelData.center.x)
    y: map2v(modelData.center.y)

    // Rendering of the control point handles and their connection line
    Shape {
        preferredRendererType: Shape.CurveRenderer

        // Left control handle line
        ShapePath {
            strokeColor: modelData.hasLeft ? "#808080" : "transparent"

            startX: offset
            startY: offset

            PathLine {
                x: _handleLeft.x + offset
                y: _handleLeft.y + offset
            }
        }

        // Right control handle line
        ShapePath {
            strokeColor: modelData.hasRight ? "#808080" : "transparent"

            startX: offset
            startY: offset

            PathLine {
                x: _handleRight.x + offset
                y: _handleRight.y + offset
            }
        }

        // Left control handle
        Rectangle {
            id: _handleLeft

            visible: modelData.hasLeft

            x: ((modelData.handleLeft.x - modelData.center.x) / 2.0) * _vis.size
            y: -((modelData.handleLeft.y - modelData.center.y) / 2.0) * _vis.size

            width: offset * 2
            height: offset * 2

            color: "#aa0000"

            MouseArea {
                anchors.fill: parent
                preventStealing: true

                onPositionChanged: (evt) => updateHandle(parent, evt, "left")
                onReleased: () => action.redrawElements()
            }
        }

        // Right control handle
        Rectangle {
            id: _handleRight

            visible: modelData.hasRight

            x: ((modelData.handleRight.x - modelData.center.x) / 2.0) * _vis.size
            y: -((modelData.handleRight.y - modelData.center.y) / 2.0) * _vis.size

            width: offset * 2
            height: offset * 2

            color: "#00aa00"

            MouseArea {
                anchors.fill: parent
                preventStealing: true

                onPositionChanged: (evt) => updateHandle(parent, evt, "right")
                onReleased: () => action.redrawElements()
            }
        }
    }

    // Rendering of the control point itself
    MouseArea {
        anchors.fill: parent
        preventStealing: true

        onPositionChanged: (evt) => {
            let coord = updateControlPoint(parent, evt, index)
            if(coord !== null) {
                action.setControlHandle(coord[0], coord[1], index, "center")
            }
        }
        onReleased: () => action.redrawElements()
    }
}