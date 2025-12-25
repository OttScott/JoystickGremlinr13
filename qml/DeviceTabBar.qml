// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Universal

T.TabBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    contentItem: ListView {
        model: control.contentModel
        currentIndex: control.currentIndex

        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        snapMode: ListView.SnapToItem

        ScrollBar.horizontal: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        highlightMoveDuration: 100
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: 48
        preferredHighlightEnd: width - 48


        MouseArea {
            anchors.fill: parent

            // Scroll the view without the need for a modifier.
            onWheel: function(evt) {
                if(parent.contentWidth < parent.width) {
                    return
                }

                if (evt.angleDelta.y > 0) {
                    parent.contentX = Math.max(0, parent.contentX - 10)
                } else {
                    parent.contentX = Math.min(
                        parent.contentWidth - parent.width,
                        parent.contentX + 10
                    )
                }
            }

            // Ignore all other events and thus pass then  to the
            // underlying ListView.
            onClicked: (mouse) => mouse.accepted = false
            onPressed: (mouse) => mouse.accepted = false
            onReleased: (mouse) => mouse.accepted = false
            onDoubleClicked: (mouse) => mouse.accepted = false
            onPositionChanged: (mouse) => mouse.accepted = false
            onPressAndHold: (mouse) => mouse.accepted = false
        }
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 48
        color: control.Universal.background
    }
}