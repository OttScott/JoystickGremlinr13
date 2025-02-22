// -*- coding: utf-8; -*-
//
// Copyright (C) 2022 Lionel Ott
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


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Gremlin.Config
import "helpers.js" as Helpers


ListView {
    property ConfigGroupModel groupModel

    spacing: 10
    rightMargin: 30
    bottomMargin: 10

    // Make it behave like a sensible scrolling container
    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AlwaysOn
    }
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds

    model: groupModel
    delegate: ConfigGroup {
        Layout.fillWidth: true
    }
}