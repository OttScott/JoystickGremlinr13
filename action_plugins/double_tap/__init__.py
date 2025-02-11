# -*- coding: utf-8; -*-

# Copyright (C) 2015 - 2025 Lionel Ott
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


from __future__ import annotations

import copy
import logging
import threading
import time
from typing import Any, List, Optional, TYPE_CHECKING
from xml.etree import ElementTree

from PySide6 import QtCore
from PySide6.QtCore import Property, Signal, Slot

from gremlin import event_handler, fsm, util
from gremlin.error import GremlinError, ProfileError
from gremlin.base_classes import AbstractActionData, AbstractFunctor, Value
from gremlin.config import Configuration
from gremlin.profile import Library
from gremlin.tree import TreeNode
from gremlin.types import ActionProperty, InputType, PropertyType, DataCreationMode

from gremlin.ui.action_model import SequenceIndex, ActionModel

if TYPE_CHECKING:
    from gremlin.ui.profile import InputItemBindingModel


class DoubleTapFunctor(AbstractFunctor):

    def __init__(self, action: DoubleTapData):
        super().__init__(action)

        self.timer = None
        self.value_press = None
        self.event_press = None
        self.fsm = self._create_fsm()

    def __call__(self, event: event_handler.Event, value: Value) -> None:
        # TODO: Currently this does not handle hat or axis events, however
        #       virtual buttons created on those inputs is supported
        if not isinstance(value.current, bool):
            logging.getLogger("system").warning(
                f"Invalid data type received in DoubleTap action: {event.value}"
            )
            return

        # Copy state when input is pressed
        if value.current:
            self.value_press = copy.deepcopy(value)
            self.event_press = event.clone()

        self.fsm.perform("press" if value.current else "release", event, value)

    def _create_fsm(self):
        states = ["neutral", "p1", "p1+t", "p2+t", "t"]
        actions = ["press", "release", "timeout"]
        if self.data.activate_on == "exclusive":
            transitions = {
                ("neutral", "press"): fsm.Transition(
                    [self._timer_start], "p1+t"
                ),
                ("neutral", "timeout"): fsm.Transition([self._noop], "neutral"),
                ("p1+t", "release"): fsm.Transition([self._noop], "t"),
                ("p1+t", "timeout"): fsm.Transition([self._single_press], "p1"),
                ("p1", "release"): fsm.Transition(
                    [self._single_release], "neutral"
                ),
                ("t", "press"): fsm.Transition([self._double_press], "p2+t"),
                ("t", "timeout"): fsm.Transition(
                    [self._single_pulse], "neutral"
                ),
                ("p2+t", "release"): fsm.Transition(
                    [self._double_release], "neutral"
                ),
                ("p2+t", "timeout"): fsm.Transition([self._noop], "p2+t")
            }
        elif self.data.activate_on == "combined":
            transitions = {
                ("neutral", "press"): fsm.Transition(
                    [self._single_press, self._timer_start], "p1+t"
                ),
                ("neutral", "timeout"): fsm.Transition([self._noop], "neutral"),
                ("p1+t", "release"): fsm.Transition([self._single_release], "t"),
                ("p1+t", "timeout"): fsm.Transition([self._noop], "p1"),
                ("p1", "release"): fsm.Transition(
                    [self._single_release], "neutral"
                ),
                ("t", "press"): fsm.Transition(
                    [self._single_press, self._double_press], "p2+t"
                ),
                ("t", "timeout"): fsm.Transition([self._noop], "neutral"),
                ("p2+t", "release"): fsm.Transition(
                    [self._single_release, self._double_release], "neutral"
                ),
                ("p2+t", "timeout"): fsm.Transition([self._noop], "p2+t")
            }
        return fsm.FiniteStateMachine("neutral", states, actions, transitions)

    def _timeout(self) -> None:
        self.fsm.perform("timeout", self.event_press, self.value_press)

    def _single_press(self, event: event_handler.Event, value: Value) -> None:
        self._process_event(
            self.functors["single"], self.event_press, self.value_press
        )

    def _single_release(self, event: event_handler.Event, value: Value) -> None:
        self._process_event(self.functors["single"], event, value)

    def _single_pulse(self, event: event_handler.Event, value: Value) -> None:
        self._process_event(
            self.functors["single"], self.event_press, self.value_press
        )
        time.sleep(0.05)
        value_release = Value(False)
        event_release = event.clone()
        event_release.is_pressed = False
        event_release.raw_value = False
        self._process_event(self.functors["single"], event_release, value_release)

    def _double_press(self, event: event_handler.Event, value: Value) -> None:
        self._process_event(self.functors["double"], event, value)

    def _double_release(self, event: event_handler.Event, value: Value) -> None:
        self._process_event(self.functors["double"], event, value)

    def _timer_start(self, event: event_handler.Event, value: Value) -> None:
        if self.timer:
            self.timer.cancel()
        self.timer = threading.Timer(self.data.threshold, self._timeout)
        self.timer.start()

    def _noop(self, event: event_handler.Event, value: Value) -> None:
        pass


class DoubleTapModel(ActionModel):

    actionsChanged = Signal()
    activateOnChanged = Signal()
    thresholdChanged = Signal()

    def __init__(
            self,
            data: AbstractActionData,
            binding_model: InputItemBindingModel,
            action_index: SequenceIndex,
            parent_index: SequenceIndex,
            parent: QtCore.QObject
    ):
        super().__init__(data, binding_model, action_index, parent_index, parent)

    def _qml_path_impl(self) -> str:
        return "file:///" + QtCore.QFile(
            "core_plugins:double_Tap/DoubleTapAction.qml"
        ).fileName()

    def _add_action_impl(self, action: AbstractActionData, options: Any) -> None:
        """Adds a new action to one of the two condition branches.

        Args:
            action: the action to add
            options: which of the two activation types to add the action two, valid
                options are [short, long]
        """
        predicate = lambda x: True if x.value and x.value.id == self.id else False
        nodes = self._action_tree.root.nodes_matching(predicate)
        if len(nodes) != 1:
            raise GremlinError(f"Node with ID {self.id} has invalid state")
        nodes[0].add_child(TreeNode(action))
        if options == "single":
            self._single_action_ids.append(action.id)
        elif options == "double":
            self._double_action_ids.append(action.id)
        else:
            raise GremlinError(f"Invalid branch specification: {options}")

        self.actionsChanged.emit()

    def _set_threshold(self, value: float) -> None:
        if self._data.threshold != value:
            self._data.threshold = value
            self.thresholdChanged.emit()

    @Property(float, fset=_set_threshold, notify=thresholdChanged)
    def threshold(self) -> float:
        return self._data.threshold

    def _set_activate_on(self, value: str) -> None:
        if value not in ["exclusive", "combined"]:
            raise GremlinError(f"Received invalid activateOn value {value}")

        if self._data.activate_on != value:
            self._data.activate_on = value
            self.activateOnChanged.emit()

    @Property(str, fset=_set_activate_on, notify=activateOnChanged)
    def activateOn(self) -> str:
        return self._data.activate_on


class DoubleTapData(AbstractActionData):

    """A container with two actions which are triggered based on whether the
    input is pressed once or twice in quick succession.

    A short press will run the fist action while a double press will run the
    second action.
    """

    version = 1
    name = "Double Tap"
    tag = "double-tap"
    icon = "\uF26F"

    functor = DoubleTapFunctor
    model = DoubleTapModel

    properties = [
        ActionProperty.ActivateDisabled
    ]
    input_types = [
        InputType.JoystickButton,
        InputType.Keyboard
    ]

    def __init__(self, behavior_type: InputType=InputType.JoystickButton):
        super().__init__(behavior_type)

        self.single_actions = []
        self.double_actions = []
        self.threshold = Configuration().value("action", "double-tap", "duration")
        self.activate_on = "exclusive"

    def _from_xml(self, node: ElementTree.Element, library: Library) -> None:
        self._id = util.read_action_id(node)
        short_ids = util.read_action_ids(node.find("single-actions"))
        self.single_actions = [library.get_action(aid) for aid in short_ids]
        long_ids = util.read_action_ids(node.find("double-actions"))
        self.double_actions = [library.get_action(aid) for aid in long_ids]
        self.threshold = util.read_property(
            node, "threshold", PropertyType.Float
        )
        self.activate_on = util.read_property(
            node, "activate-on", PropertyType.String
        )
        if self.activate_on not in ["exclusive", "combined"]:
            raise ProfileError(
                f"Invalid activat-on value present: {self.activate_on}"
            )

    def _to_xml(self) -> ElementTree.Element:
        """Returns an XML node representing this container's data.

        :return XML node representing the data of this container
        """
        node = util.create_action_node(DoubleTapData.tag, self._id)
        node.append(util.create_action_ids(
            "single-actions", [action.id for action in self.single_actions]
        ))
        node.append(util.create_action_ids(
            "double-actions", [action.id for action in self.double_actions]
        ))
        node.append(util.create_property_node(
            "threshold", self.threshold, PropertyType.Float
        ))
        node.append(util.create_property_node(
            "activate-on", self.activate_on, PropertyType.String
        ))

        return node

    def is_valid(self) -> bool:
        return True

    def _valid_selectors(self) -> List[str]:
        return ["single", "double"]

    def _get_container(
            self,
            selector: Optional[str] = None
    ) -> List[AbstractActionData]:
        if selector == "single":
            return self.single_actions
        elif selector == "double":
            return self.double_actions

    def _handle_behavior_change(
        self,
        old_behavior: InputType,
        new_behavior: InputType
    ) -> None:
        pass


create = DoubleTapData

Configuration().register(
    "action",
    "double-tap",
    "duration",
    PropertyType.Float,
    0.5,
    "Default time before triggering the long press action.",
    {
        "min": 0.0,
        "max": 10.0
    },
    True
)