// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Gremlin.Device


Item {
    id: _root

    property string logicalInputType

    property alias currentIndex: _model.currentIndex
    property alias logicalInputIdentifier: _model.currentIdentifier
    property alias validTypes: _model.validTypes

    implicitHeight: _content.height
    implicitWidth: _content.implicitWidth


    LogicalDeviceSelectorModel {
        id: _model
    }

    RowLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        JGComboBox {
            id: _combobox

            Layout.minimumWidth: 200
            Layout.fillWidth: true

            model: _model
            textRole: "label"
            currentIndex: _model.currentIndex

            onActivated: () => {
                if (_model.currentIndex !== currentIndex) {
                    _model.currentIndex = currentIndex
                }
            }
        }
    }

}