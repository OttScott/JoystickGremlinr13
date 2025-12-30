// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Shapes


Shape {
    id: _shape

    property alias color: _path.fillColor

    ShapePath {
        id: _path

        startX: 0
        startY: _shape.height

        strokeColor: "transparent"

        PathLine { x: _shape.width/2; y: 0 }
        PathLine { x: _shape.width; y: _shape.height }
        PathLine { x: 0; y: _shape.height }
    }
}
