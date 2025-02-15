// -*- coding: utf-8; -*-
//
// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only
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

// Implements a ComboBox that is usable with a mouse by virtue of scrolling
// at an acceptable speed. The amount of scrolling can be adjusted via the
// exposed scrollStep property.


import QtQuick
import QtQuick.Window
import QtQuick.Controls.impl
import QtQuick.Templates as T
import QtQuick.Controls.Universal


ComboBox {
    id: control

    property int scrollStep: 7

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)

    Universal.theme: editable && activeFocus ? Universal.Light : undefined

    popup: T.Popup {
        width: control.width
        height: Math.min(contentItem.implicitHeight, control.Window.height - topMargin - bottomMargin)
        topMargin: 8
        bottomMargin: 8

        Universal.theme: control.Universal.theme
        Universal.accent: control.Universal.accent

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
            }

            MouseArea {
                anchors.fill: parent

                onPressed: (mouse) => mouse.accepted = false
                onReleased: (mouse) => mouse.accepted = false

                onWheel: (wheel) => {
                    if(wheel.angleDelta.y > 0) {
                        parent.positionViewAtIndex(
                            parent.currentIndex - control.scrollStep,
                            ListView.Center
                        )
                    } else {
                        parent.positionViewAtIndex(
                            parent.currentIndex + control.scrollStep,
                            ListView.Center
                        )
                    }
                }
            }
        }

        background: Rectangle {
            color: control.Universal.chromeMediumLowColor
            border.color: control.Universal.chromeHighColor
            border.width: 1
        }
    }
}