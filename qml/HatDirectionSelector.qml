// -*- coding: utf-8; -*-
//
// Copyright (C) 2015 - 2020 Lionel Ott
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


import QtQuick 2.14
import QtQuick.Controls 2.14

import gremlin.ui.profile 1.0


Item {
    id: root

    property VirtualButtonModel virtualButton

    Row {
        id: idCheckboxes

        spacing: 10

        IconCheckBox {
            image: "../gfx/hat_n.png"

            onChecked
        }

        IconCheckBox {
            image: "../gfx/hat_ne.png"
        }

        IconCheckBox {
            image: "../gfx/hat_e.png"
        }

        IconCheckBox {
            image: "../gfx/hat_se.png"
        }

        IconCheckBox {
            image: "../gfx/hat_s.png"
        }

        IconCheckBox {
            image: "../gfx/hat_sw.png"
        }

        IconCheckBox {
            image: "../gfx/hat_w.png"
        }

        IconCheckBox {
            image: "../gfx/hat_nw.png"
        }
    }

}