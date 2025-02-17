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

import Gremlin.ActionPlugins
import Gremlin.Profile
import "../../qml"


Item {
    id: _root

    property SmartToggleModel action

    implicitHeight: _content.height

    // Show all child nodes
    ColumnLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
            Label {
                text: "Toggle delay"
            }
            FloatSpinBox {
                minValue: 0
                maxValue: 100
                realValue: _root.action.delay
                stepSize: 0.05

                onRealValueModified: function() {
                    _root.action.delay = realValue
                }
            }

            LayoutSpacer {}

            ActionSelector {
                actionNode: _root.action
                callback: function(x) { _root.action.appendAction(x, "children"); }
            }
        }

        Repeater {
            model: _root.action.getActions("children")

            delegate: ActionNode {
                action: modelData
                parentAction: _root.action
                containerName: "children"

                Layout.fillWidth: true
            }
        }
    }
}