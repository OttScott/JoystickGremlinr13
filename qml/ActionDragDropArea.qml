// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick


DragDropArea {
    validationCallback: function(drag) {
        return drag.getDataAsString("type") == "action"
    }
}