// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

import Gremlin.Profile

Item {
    id: _root

    property InputItemBindingModel inputBinding
    property InputItemModel inputItemModel
    property MouseArea dragHandleArea: _dragArea

    height: _generalHeader.height + _behaviorAxisButton.height +
        _behaviorHatButton.height
    z: -1

    // Content
    ColumnLayout {
        id: _layout

        anchors.left: parent.left
        anchors.right: parent.right

        // Default header components visible with every input
        RowLayout {
            id: _generalHeader

            IconButton {
                id: _handle

                font.pixelSize: 24
                horizontalPadding: -5
                text: bsi.icons.verticalDrag

                // Drag handle mouse interaction area
                MouseArea {
                    id: _dragArea

                    anchors.fill: parent

                    drag.target: _handle
                    drag.axis: Drag.YAxis
                }
            }

            JGTextField {
                id: _description

                Layout.fillWidth: true

                placeholderText: "Description"
                text: _root.inputBinding.rootAction ?
                    _root.inputBinding.rootAction.actionLabel : "Description"

                onTextEdited: () => {
                    _root.inputBinding.rootAction.actionLabel = text
                }
            }

            InputBehavior {
                id: _behavior

                inputBinding: _root.inputBinding
            }

            ActionSelector {
                Layout.alignment: Qt.AlignRight

                actionNode: _root.inputBinding.rootAction
                callback: (x) => { actionNode.appendAction(x, "children") }
            }

            IconButton {
                id: _headerRemove

                text: bsi.icons.remove
                font.pixelSize: 24

                onClicked: () => {
                    _root.inputItemModel.deleteActionSequnce(_root.inputBinding)
                }
            }
        }

        // UI for a physical axis behaving as a button
        Loader {
            id: _behaviorAxisButton

            active: _root.inputBinding.behavior == "button" &&
                 _root.inputBinding.inputType == "axis"
            onActiveChanged: () => {
                visible: active
                height = active ? item.contentHeight : 0
            }

            sourceComponent: Row {
                spacing: 10

                property int contentHeight: Math.max(
                    _axisLabel.height,
                    _axisRange.height,
                    _axisDirection.height
                )

                Label {
                    id: _axisLabel

                    anchors.verticalCenter: _axisRange.verticalCenter
                    text: "Activate between"
                }
                NumericalRangeSlider {
                    id: _axisRange

                    from: -1.0
                    to: 1.0
                    firstValue: _root.inputBinding.virtualButton.lowerLimit
                    secondValue: _root.inputBinding.virtualButton.upperLimit
                    stepSize: 0.1
                    decimals: 3

                    onFirstValueChanged: () => {
                        _root.inputBinding.virtualButton.lowerLimit = firstValue
                    }
                    onSecondValueChanged: () => {
                        _root.inputBinding.virtualButton.upperLimit = secondValue
                    }
                }
                Label {
                    anchors.verticalCenter: _axisRange.verticalCenter
                    text: "when entered from"
                }
                ComboBox {
                    id: _axisDirection

                    model: ["Anywhere", "Above", "Below"]

                    // Select the correct entry
                    Component.onCompleted: {
                        currentIndex = find(
                            _root.inputBinding.virtualButton.direction,
                            Qt.MatchFixedString
                        )
                    }

                    onActivated: () => {
                        _root.inputBinding.virtualButton.direction = currentText
                    }
                }
            }
        }

        // UI for a physical hat behaving as a button
        Loader {
            id: _behaviorHatButton

            active: _root.inputBinding.behavior == "button" &&
                _root.inputBinding.inputType == "hat"
            onActiveChanged: () => {
                visible: active
                height = active ? item.contentHeight : 0
            }

            sourceComponent: Row {
                property int contentHeight: Math.max(
                    _hatDirection.height,
                    _hatLabel.height
                )

                spacing: 10

                Label {
                    id: _hatLabel
                    anchors.verticalCenter: _hatDirection.verticalCenter
                    text: "Activate on"
                }
                HatDirectionSelector {
                    id: _hatDirection

                    virtualButton: _root.inputBinding.virtualButton
                }
            }
        }
    }
}
