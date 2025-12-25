// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


AbstractButton {
    id: _root

    // property alias text: _label.text
    // property bool selected: true
    // signal activated

    // implicitHeight: _container.implicitHeight

    // Rectangle {
    //     implicitHeight: _container.implicitHeight
    //     implicitWidth: parent.width

    //     color: selected ? Universal.chromeMediumColor : Universal.background

    //     RowLayout {
    //         id: _container

    //         Rectangle {
    //             width: 5

    //             Layout.fillHeight: true
    //             Layout.topMargin: 10
    //             Layout.bottomMargin: 10

    //             color: selected ? Universal.accent : Universal.background
    //         }

    //         Label {
    //             id: _label

    //             Layout.fillWidth: true
    //             Layout.topMargin: 10
    //             Layout.bottomMargin: 10
    //         }
    //     }

    //     MouseArea {
    //         anchors.fill: parent

    //         onClicked: function() {
    //             _root.activated()
    //         }
    //     }


        background: Rectangle {
            implicitWidth: 550
            implicitHeight: 66
            opacity: enabled ? 1 : 0.3
            border.color: controlBt.down ? "#17a81a" : "#21be2b"
            border.width: 1
            radius: 2
        }
    }



}
