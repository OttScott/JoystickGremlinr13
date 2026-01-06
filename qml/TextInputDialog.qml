// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window

import Gremlin.Style

Window {
    id: _root

    minimumWidth: 200
    minimumHeight: 60

    color: Style.background
    Universal.theme: Style.theme

    signal accepted(string value)
    property string text : "New text"
    property var validator: function(value) { return true }

    onTextChanged: () =>  { _input.focus = true }

    title: "Text Input Field"

    RowLayout {
        anchors.fill: parent

        JGTextField {
            id: _input

            Layout.fillWidth: true
            Layout.leftMargin: 5

            text: _root.text

            onTextEdited: () => {
                let isValid = _root.validator(text)
                _input.outlineOverride = isValid ? null : Style.error
                _button.enabled = isValid
            }
        }

        Button {
            id: _button

            Layout.rightMargin: 10

            text: "Ok"

            onClicked: () => { _root.accepted(_input.text) }
        }
    }

}
