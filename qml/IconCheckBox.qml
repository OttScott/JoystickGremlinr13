// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls


Item {
    id: root

    property string image
    property alias checked : _checkbox.checked

    width: _checkbox.width + _image.width
    height: _checkbox.height

    CheckBox {
        id: _checkbox

        contentItem: Image {
            id: _image

            source: image
            fillMode: Image.PreserveAspectFit
            transform: Translate{
                x: _checkbox.indicator.implicitWidth
            }
        }
    }
}