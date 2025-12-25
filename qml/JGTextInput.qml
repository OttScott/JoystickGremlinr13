// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

TextInput {
    padding: 4

    // onTextEdited: function()
    // {
    //     let isValid = _root.validator(text)
    //     _outline.border.color = isValid ? Universal.accent : "red"
    //     _button.enabled = isValid
    // }

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