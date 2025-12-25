// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal


Window {
    id: _root

    minimumWidth: 200
    minimumHeight: 60

    color: Universal.background

    signal accepted(string value)
    property string text : "New text"
    property var validator: function(value) { return true }

    onTextChanged: function() {
        _input.focus = true
    }


    title: "Text Input Field"

    RowLayout {
        anchors.fill: parent

        TextInput {
            id: _input

            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.fillWidth: true

            font.pixelSize: 15
            padding: 4

            text: _root.text

            onTextEdited: function()
            {
                let isValid = _root.validator(text)
                _outline.border.color = isValid ? Universal.accent : "red"
                _button.enabled = isValid
            }

            // Outline for the TextEdit field
            Rectangle {
                id: _outline
                anchors.fill: parent

                border {
                    color: Universal.accent
                    width: 1
                }
                z: -1
            }
        }

        Button {
            id: _button
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            text: "Ok"

            onClicked: function()
            {
                _root.accepted(_input.text)
            }
        }
    }

}
