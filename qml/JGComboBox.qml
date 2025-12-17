// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

ComboBox {
    id: _combobox

    property bool enableTooltips: true

    delegate: ItemDelegate {
        required property var model
        required property int index

        width: ListView.view.width
        text: model[_combobox.textRole]
        font.weight: _combobox.currentIndex === index ? Font.DemiBold : Font.Normal
        highlighted: _combobox.highlightedIndex === index
        hoverEnabled: _combobox.hoverEnabled

        ToolTip {
            text: parent.text
            // Set an upper width of the tooltip to force word
            // wrap on texts.
            width: contentWidth > 500 ? 500 : contentWidth + 20
            visible: parent.hovered && _combobox.enableTooltips
            delay: 500
        }
    }

    ToolTip {
        text: parent.currentText
        // Set an upper width of the tooltip to force word wrap
        // on long selection names.
        width: contentWidth > 500 ? 500 : contentWidth + 20
        visible: _hoverHandler.hovered && enableTooltips
        delay: 500
    }

    HoverHandler {
        id: _hoverHandler
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}