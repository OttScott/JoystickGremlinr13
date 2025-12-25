// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import QtQuick.Controls.Universal

import Gremlin.Profile
import Gremlin.UI
import Gremlin.ActionPlugins
import "../../qml"


Item {
    id: _root

    property MergeAxisModel action

    property LabelValueSelectionModel actionModel: action.mergeActionList
    property LabelValueSelectionModel operationModel: action.operationList

    implicitHeight: _content.height

    Connections {
        target: action

        function onModelChanged()
        {
            actionModel.currentValue = _root.action.mergeAction
            operationModel.currentValue = _root.action.operation
        }
    }

    // Dialog to change the label of the current action
    Dialog {
        id: _dialog

        anchors.centerIn: Overlay.overlay

        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        focus: true

        title: "Rename action"

        Row
        {
            anchors.fill: parent

            TextField {
                id: _action_label

                width: 400
                focus: true

                text: action.label
                placeholderText: "Action label"

                onAccepted: function()
                {
                    _dialog.accept()
                }
            }
        }

        onAccepted: function()
        {
            action.label = _action_label.text
        }
    }

    ColumnLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right


        // +-------------------------------------------------------------------
        // | Merge axis instance selection and management
        // +-------------------------------------------------------------------
        RowLayout {
            Label {
                text: "Merge axis instance"
            }
            LabelValueComboBox {
                id: _action_selection

                model: _root.actionModel

                Component.onCompleted: function() {
                    _root.actionModel.currentValue = _root.action.mergeAction
                }

                onSelectionChanged: function() {
                    _root.action.mergeAction = _root.actionModel.currentValue
                }
            }

            Row {
                IconButton {
                    text: bsi.icons.add_new
                    font.pixelSize: 24

                    onClicked: () => _root.action.newMergeAxis()
                }

                IconButton {
                    text: bsi.icons.rename
                    font.pixelSize: 24

                    onClicked: () => _dialog.open()
                }
            }
        }

        LayoutHorizontalSpacer {}

        RowLayout {
            Label {
                text: "Merge operation"
            }
            LabelValueComboBox {
                id: _operation_selection

                model: _root.operationModel

                Component.onCompleted: function() {
                    _root.operationModel.currentValue = _root.action.operation
                }

                onSelectionChanged: function() {
                    _root.action.operation = _root.operationModel.currentValue
                }
            }
        }

        // +-------------------------------------------------------------------
        // | Axis assignments
        // +-------------------------------------------------------------------
        RowLayout {
            // First axis
            Label {
                text: "First axis"
                font.family: "Segoe UI"
                font.weight: 600
            }
            Label {
                text: _root.action.firstAxis.label
            }
            IconButton {
                text: bsi.icons.replace

                onClicked: function() {
                    _root.action.firstAxis = uiState.currentInput
                }
            }

            LayoutHorizontalSpacer {
                Layout.fillWidth: false
                Layout.preferredWidth: 50
            }

            // Second axis selection
            Label {
                text: "Second axis"
                font.family: "Segoe UI"
                font.weight: 600
            }
            Label {
                text: _root.action.secondAxis.label
            }
            IconButton {
                text: bsi.icons.replace

                onClicked: function() {
                    _root.action.secondAxis = uiState.currentInput
                }
            }
        }

        // +-------------------------------------------------------------------
        // | Child action selection
        // +-------------------------------------------------------------------
        RowLayout {
            Label {
                text: "Actions"
            }

            Rectangle {
                Layout.fillWidth: true
            }

            ActionSelector {
                actionNode: _root.action
                callback:  (x) => _root.action.appendAction(x, "children")
            }
        }

        Rectangle {
            id: _childActionDivider
            Layout.fillWidth: true
            height: 2
            color: Universal.baseLowColor
        }

        // Display the actions operating on the merged axis output
        Repeater {
            model: _root.action.getActions("children")

            delegate: ActionNode {
                action: modelData
                parentAction: _root.action
                containerName: "children"

                Layout.fillWidth: true
            }
        }
    }

    // Drop action for insertion into empty/first slot of the short actions
    ActionDragDropArea {
        target: _childActionDivider
        dropCallback: function(drop) {
            modelData.dropAction(drop.text, modelData.sequenceIndex, "children");
        }
    }
}
