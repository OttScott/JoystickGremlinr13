# -*- coding: utf-8; -*-

# Copyright (C) 2015 - 2024 Lionel Ott
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

from abc import ABC, abstractmethod
import collections
import functools
import logging
import time
from threading import Event, Lock, Thread
import uuid
from xml.etree import ElementTree

from win32security import POLICY_READ

import gremlin
from gremlin import mode_manager, util
from gremlin.base_classes import AbstractActionData
from gremlin.common import SingletonDecorator
from gremlin.keyboard import send_key_down, send_key_up, key_from_name, Key
from gremlin.types import AxisMode, InputType, MouseButton, PropertyType

MacroEntry = collections.namedtuple(
    "MacroEntry",
    ["macro", "state"]
)


@SingletonDecorator
class MacroManager:

    """Manages the proper dispatching and scheduling of macros."""

    def __init__(self):
        """Initializes the instance."""
        self._active = {}
        self._queue = []
        self._flags = {}
        self._flags_lock = Lock()
        self._queue_lock = Lock()

        # Default delay between subsequent message dispatch. This is to get
        # around some games not picking up messages if they are sent in too
        # quick a succession.
        self.default_delay = 0.05

        self._is_executing_exclusive = False
        self._is_running = False
        self._schedule_event = Event()

        self._run_scheduler_thread = None

    def start(self) -> None:
        """Starts the scheduler."""
        self._active = {}
        self._flags = {}
        self._is_running = True
        if self._run_scheduler_thread is None:
            self._run_scheduler_thread = Thread(target=self._run_scheduler)
        if not self._run_scheduler_thread.is_alive():
            self._run_scheduler_thread.start()

    def stop(self) -> None:
        """Stops the scheduler."""
        self._is_running = False
        if self._run_scheduler_thread is not None and \
                self._run_scheduler_thread.is_alive():

            # Terminate the scheduler
            self._schedule_event.set()
            self._run_scheduler_thread.join()
            self._run_scheduler_thread = None

            # Terminate any macro that is still active
            with self._flags_lock:
                for key in self._flags:
                    self._flags[key] = False

    def queue_macro(self, macro: Macro) -> None:
        """Queues a macro in the schedule taking the repeat type into account.

        Args:
            macro: the macro to add to the scheduler
        """
        if isinstance(macro.repeat, ToggleRepeat) and macro.id in self._active:
            self.terminate_macro(macro)
        else:
            # Preprocess macro to contain pauses as necessary
            self._preprocess_macro(macro)
            with self._queue_lock:
                self._queue.append(MacroEntry(macro, True))
            self._schedule_event.set()

    def terminate_macro(self, macro: Macro) -> None:
        """Adds a termination request for a macro to the execution queue.

        Args:
            macro: the macro to terminate
        """
        self._queue.append(MacroEntry(macro, False))
        self._schedule_event.set()

    def _run_scheduler(self) -> None:
        """Dispatches macros as required."""
        while self._is_running:
            # Wake up when the event triggers and reset it
            self._schedule_event.wait()
            self._schedule_event.clear()

            # Run scheduled macros and ensure exclusive ones run separately
            # from all other macros
            with self._queue_lock:
                entries_to_remove = []
                has_exclusive = False
                for entry in self._queue:
                    # Terminate macro if needed
                    if entry.state is False:
                        if entry.macro.id in self._flags \
                                and self._flags[entry.macro.id]:
                            # Terminate currently running macro
                            with self._flags_lock:
                                self._flags[entry.macro.id] = False

                            # Remove all queued up macros with the same id as
                            # they should have been impossible to queue up
                            # in the first place
                            removal_list = []
                            for queue_entry in self._queue:
                                if queue_entry.macro.id == entry.macro.id:
                                    removal_list.append(queue_entry)
                            for queue_entry in removal_list:
                                self._queue.remove(queue_entry)
                    # Don't run a queued macro if the same instance is already
                    # running
                    elif entry.macro.id in self._active:
                        continue
                    # Handle exclusive macros
                    elif entry.macro.exclusive:
                        has_exclusive = True
                        if len(self._active) == 0:
                            self._dispatch_macro(entry.macro)
                            self._is_executing_exclusive = True
                            entries_to_remove.append(entry)
                    # Start a queued up macro
                    elif not has_exclusive and not self._is_executing_exclusive:
                        self._dispatch_macro(entry.macro)
                        entries_to_remove.append(entry)

                # Remove all entries we've processed
                for entry in entries_to_remove:
                    if entry in self._queue:
                        self._queue.remove(entry)

    def _dispatch_macro(self, macro: Macro) -> None:
        """Dispatches a single macro to be run.

        Args:
            macro: the macro to dispatch
        """
        if macro.id not in self._active:
            self._active[macro.id] = macro
            Thread(target=functools.partial(self._execute_macro, macro)).start()
        else:
            logging.getLogger("system").warning(
                "Attempting to dispatch an already running macro"
            )

    def _execute_macro(self, macro: Macro)  :
        """Executes a given macro in a separate thread.

        This method will run all provided actions and once they all have been
        executed will remove the macro from the set of active macros and
        inform the scheduler of the completion.

        Args:
            macro: the macro object to be executed
        """
        # Handle macros with a repeat mode
        if macro.repeat is not None:
            delay = macro.repeat.delay

            with self._flags_lock:
                self._flags[macro.id] = True

            # Handle count repeat mode
            if isinstance(macro.repeat, CountRepeat):
                count = 0
                while count < macro.repeat.count and self._flags[macro.id]:
                    for action in macro.sequence:
                        action()
                    count += 1
                    time.sleep(delay)

            # Handle continuous repeat modes
            elif type(macro.repeat) in [HoldRepeat, ToggleRepeat]:
                while self._flags[macro.id]:
                    for action in macro.sequence:
                        action()
                    time.sleep(delay)

        # Handle simple one shot macros
        else:
            for action in macro.sequence:
                action()

        # Remove macro from active set, notify manager, and remove any
        # potential callbacks
        del self._active[macro.id]
        if macro.exclusive:
            self._is_executing_exclusive = False
        with self._flags_lock:
            if macro.id in self._flags:
                self._flags[macro.id] = False
        self._schedule_event.set()

    def _preprocess_macro(self, macro: Macro) -> None:
        """Inserts pauses as necessary into the macro.

        Args:
            macro: the macro instance to modify
        """
        new_sequence = [macro.sequence[0]]
        for a1, a2 in zip(macro.sequence[:-1], macro.sequence[1:]):
            if isinstance(a1, PauseAction) or isinstance(a2, PauseAction):
                new_sequence.append(a2)
            else:
                new_sequence.append(PauseAction(self.default_delay))
                new_sequence.append(a2)
        macro._sequence = new_sequence


class Macro:

    """Represents a macro which can be executed."""

    # Unique identifier for each macro
    _next_macro_id = 0

    def __init__(self):
        """Creates a new macro instance."""
        self._sequence = []
        self._id = Macro._next_macro_id
        Macro._next_macro_id += 1
        self.repeat = None
        self.exclusive = False

    @property
    def id(self) -> int:
        """Returns the unique id of this macro.

        Returns:
            unique id of this macro
        """
        return self._id

    @property
    def sequence(self) -> List[AbstractActionData]:
        """Returns the action sequence of this macro.

        Returns:
            Sequence of actions comprising the macro
        """
        return self._sequence

    def add_action(self, action: AbstractActionData) -> None:
        """Adds an action to the list of actions to perform.

        Args:
            action: the action to add
        """
        self._sequence.append(action)

    def pause(self, duration: float) -> None:
        """Adds a pause of the given duration to the macro.

        Args:
            duration: the duration of the pause in seconds
        """
        self._sequence.append(PauseAction(duration))

    def press(self, key: Key) -> None:
        """Presses the specified key down.

        Args:
            key: the key to press
        """
        self.action(key, True)

    def release(self, key: Key) -> None:
        """Releases the specified key.

        Args:
            key; the key to release
        """
        self.action(key, False)

    def tap(self, key: Key) -> None:
        """Taps the specified key.

        Args:
            key: the key to tap
        """
        self.action(key, True)
        self.action(key, False)

    def action(self, key: Key | str, is_pressed: bool) -> None:
        """Adds the specified action to the sequence.

        Args:
            key: the key involved in the action
            is_pressed: boolean indicating if the key is pressed
                (True) or released (False)
        """
        if isinstance(key, str):
            key = key_from_name(key)
        elif isinstance(key, Key):
            pass
        else:
            raise gremlin.error.KeyboardError("Invalid key specified")

        self._sequence.append(KeyAction(key, is_pressed))


class AbstractAction(ABC):

    """Base class for all macro action."""

    @abstractmethod
    def __call__(self) -> None:
        pass

    @abstractmethod
    def to_xml(self) -> ElementTree.Element:
        pass

    @abstractmethod
    def from_xml(self, node: ElementTree.Element) -> None:
        pass

    def _create_node(self, type_name: str) -> ElementTree.Element:
        """Creates an action node of the given type.

        Args:
            type_name: name of the type of this action node

        Returns:
            An action node typed as request
        """
        node = ElementTree.Element("action")
        node.set("type", type_name)
        return node


class JoystickAction(AbstractAction):

    """Joystick input action for a macro."""

    def __init__(
            self,
            device_guid: uuid.UUID,
            input_type: InputType,
            input_id: int | uuid.UUID,
            value: bool | float | Tuple[int, int],
            axis_mode: AxisMode=AxisMode.Absolute
    ):
        """Creates a new JoystickAction instance for use in a macro.

        Args:
            device_guid: GUID of the device generating the input
            input_type: type of input being generated
            input_id: id of the input being generated
            value: the value of the generated input
            axis_mode: if an axis is used, how to interpret the value
        """
        self.device_guid = device_guid
        self.input_type = input_type
        self.input_id = input_id
        self.value = value
        self.axis_mode = axis_mode

    def __call__(self) -> None:
        """Emits an Event instance through the EventListener system."""
        el = gremlin.event_handler.EventListener()
        if self.input_type == InputType.JoystickAxis:
            event = gremlin.event_handler.Event(
                event_type=self.input_type,
                device_guid=self.device_guid,
                identifier=self.input_id,
                mode=mode_manager.ModeManager().current,
                value=self.value
            )
        elif self.input_type == InputType.JoystickButton:
            event = gremlin.event_handler.Event(
                event_type=self.input_type,
                device_guid=self.device_guid,
                identifier=self.input_id,
                mode=mode_manager.ModeManager().current,
                is_pressed=self.value
            )
        elif self.input_type == InputType.JoystickHat:
            event = gremlin.event_handler.Event(
                event_type=self.input_type,
                device_guid=self.device_guid,
                identifier=self.input_id,
                mode=mode_manager.ModeManager().current,
                value=self.value
            )

        el.joystick_event.emit(event)

    def to_xml(self) -> ElementTree.Element:
        node = self._create_node("joystick")
        util.append_property_nodes([
            ["device-guid", self.device_guid, PropertyType.UUID],
            ["input-type", self.input_type, PropertyType.InputType],
            ["input-id", self.input_id, PropertyType.Int],
        ])
        if self.input_type == InputType.JoystickAxis:
            util.append_property_nodes(
                node,
                [
                    ["value", self.value, PropertyType.Float],
                    ["axis-mode", self.axis_mode, PropertyType.AxisMode]
                ]
            )
        elif self.input_type == InputType.JoystickButton:
            node.append(util.create_property_node(
                "value", self.value, PropertyType.Bool
            ))
        elif self.input_type == InputType.JoystickHat:
            node.append(util.create_property_node(
                "value", self.value, PropertyType.HatDirection
            ))
        return node

    def from_xml(self, node: ElementTree.Element) -> None:
        self.device_guid = util.read_property(
            node, "device-guid", PropertyType.UUID
        )
        self.input_type = util.read_property(
            node, "input-type", PropertyType.InputType
        )
        self.input_id = util.read_property(node, "input-id", PropertyType.Int)
        if self.input_type == InputType.JoystickAxis:
            self.value = util.read_property(node, "value", PropertyType.Float)
            self.axis_mode = util.read_property(
                node, "axis-mode", PropertyType.AxisMode
            )
        elif self.input_type == InputType.JoystickButton:
            self.value = util.read_property(node, "value", PropertyType.Bool)
        elif self.input_type == InputType.JoystickHat:
            self.value = util.read_property(
                node, "value", PropertyType.HatDirection
            )


class KeyAction(AbstractAction):

    """Key to press or release by a macro."""

    def __init__(self, key: Key, is_pressed: bool):
        """Creates a new KeyAction object for use in a macro.

        Args:
            key: the key to use in the action
            is_pressed: True if the key should be pressed, False otherwise
        """
        if not isinstance(key, Key):
            raise gremlin.error.KeyboardError("Invalid Key instance provided")

        self.key = key
        self.is_pressed = is_pressed

    def __call__(self) -> None:
        if self.is_pressed:
            send_key_down(self.key)
        else:
            send_key_up(self.key)

    def to_xml(self) -> ElementTree.Element:
        node = self._create_node("key")
        util.append_property_nodes(
            node,
            [
                ["scan-code", self.key.scan_code, PropertyType.Int],
                ["is-extended", self.key.is_extended, PropertyType.Bool],
                ["is-pressed", self.is_pressed, PropertyType.Bool],
            ]
        )
        return node

    def from_xml(self, node: ElementTree.Element) -> None:
        self.key = key_from_code(
            util.read_property(node, "scan-code", PropertyType.Int),
            util.read_property(node, "is-extended", PropertyType.Bool)
        )
        self.is_pressed = util.read_property(
            node, "is-pressed", PropertyType.Bool
        )


class MouseButtonAction(AbstractAction):

    """Mouse button action."""

    def __init__(self, button: MouseButton, is_pressed: bool):
        """Creates a new MouseButtonAction object for use in a macro.

        Args:
            button: the button to use in the action
            is_pressed: True if the button should be pressed, False otherwise
        """
        if not isinstance(button, MouseButton):
            raise gremlin.error.MouseError("Invalid mouse button provided")

        self.button = button
        self.is_pressed = is_pressed

    def __call__(self) -> None:
        if self.button == MouseButton.WheelDown:
            gremlin.sendinput.mouse_wheel(1)
        elif self.button == MouseButton.WheelUp:
            gremlin.sendinput.mouse_wheel(-1)
        else:
            if self.is_pressed:
                gremlin.sendinput.mouse_press(self.button)
            else:
                gremlin.sendinput.mouse_release(self.button)

    def to_xml(self) -> ElementTree.Element:
        node = self._create_node("mouse")
        util.append_property_nodes(
            node,
            [
                ["button", MouseButton.to_string(self.button), PropertyType.String],
                ["is-pressed", self.is_pressed, PropertyType.Bool],
            ]
        )
        return node

    def from_xml(self, node: ElementTree.Element) -> None:
        self.button = MouseButton.to_enum(util.read_property(
            node, "button", PropertyType.String
        ))
        self.is_pressed = util.read_property(
            node, "is-pressed", PropertyType.Bool
        )


class MouseMotionAction(AbstractAction):

    """Mouse motion action."""

    def __init__(self, dx: float|int, dy: float|int):
        """Creates a new MouseMotionAction object for use in a macro.

        Args:
            dx: change along the X axis
            dy: change along the Y axis
        """
        self.dx = int(dx)
        self.dy = int(dy)

    def __call__(self) -> None:
        gremlin.sendinput.mouse_relative_motion(self.dx, self.dy)

    def to_xml(self) -> ElementTree.Element:
        node = self._create_node("mouse-motion")
        util.append_property_nodes(
            node,
            [
                ["dx", self.dx, PropertyType.Int],
                ["dy", self.dy, PropertyType.Int],
            ]
        )
        return node

    def from_xml(self, node: ElementTree.Element) -> None:
        self.dx = util.read_property(node, "dx", PropertyType.Int)
        self.dy = util.read_property(node, "dy", PropertyType.Int)


class PauseAction(AbstractAction):

    """Represents the pause in a macro between pressed."""

    def __init__(self, duration: float):
        """Creates a new Pause object for use in a macro.

        Args:
            duration: the duration in seconds of the pause
        """
        self.duration = duration

    def __call__(self) -> None:
        time.sleep(self.duration)

    def to_xml(self) -> ElementTree.Element:
        node = self._create_node("pause")
        node.append(util.create_property_node(
            "duration", self.duration, PropertyType.Float
        ))
        return node

    def from_xml(self, node: ElementTree.Element) -> None:
        self.duration = util.read_property(
            node, "duration", PropertyType.Float
        )


class VJoyAction(AbstractAction):

    """VJoy input action for a macro."""

    def __init__(
            self,
            vjoy_id: int,
            input_type: InputType,
            input_id: int,
            value: bool | float | Tuple[int, int],
            axis_mode: AxisMode=AxisMode.Absolute
    ):
        """Creates a new JoystickAction instance for use in a macro.

        Args:
            vjoy_id: id of the vjoy device which is to be modified
            input_type: type of input being generated
            input_id: id of the input being generated
            value: the value of the generated input
            axis_type: if an axis is used, how to interpret the value
        """
        self.vjoy_id = vjoy_id
        self.input_type = input_type
        self.input_id = input_id
        self.value = value
        self.axis_mode = axis_mode

    def __call__(self) -> None:
        vjoy = gremlin.joystick_handling.VJoyProxy()[self.vjoy_id]
        if self.input_type == InputType.JoystickAxis:
            if self.axis_type == "absolute":
                vjoy.axis(self.input_id).value = self.value
            elif self.axis_type == "relative":
                vjoy.axis(self.input_id).value = max(
                    -1.0,
                    min(1.0, vjoy.axis(self.input_id).value + self.value)
                )
        elif self.input_type == InputType.JoystickButton:
            vjoy.button(self.input_id).is_pressed = self.value
        elif self.input_type == InputType.JoystickHat:
            vjoy.hat(self.input_id).direction = self.value

    def to_xml(self) -> ElementTree.Element:
        node = self._create_node("joystick")
        util.append_property_nodes([
            ["vjoy-id", self.vjoy_id, PropertyType.Int],
            ["input-type", self.input_type, PropertyType.InputType],
            ["input-id", self.input_id, PropertyType.Int],
        ])
        if self.input_type == InputType.JoystickAxis:
            util.append_property_nodes(
                node,
                [
                    ["value", self.value, PropertyType.Float],
                    ["axis-mode", self.axis_mode, PropertyType.AxisMode]
                ])
        elif self.input_type == InputType.JoystickButton:
            node.append(util.create_property_node(
                "value", self.value, PropertyType.Bool
            ))
        elif self.input_type == InputType.JoystickHat:
            node.append(util.create_property_node(
                "value", self.value, PropertyType.HatDirection
            ))
        return node

    def from_xml(self, node: ElementTree.Element) -> None:
        self.vjoy_id = util.read_property(node, "vjoy-id", PropertyType.Int)
        self.input_type = util.read_property(
            node, "input-type", PropertyType.InputType
        )
        self.input_id = util.read_property(node, "input-id", PropertyType.Int)
        if self.input_type == InputType.JoystickAxis:
            self.value = util.read_property(node, "value", PropertyType.Float)
            self.axis_mode = util.read_property(
                node, "axis-mode", PropertyType.AxisMode
            )
        elif self.input_type == InputType.JoystickButton:
            self.value = util.read_property(node, "value", PropertyType.Bool)
        elif self.input_type == InputType.JoystickHat:
            self.value = util.read_property(
                node, "value", PropertyType.HatDirection
            )


class AbstractRepeat(ABC):

    """Base class for all macro repeat modes."""

    def __init__(self, delay: float):
        """Creates a new instance.

        Args:
            delay the delay between repetitions
        """
        self.delay = delay

    def to_xml(self) -> ElementTree.Element:
        """Returns an XML node encoding the repeat information.

        Returns:
            XML node containing the instance's information
        """
        node = ElementTree.Element("repeat")
        node.append(util.create_property_node(
            "delay", self.delay, PropertyType.Float)
        )
        self._to_xml_additional(node)
        return node

    def from_xml(self, node: ElementTree.Element) -> None:
        """Populates the instance's data from the provided XML node.

        Args:
            node: XML node containing data with which to populate the instance
        """
        self.delay = util.read_property(node, "delay", PropertyType.Float)
        self._from_xml_additional(node)

    @abstractmethod
    def _to_xml_additional(self, node: ElementTree.Element) -> None:
        pass

    @abstractmethod
    def _from_xml_additional(self, node: ElementTree.Element) -> None:
        pass


class CountRepeat(AbstractRepeat):

    """Repeat mode which repeats the macro a fixed number of times."""

    def __init__(self, count: int=1, delay: float=0.1):
        """Creates a new instance.

        Args:
            count: the number of times to repeat the macro
            delay: the delay between repetitions
        """
        super().__init__(delay)
        self.count = count

    def _to_xml_additional(self, node: ElementTree.Element) -> None:
        """Returns an XML node encoding the repeat information.

        Args:
            node: XML node containing the instance's information
        """
        node.set("type", "count")
        node.append(util.create_property_node(
            "count", self.count, PropertyType.Int
        ))

    def _from_xml_additional(self, node: ElementTree.Element) -> None:
        """Populates the instance's data from the provided XML node.

        Args:
            node: XML node containing data with which to populate the instance
        """
        self.count = util.read_property(node, "count", PropertyType.Int)


class ToggleRepeat(AbstractRepeat):

    """Repeat mode which repeats the macro as long as it hasn't been toggled
    off again after being toggled on."""

    def __init__(self, delay: float=0.1):
        """Creates a new instance.

        Args:
            delay the delay between repetitions
        """
        super().__init__(delay)

    def _to_xml_additional(self, node: ElementTree.Element) -> None:
        """Returns an XML node encoding the repeat information.

        Args:
            node: XML node containing the instance's information
        """
        node.set("type", "toggle")

    def _from_xml_additional(self, node: ElementTree.Element) -> None:
        """Populates the instance's data from the provided XML node.

        Args:
            node: XML node containing data with which to populate the instance
        """
        pass


class HoldRepeat(AbstractRepeat):

    """Repeat mode which repeats the macro as long as the activation condition
    is being fulfilled or held down."""

    def __init__(self, delay: float=0.1):
        """Creates a new instance.

        Args:
            delay the delay between repetitions
        """
        super().__init__(delay)

    def _to_xml_additional(self, node: ElementTree.Element) -> None:
        """Returns an XML node encoding the repeat information.

        Args:
            node: XML node containing the instance's information
        """
        node.set("type", "hold")

    def _from_xml_additional(self, node: ElementTree.Element) -> None:
        """Populates the instance's data from the provided XML node.

        Args:
            node XML node containing data with which to populate the instance
        """
        pass
