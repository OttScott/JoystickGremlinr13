// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

import Gremlin.Config
import "helpers.js" as Helpers


ColumnLayout {
    required property int index
    required property string groupName
    required property ConfigEntryModel entryModel

    anchors.left: parent.left
    anchors.right: parent.right

    // Group header
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 50

        UIHeader {
            text: Helpers.capitalize(groupName)
        }
    }

    // Display config entries
    Repeater {
        model: entryModel
        delegate: _entryDelegateChooser
    }

    // Header text component
    component UIHeader : JGText {
        font.pointSize: 14
        font.weight: 500
        font.family: "Segoe UI"
    }

    // Standard text component
    component UIText : JGText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignJustify
        wrapMode: Text.Wrap

        font.pointSize: 11
        font.family: "Segoe UI"
    }

    // Delegate rendering individual configuration option styles
    DelegateChooser {
        id: _entryDelegateChooser
        role: "data_type"

        // On/off options
        DelegateChoice {
            roleValue: "bool"

            RowLayout {
                Layout.fillWidth: true

                Switch {
                    Layout.alignment: Qt.AlignTop
                    checked: value

                    text: checked ? "On" : "Off"

                    onToggled: () => { value = checked }
                }

                UIText {
                    text: description
                }
            }
        }
        // Floating point value inputs
        DelegateChoice {
            roleValue: "float"

            ColumnLayout {
                Layout.fillWidth: true

                UIText {
                    text: description
                }

                FloatSpinBox {
                    value: value
                    minValue: properties.min
                    maxValue: properties.max

                    onValueModified: (newValue) => { value = newValue }
                }
            }
        }
        // Integer value inputs
        DelegateChoice {
            roleValue: "int"

            ColumnLayout {
                Layout.fillWidth: true

                UIText {
                    text: description
                }

                JGSpinBox {
                    value: model.value
                    from: properties.min
                    to: properties.max

                    onValueModified: () => { model.value = value }
                }
            }
        }
        // Textual inputs
        DelegateChoice {
            roleValue: "string"

            ColumnLayout {
                Layout.fillWidth: true

                UIText {
                    text: description
                }

                TextField {
                    text: value

                    Layout.fillWidth: true

                    onTextEdited: () => { value = text }
                }
            }
        }
        // Drop down menu selection
        DelegateChoice {
            roleValue: "selection"

            ColumnLayout {
                Layout.fillWidth: true

                UIText {
                    text: description
                }

                ComboBox {
                    model: properties.valid_options

                    implicitContentWidthPolicy: ComboBox.WidestText

                    Component.onCompleted: () => { currentIndex = find(value) }
                    onActivated: () => { value = currentValue }
                }
            }
        }
        // Meta Option dynamic loading
        DelegateChoice {
            roleValue: "meta_option"

            ColumnLayout {
                Layout.fillWidth: true

                UIText {
                    text: description
                }

                DynamicItemLoader {
                    qmlPath: value

                    Layout.fillWidth: true

                    onLoadError: (src, err) => {
                        console.warn("Meta option load error:", src, err)
                    }
                }

            }
        }

    }
}