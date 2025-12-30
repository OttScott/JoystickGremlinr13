// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

import Gremlin.Style

TabButton {
    font.pixelSize: 14
    font.weight: 600

    background: Rectangle {
        color: parent.checked ? Style.accent : Style.background
    }
}
