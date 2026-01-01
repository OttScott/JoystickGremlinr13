// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Gremlin.Config
import "helpers.js" as Helpers

JGListView {
    property ConfigGroupModel groupModel

    scrollbarAlwaysVisible: true

    model: groupModel
    delegate: ConfigGroup {}
}
