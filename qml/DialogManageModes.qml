// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal

import Gremlin.Profile


Window {
    id: _root

    minimumWidth: 900
    minimumHeight: 500

    title: "Manage Modes"

    property ModeHierarchyModel modeHierarchy : ModeHierarchyModel {}
    property ModeListModel modeList : ModeListModel {}

    TextInputDialog {
        id: _textInput

        visible: false
        width: 500

        property var callback: null

        onAccepted: function(value)
        {
            callback(value)
            visible = false
        }
    }

    ColumnLayout {
        id: _content

        anchors.fill: parent

        JGListView  {
            Layout.fillWidth: true
            Layout.fillHeight: true

            scrollbarAlwaysVisible: true
            spacing: 10

            model: modeList
            delegate: _delegate
        }

        Button {
            Layout.alignment: Qt.AlignHCenter

            text: "Add Mode"

            onClicked: function()
            {
                let validNames = modeHierarchy.modeStringList()

                _textInput.title = "Add new mode"
                _textInput.text = "New mode"
                _textInput.validator = function(value)
                {
                    return !validNames.includes(value)
                }
                _textInput.callback = function(name) {
                    modeHierarchy.newMode(name)
                }
                _textInput.visible = true
            }
        }
    }

    Component {
        id: _delegate

        RowLayout {
            required property string name
            required property string parentName

            width: ListView.view.width
            height: _parentMode.height

            TextInput {
                Layout.fillWidth: true
                Layout.leftMargin: 10

                font.pixelSize: 15
                padding: 4

                text: name
            }

            IconButton {
                text: bsi.icons.edit

                Layout.leftMargin: 10

                onClicked: function()
                {
                    let validNames = modeHierarchy.validParents(name)

                    _textInput.text = name
                    _textInput.callback = function(value)
                    {
                        modeHierarchy.renameMode(name, value)
                    }
                    _textInput.validator = function(value)
                    {
                        return !validNames.includes(value)
                    }
                    _textInput.visible = true
                }
            }

            ComboBox {
                id: _parentMode

                Layout.preferredWidth: 200
                Layout.leftMargin: 10
                Layout.rightMargin: 10

                model: modeHierarchy.validParents(name)

                textRole: "value"
                valueRole: "value"

                onActivated: function(index)
                {
                    modeHierarchy.setParent(name, currentValue)
                }

                Component.onCompleted: function()
                {
                    currentIndex = indexOfValue(parentName)
                }
            }

            IconButton {
                text: bsi.icons.trash

                Layout.rightMargin: 10

                onClicked: function()
                {
                    modeHierarchy.deleteMode(name)
                }
            }
        }
    }
}