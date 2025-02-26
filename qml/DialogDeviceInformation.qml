// -*- coding: utf-8; -*-
//
// Copyright (C) 2019 Lionel Ott
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

import Gremlin.Device


Window {
    minimumWidth: 1000
    minimumHeight: 300

    color: Universal.background
    title: "Device Information"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        anchors.rightMargin: 0

        RowLayout {
            Layout.preferredHeight: 50

            HeaderText {
                text: "Name"
                Layout.fillWidth: true
            }
            HeaderText {
                text: "Axes"
                Layout.preferredWidth: 50
            }
            HeaderText {
                text: "Buttons"
                Layout.preferredWidth: 75
            }
            HeaderText {
                text: "Hats"
                Layout.preferredWidth: 50
            }
            HeaderText {
                text: "VID"
                Layout.preferredWidth: 100
            }
            HeaderText {
                text: "PID"
                Layout.preferredWidth: 100
            }
            HeaderText {
                text: "Joystick ID"
                Layout.preferredWidth: 100
            }
            HeaderText {
                text: "Device GUID"
                Layout.preferredWidth: 320
            }
        }

        ScrollView {
            id: _view
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                spacing: 0

                Repeater {
                    model: DeviceListModel {}

                    delegate: Rectangle {
                        id: _outer

                        height: 40
                        width: _view.width

                        color: index % 2 === 0 ? "#C0C0C0" : Universal.background

                        RowLayout {
                            width: parent.width

                            TextEntry {
                                text: name
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft

                            }
                            TextEntry {
                                text: axes
                                Layout.preferredWidth: 50
                            }
                            TextEntry {
                                text: buttons
                                Layout.preferredWidth: 75
                            }
                            TextEntry {
                                text: hats
                                Layout.preferredWidth: 50
                            }
                            TextEntry {
                                text: vid
                                Layout.preferredWidth: 100
                            }
                            TextEntry {
                                text: pid
                                Layout.preferredWidth: 100
                            }
                            TextEntry {
                                text: joy_id
                                Layout.preferredWidth: 100
                            }
                            TextField {
                                text: guid
                                Layout.preferredWidth: 320
                                Layout.rightMargin: 10

                                readOnly: true
                                horizontalAlignment: Text.AlignHCenter

                                background: Rectangle {
                                    anchors.fill: parent
                                    color: _outer.color
                                    border.width: 1
                                    border.color: Universal.baseLowColor
                                    opacity: 1.0
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component TextEntry : Text {
        Layout.preferredHeight: 40

        color: Universal.foreground
        elide: Text.ElideRight

        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        rightPadding: 10
    }

    component HeaderText : Text {
        Layout.preferredHeight: 40

        color: Universal.foreground
        font.weight: 600

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
