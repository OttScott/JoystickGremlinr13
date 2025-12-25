// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

import Gremlin.Profile


Item {
    id: _root

    property InputItemBindingModel inputBinding

    width: idContent.width
    height: idContent.height

    Row {
        id: idContent

        Loader {
            active: _root.inputBinding.inputType == "button"
            sourceComponent: RadioButton {
                visible: false
            }
        }

        Loader {
            active: _root.inputBinding.inputType != "button"

            sourceComponent: Row {
                Label {
                    id: idBehavior

                    leftPadding: 20
                    text: "Treat as"

                    anchors.verticalCenter: idBehaviorButton.verticalCenter
                }

                RadioButton {
                    id: idBehaviorButton

                    text: "Button"

                    checked: _root.inputBinding.behavior == "button"
                    onClicked: {
                        _root.inputBinding.behavior = "button"
                    }
                }

                Loader {
                    active: _root.inputBinding.inputType == "axis"
                    sourceComponent: RadioButton {
                        id: idBehaviorAxis

                        text: "Axis"

                        checked: _root.inputBinding.behavior == "axis"
                        onClicked: {
                            _root.inputBinding.behavior = "axis"
                        }
                    }
                }
                Loader {
                    active: _root.inputBinding.inputType == "hat"
                    sourceComponent: RadioButton {
                        id: idBehaviorHat

                        text: "Hat"

                        checked: _root.inputBinding.behavior == "hat"
                        onClicked: {
                            _root.inputBinding.behavior = "hat"
                        }
                    }
                }
            }
        }
    }
}