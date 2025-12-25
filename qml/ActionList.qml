// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal

import Gremlin.Profile


Item {
    id: idRoot

    property ProfileModel profileModel
//    property InputConfiguration inputConfiguration

//    ColumnLayout {

    RowLayout {
        anchors.fill: parent

        DisplayText {
            text: "Action"
            width: 300
        }
        ComboBox {
//                width: 200
            id: idActionLlist
            model: backend.action_list
//            font.pointSize: 10

//            menu.style.font.pointSize: 36
        }
        Button {
            text: "Add"
            font.pointSize: 10
            //onClicked: backend.add_action(
            //    inputConfiguration
            //    action_list.currentText
            //)
        }
    }

//    }
}