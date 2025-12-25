// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal

import Gremlin.Profile
import Gremlin.ActionPlugins
import "../../qml"


Item {
    property DescriptionModel action

    implicitHeight: _content.height

    RowLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right

        Label {
            id: _label

            Layout.preferredWidth: 150

            text: "Description"
        }

        TextField {
            id: _description

            Layout.fillWidth: true

            placeholderText: null != action ? null : "Enter description"
            text: action.description
            selectByMouse: true

            onTextChanged: {
                action.description = text
            }
        }
    }
}
