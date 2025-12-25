// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick


Rectangle {
    property var target

    x: target.x
    y: target.y
    width: Math.max(target.implicitWidth, target.width)
    height: Math.max(target.implicitHeight, target.height)

    color: "green"
    opacity: 0.5
}