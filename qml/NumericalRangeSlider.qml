// -*- coding: utf-8; -*-
//
// Copyright (C) 2020 Lionel Ott
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


Item {
    id: _root

    property real from
    property real to
    property real firstValue
    property real secondValue
    property real stepSize
    property int decimals

    height: Math.max(_slider.height, _firstValue.height, _secondValue.height)
    width: _slider.width + _firstValue.width + _secondValue.width


    property var validator: DoubleValidator {
        bottom: Math.min(_root.from, _root.to)
        top:  Math.max(_root.from, _root.to)
    }

    function textFromValue(value) {
        return Number(value).toLocaleString(Qt.locale(), "f", _root.decimals)
    }

    function valueFromText(text) {
            return Number.fromLocaleString(Qt.locale(), text)
    }


    Rectangle {
        id: _firstValue

        anchors.verticalCenter: _slider.verticalCenter

        border.color: "#bdbebf"
        border.width: 2
        width: _firstValueInput.width
        height: _firstValueInput.height

        TextField {
            id: _firstValueInput

            padding: 5
            text: _root.textFromValue(_root.firstValue)

            font: _slider.font
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter

            readOnly: false
            selectByMouse: true
            validator: _root.validator
            inputMethodHints: Qt.ImhFormattedNumbersOnly

            onTextEdited: {
                let value = valueFromText(text)
                if(value >= _root.secondValue)
                {
                    value = _root.secondValue
                }
                _root.firstValue = value
            }
        }
    }


    RangeSlider {
        id: _slider

        anchors.left: _firstValue.right

        from: _root.from
        to: _root.to
        first.value: _root.firstValue
        second.value: _root.secondValue
        stepSize: _root.stepSize

        Component.onCompleted: {
            _root.firstValue = Qt.binding(() => first.value)
            _root.secondValue = Qt.binding(() => second.value)
        }
    }

    Rectangle {
        id: _secondValue

        anchors.left: _slider.right
        anchors.verticalCenter: _slider.verticalCenter

        border.color: "#bdbebf"
        border.width: 2
        width: _secondValueInput.width
        height: _secondValueInput.height

        TextField {
            id: _secondValueInput

            padding: 5
            text: _root.textFromValue(_root.secondValue)

            font: _slider.font
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter

            readOnly: false
            selectByMouse: true
            validator: _root.validator
            inputMethodHints: Qt.ImhFormattedNumbersOnly

            onTextEdited: {
                let value = valueFromText(text)
                if(value <= _root.firstValue)
                {
                    value = _root.firstValue
                }
                _root.secondValue = value
            }
        }
    }

}