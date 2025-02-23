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
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal

import Gremlin.Profile
import Gremlin.ActionPlugins
import "../../qml"


Item {
    property HatButtonsModel action

    implicitHeight: _content.height

    ColumnLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
            Label {
                text: "Button mode"
            }
            RadioButton {
                text: "4 way"
                checked: _root.action.buttonCount == 4

                onClicked: {
                    _root.action.buttonCount = 4
                }
            }
            RadioButton {
                text: "8 way"
                checked: _root.action.buttonCount == 8

                onClicked: {
                    _root.action.buttonCount = 8
                }
            }
        }

        Repeater {
            model: _root.action.buttonCount

            delegate: ButtonContainer {}
        }
    }

    component ButtonContainer : ColumnLayout {
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: _root.action.buttonName(index)
            }

            LayoutHorizontalSpacer {}

            ActionSelector {
                actionNode: _root.action
                callback: function(x) {
                    _root.action.appendAction(x, _root.action.buttonName(index));
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: Universal.baseLowColor
        }

        ListView {
            id: _buttonSequence

            model: _root.action.getActions(_root.action.buttonName(index))

            Layout.fillWidth: true
            implicitHeight: contentHeight

            delegate: ActionNode {
                action: modelData
                parentAction: _root.action
                containerName: _root.action.buttonName(index)

                width: _buttonSequence.width
            }
        }
    }
}