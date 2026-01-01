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
    anchors.rightMargin: 20

    JGText {
        Layout.fillWidth: true
        Layout.preferredHeight: 50

        text: Helpers.capitalize(groupName)

        font.pointSize: 16
        font.weight: 500
        font.family: "Segoe UI"
        verticalAlignment: Text.AlignBottom
    }

    Repeater {
        model: entryModel

        delegate: _entryDelegateChooser
    }

    LayoutVerticalSpacer {
        Layout.preferredHeight: 5
    }

    // Delegate rendering individual configuration option styles.
    DelegateChooser {
        id: _entryDelegateChooser
        role: "data_type"

        // On/off options.
        DelegateChoice {
            roleValue: "bool"

            OptionEntryCard {
                Layout.fillWidth: true

                title: name
                explanation: description

                Switch {
                    Layout.alignment: Qt.AlignRight

                    checked: value

                    text: checked ? "On" : "Off"

                    onToggled: () => { value = checked }
                }
            }
        }
        // Floating point value inputs.
        DelegateChoice {
            roleValue: "float"

            OptionEntryCard {
                Layout.fillWidth: true

                title: name
                explanation: description

                FloatSpinBox {
                    Layout.alignment: Qt.AlignRight

                    value: value
                    minValue: properties.min
                    maxValue: properties.max

                    onValueModified: (newValue) => { value = newValue }
                }
            }
        }
        // Integer value inputs.
        DelegateChoice {
            roleValue: "int"

            OptionEntryCard {
                Layout.fillWidth: true

                title: name
                explanation: description

                JGSpinBox {
                    Layout.alignment: Qt.AlignRight

                    value: model.value
                    from: properties.min
                    to: properties.max

                    onValueModified: () => { model.value = value }
                }
            }
        }
        // Textual inputs.
        DelegateChoice {
            roleValue: "string"

            OptionEntryCard {
                Layout.fillWidth: true

                title: name
                explanation: description

                JGTextField {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true

                    text: value

                    onTextEdited: () => { value = text }

                    ToolTip {
                        text: parent.text

                        width: contentWidth > 500 ? 500 : contentWidth + 20

                        visible: parent.hovered
                        delay: 500
                    }
                }
            }
        }
        // Drop down menu selection.
        DelegateChoice {
            roleValue: "selection"

            OptionEntryCard {
                Layout.fillWidth: true

                title: name
                explanation: description

                ComboBox {
                    Layout.alignment: Qt.AlignRight

                    model: properties.valid_options

                    implicitContentWidthPolicy: ComboBox.WidestText

                    Component.onCompleted: () => { currentIndex = find(value) }
                    onActivated: () => { value = currentValue }
                }
            }
        }
        // Meta Option dynamic loading.
        DelegateChoice {
            roleValue: "meta_option"

            OptionEntryCard {
                Layout.fillWidth: true

                title: name
                explanation: description

                DynamicItemLoader {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true

                    qmlPath: value

                    onLoadError: (err) => {
                        console.warn("Meta option load error:", err)
                    }
                }
            }
        }
    }

}
