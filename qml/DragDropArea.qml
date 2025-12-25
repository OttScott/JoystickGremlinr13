// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick


DropArea {
    property var target
    property var dropCallback
    property var validationCallback

    property bool validDrag: false

    x: target.x
    y: target.y + target.height - height
    width: target.width
    height: _dropMarker.height

    // Visualization of the drop indicator
    DropMarker {
        id: _dropMarker
        showMarker: parent.validDrag
    }

    onEntered: function(drag)
    {
        validDrag = validationCallback(drag)
    }

    onExited: function()
    {
        validDrag = false
    }

    onDropped: function(drop)
    {
        drop.accept()
        dropCallback(drop)
    }
}