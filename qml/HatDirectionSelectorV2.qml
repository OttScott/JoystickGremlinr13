// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Gremlin.Profile


Item {
    id: _root

    property HatDirectionModel directions

    implicitHeight: _checkboxes.height
    implicitWidth: _checkboxes.width

    RowLayout {
        id: _checkboxes

        IconCheckBox {
            image: "../gfx/hat_n.png"

            checked: directions.hatNorth
            onCheckedChanged: {
                directions.hatNorth = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_ne.png"

            checked: directions.hatNorthEast
            onCheckedChanged: {
                directions.hatNorthEast = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_e.png"

            checked: directions.hatEast
            onCheckedChanged: {
                directions.hatEast = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_se.png"

            checked: directions.hatSouthEast
            onCheckedChanged: {
                directions.hatSouthEast = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_s.png"

            checked: directions.hatSouth
            onCheckedChanged: {
                directions.hatSouth = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_sw.png"

            checked: directions.hatSouthWest
            onCheckedChanged: {
                directions.hatSouthWest = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_w.png"

            checked: directions.hatWest
            onCheckedChanged: {
                directions.hatWest = checked
            }
        }

        IconCheckBox {
            image: "../gfx/hat_nw.png"

            checked: directions.hatNorthWest
            onCheckedChanged: {
                directions.hatNorthWest = checked
            }
        }
    }
}