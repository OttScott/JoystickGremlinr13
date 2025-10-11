// -*- coding: utf-8; -*-
//
// Copyright (C) 2025 Lionel Ott
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


ListView {
    property bool scrollbarAlwaysVisible: false

    // Prevent content being shown outside the widget's bounds.
    clip: true

    // Scrollbar visibility behavior as configured.
    ScrollBar.vertical: ScrollBar {
        policy: scrollbarAlwaysVisible ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
    }
    // Disable mobile device scrolling behaviors.
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
}