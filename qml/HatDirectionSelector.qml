// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

import Gremlin.Profile


Item {
    id: _root

    property VirtualButtonModel virtualButton

    implicitHeight: _checkboxes.height
    implicitWidth: _checkboxes.width

    Row {
        id: _checkboxes

        spacing: 10

        IconCheckBox {
            image: "../gfx/hat_n.png"

            checked: virtualButton.hatNorth
            onCheckedChanged: {
                virtualButton.hatNorth = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_ne.png"

            checked: virtualButton.hatNorthEast
            onCheckedChanged: {
                virtualButton.hatNorthEast = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_e.png"

            checked: virtualButton.hatEast
            onCheckedChanged: {
                virtualButton.hatEast = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_se.png"

            checked: virtualButton.hatSouthEast
            onCheckedChanged: {
                virtualButton.hatSouthEast = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_s.png"

            checked: virtualButton.hatSouth
            onCheckedChanged: {
                virtualButton.hatSouth = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_sw.png"

            checked: virtualButton.hatSouthWest
            onCheckedChanged: {
                virtualButton.hatSouthWest = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_w.png"

            checked: virtualButton.hatWest
            onCheckedChanged: {
                virtualButton.hatWest = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_nw.png"

            checked: virtualButton.hatNorthWest
            onCheckedChanged: {
                virtualButton.hatNorthWest = checked
            }
        }
    }
}