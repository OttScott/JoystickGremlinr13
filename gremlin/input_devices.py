# -*- coding: utf-8; -*-

# Copyright (C) 2015 Lionel Ott
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


import collections
from collections.abc import Callable
import functools
import heapq
import inspect
import logging
import time
import threading
from typing import Any
import uuid

from PySide6 import QtCore

import dill
from vjoy import vjoy

import gremlin.common
import gremlin.keyboard

from gremlin import common, error, event_handler, mode_manager
from gremlin.input_cache import Joystick, Keyboard
from gremlin.types import InputType


# List of all joystick devices
_joystick_devices = []

# Joystick initialization lock
_joystick_init_lock = threading.Lock()


class CallbackRegistry:

    """Registry of all callbacks known to the system."""

    def __init__(self):
        """Creates a new callback registry instance."""
        self._registry = {}
        self._current_id = 0

    def add(
            self,
            callback: Callable,
            event: event_handler.Event,
            mode: str
    ) -> None:
        """Adds a new callback to the registry.

        Args:
            callback: function to add as a callback
            event: the event on which to trigger the callback
            mode: the mode in which to trigger the callback
        """
        self._current_id += 1
        function_name = "{}_{:d}".format(callback.__name__, self._current_id)

        if event.device_guid not in self._registry:
            self._registry[event.device_guid] = {}
        if mode not in self._registry[event.device_guid]:
            self._registry[event.device_guid][mode] = {}
        if event not in self._registry[event.device_guid][mode]:
            self._registry[event.device_guid][mode][event] = {}

        self._registry[event.device_guid][mode][event][function_name] = callback

    @property
    def registry(self) -> dict:
        """Returns the registry dictionary.

        Returns:
            The callback registry dictionary
        """
        return self._registry

    def clear(self) -> None:
        """Clears the registry entries."""
        self._registry = {}


class PeriodicRegistry:

    """Registry for periodically executed functions."""

    def __init__(self):
        """Creates a new instance."""
        self._registry = {}
        self._running = False
        self._thread = threading.Thread(target=self._thread_loop)
        self._queue = []
        self._plugins = []

    def start(self) -> None:
        """Starts the event loop."""
        # Only proceed if we have functions to call
        if len(self._registry) == 0:
            return

        # Only create a new thread and start it if the thread is not
        # currently running
        self._running = True
        if not self._thread.is_alive():
            self._thread = threading.Thread(target=self._thread_loop)
            self._thread.start()

    def stop(self) -> None:
        """Stops the event loop."""
        self._running = False
        if self._thread.is_alive():
            self._thread.join()

    def add(self, callback: Callable, interval: float) -> None:
        """Adds a function to execute periodically.

        Args:
            callback: the function to execute
            interval: the time in seconds between executions
        """
        self._registry[callback] = (interval, callback)

    def clear(self) -> None:
        """Clears the registry."""
        self._registry = {}

    def _install_plugins(self, callback: Callable) -> Callable:
        """Installs the current plugins into the given callback.

        Args:
            callback: the callback function to install the plugins into

        Returns:
            new callback with plugins installed
        """
        signature = inspect.signature(callback).parameters
        partial_fn = functools.partial
        if "self" in signature:
            partial_fn = functools.partialmethod
        for plugin in self._plugins:
            if plugin.keyword in signature:
                callback = plugin.install(callback, partial_fn)
        return callback

    def _thread_loop(self) -> None:
        """Main execution loop run in a separate thread."""
        # Setup plugins to use
        self._plugins = [
            JoystickPlugin(),
            VJoyPlugin(),
            KeyboardPlugin()
        ]
        callback_map = {}

        # Populate the queue
        self._queue = []
        for item in self._registry.values():
            plugin_cb = self._install_plugins(item[1])
            callback_map[plugin_cb] = item[0]
            heapq.heappush(
                self._queue,
                (time.time() + callback_map[plugin_cb], plugin_cb)
            )

        # Main thread loop
        while self._running:
            # Process all events that require running
            while self._queue[0][0] < time.time():
                item = heapq.heappop(self._queue)
                item[1]()

                heapq.heappush(
                    self._queue,
                    (time.time() + callback_map[item[1]], item[1])
                )

            # Sleep until either the next function needs to be run or
            # our timeout expires
            time.sleep(min(self._queue[0][0] - time.time(), 1.0))


# Global registry of all registered callbacks
callback_registry = CallbackRegistry()

# Global registry of all periodic callbacks
periodic_registry = PeriodicRegistry()


# def register_callback(callback, device, input_type, input_id):
#     """Adds a callback to the registry.
#
#     This function adds the provided callback to the global callback_registry
#     for the specified event and mode combination.
#
#     Parameters
#     ==========
#     callback : callable
#         The callable object to execute when the event with the specified
#         conditions occurs
#     device : JoystickDecorator
#         Joystick decorator specifying the device and mode in which to execute
#         the callback
#     input_type : gremlin.types.InputType
#         Type of input on which to execute the callback
#     input_id : int
#         Index of the input on which to execute the callback
#     """
#     event = event_handler.Event(
#         event_type=input_type,
#         device_guid=device.device_guid,
#         identifier=input_id
#     )
#     callback_registry.add(callback, event, device.mode, False)


class VJoyProxy:

    """Manages the usage of vJoy and allows shared access all callbacks."""

    vjoy_devices = {}

    def __getitem__(self, key):
        """Returns the requested vJoy instance.

        :param key id of the vjoy device
        :return the corresponding vjoy device
        """
        if key in VJoyProxy.vjoy_devices:
            return VJoyProxy.vjoy_devices[key]
        else:
            if not isinstance(key, int):
                raise error.GremlinError(
                    "Integer ID for vjoy device ID expected"
                )

            try:
                device = vjoy.VJoy(key)
                VJoyProxy.vjoy_devices[key] = device
                return device
            except error.VJoyError as e:
                logging.getLogger("system").error(
                    "Failed accessing vJoy id={}, error is: {}".format(
                        key,
                        e
                    )
                )
                raise e

    @classmethod
    def reset(cls):
        """Relinquishes control over all held VJoy devices."""
        for device in VJoyProxy.vjoy_devices.values():
            device.invalidate()
        VJoyProxy.vjoy_devices = {}


class VJoyPlugin:

    """Plugin providing automatic access to the VJoyProxy object.

    For a function to use this plugin it requires one of its parameters
    to be named "vjoy".
    """

    vjoy = VJoyProxy()

    def __init__(self):
        self.keyword = "vjoy"

    def install(self, callback: Callable, partial_fn: Callable) -> Callable:
        """Decorates the given callback function to provide access to
        the VJoyProxy object.

        Only if the signature contains the plugin's keyword is the
        decorator applied.

        Args:
            callback: the callback to decorate
            partial_fn: function to create the partial function / method

        Returns:
            callback with the plugin parameter bound
        """
        return partial_fn(callback, vjoy=VJoyPlugin.vjoy)


class JoystickPlugin:

    """Plugin providing automatic access to the Joystick object.

    For a function to use this plugin it requires one of its parameters
    to be named "joy".
    """

    joystick = Joystick()

    def __init__(self):
        self.keyword = "joy"

    def install(self, callback: Callable, partial_fn: Callable) -> Callable:
        """Decorates the given callback function to provide access
        to the Joystick object.

        Only if the signature contains the plugin's keyword is the
        decorator applied.

        Args:
            callback: the callback to decorate
            partial_fn: function to create the partial function / method

        Returns:
            callback with the plugin parameter bound
        """
        return partial_fn(callback, joy=JoystickPlugin.joystick)


class KeyboardPlugin:

    """Plugin providing automatic access to the Keyboard object.

    For a function to use this plugin it requires one of its parameters
    to be named "keyboard".
    """

    keyboard = Keyboard()

    def __init__(self):
        self.keyword = "keyboard"

    def install(self, callback, partial_fn):
        """Decorates the given callback function to provide access to
        the Keyboard object.

        Args:
            callback: the callback to decorate
            partial_fn: function to create the partial function / method

        Returns:
            callback with the plugin parameter bound
        """
        return partial_fn(callback, keyboard=KeyboardPlugin.keyboard)


ButtonReleaseEntry = collections.namedtuple(
    "Entry", ["callback", "event", "mode"]
)


@common.SingletonDecorator
class ButtonReleaseActions(QtCore.QObject):

    """Ensures a desired action is run when a button is released."""

    def __init__(self):
        """Initializes the instance."""
        QtCore.QObject.__init__(self)

        self._registry = {}
        self._ignore_registry = {}
        el = event_handler.EventListener()
        el.joystick_event.connect(self._input_event_cb)
        el.keyboard_event.connect(self._input_event_cb)
        el.virtual_event.connect(self._input_event_cb)
        mm = mode_manager.ModeManager()
        self._current_mode = mm.current.name
        mm.mode_changed.connect(self._mode_changed_cb)

    def register_callback(
        self,
        callback: Callable[[], None],
        physical_event: event_handler.Event
    ) -> None:
        """Registers a callback with the system.

        Args:
            callback: the function to run when the corresponding button is
                released
            physical_event: the physical event of the button being pressed
        """
        release_evt = physical_event.clone()
        release_evt.is_pressed = False

        if release_evt not in self._registry:
            self._registry[release_evt] = []
        # Do not record the mode since we may want to run the release action
        # independent of a mode
        self._registry[release_evt].append(
            ButtonReleaseEntry(callback, release_evt, None)
        )

    def register_button_release(
        self,
        vjoy_input: tuple[int, int],
        physical_event: event_handler.Event,
        activate_on: bool
    ) -> None:
        """Registers a physical and vjoy button pair for tracking.

        This method ensures that a vjoy button is pressed/released when the
        specified physical event occurs next. This is useful for cases where
        an action was triggered in a different mode or using a different
        condition.

        Args:
            vjoy_input: the vjoy button to release, represented as
                (vjoy_device_id, vjoy_button_id)
            physical_event: the button event when release should
                trigger the release of the vjoy button
            activate_on: button state on which to trigger the automatic
                release
        """
        if (physical_event, vjoy_input) in self._ignore_registry:
            logging.getLogger("system").warning(
                f"Not registering button release event for "
                f"{physical_event} to {vjoy_input}"
            )
            return

        release_evt = physical_event.clone()
        release_evt.is_pressed = activate_on

        if release_evt not in self._ignore_registry:
            self._ignore_registry[release_evt] = []
        # Record current mode so we only release if we've changed mode
        self._ignore_registry[release_evt].append(ButtonReleaseEntry(
            lambda: self._release_callback_prototype(vjoy_input),
            release_evt,
            self._current_mode
        ))

    def ignore_button_release(
            self,
            vjoy_input: tuple[int, int],
            physical_event: event_handler.Event
    ) -> None:
        """Ignores physical and vjoy button pair tracking requests.

        This prevents calls to register_button_callback from being honored
        in cases where some action wants to disable this feature.

        Args:
            vjoy_input: the vjoy button to release, represented as
                (vjoy_device_id, vjoy_button_id)
            physical_event: the button event when release should
                trigger the release of the vjoy button
        """
        key = (physical_event, vjoy_input)
        self._ignore_registry[key] = True

    def reset(self) -> None:
        """Wipes the registry database."""
        self._registry = {}
        self._ignore_registry = {}

    def _release_callback_prototype(self, vjoy_input: int) -> None:
        """Prototype of a button release callback, used with lambdas.

        Args:
            vjoy_input: the vjoy input data to use in the release
        """
        vjoy = VJoyProxy()
        # Check if the button is valid otherwise we cause Gremlin to crash
        if vjoy[vjoy_input[0]].is_button_valid(vjoy_input[1]):
            vjoy[vjoy_input[0]].button(vjoy_input[1]).is_pressed = False
        else:
            logging.getLogger("system").warning(
                f"Attempted to use non existent button: " +
                f"vJoy {vjoy_input[0]:d} button {vjoy_input[1]:d}"
            )

    def _input_event_cb(self, event: event_handler.Event) -> None:
        """Runs callbacks associated with the given event.

        Args:
            event: the event to process
        """
        #if evt in [e for e in self._registry if e.is_pressed != evt.is_pressed]:
        if event in self._registry:
            new_list = []
            for entry in self._registry[event]:
                if entry.event.is_pressed == event.is_pressed:
                    entry.callback()
                else:
                    new_list.append(entry)
            self._registry[event] = new_list

    def _mode_changed_cb(self, mode: str) -> None:
        """Updates the current mode variable.

        Args:
            mode: name of the now active mode
        """
        self._current_mode = mode


@common.SingletonDecorator
class JoystickInputSignificant:

    """Checks whether or not joystick inputs are significant."""

    def __init__(self):
        """Initializes the instance."""
        self._event_registry = {}
        self._mre_registry = {}
        self._time_registry = {}

    def should_process(self, event: event_handler.Event) -> bool:
        """Returns whether or not a particular event is significant enough to
        process.

        Args:
            event: the event to check for significance

        Returns:
            True if the event should be processed, False otherwise
        """
        self._mre_registry[event] = event

        if event.event_type == InputType.JoystickAxis:
            return self._process_axis(event)
        elif event.event_type == InputType.JoystickButton:
            return self._process_button(event)
        elif event.event_type == InputType.JoystickHat:
            return self._process_hat(event)
        else:
            logging.getLogger("system").warning(
                "Event with unknown type received"
            )
            return False

    def last_event(self, event: event_handler.Event) -> event_handler.Event:
        """Returns the most recent event of this type.

        Args:
            event: the type of event for which to return the most recent one

        Returns:
            Latest event instance corresponding to the specified event
        """
        return self._mre_registry[event]

    def reset(self) -> None:
        """Resets the detector to a clean state for subsequent uses."""
        self._event_registry = {}
        self._mre_registry = {}
        self._time_registry = {}

    def _process_axis(self, event: event_handler.Event) -> bool:
        """Process an axis event.

        Args:
            event: the axis event to process

        Returns:
            True if it should be processed, False otherwise
        """
        if event in self._event_registry:
            # Reset everything if we have no recent data
            if self._time_registry[event] + 5.0 < time.time():
                self._event_registry[event] = event
                self._time_registry[event] = time.time()
                return False
            # Update state
            else:
                self._time_registry[event] = time.time()
                if abs(self._event_registry[event].value - event.value) > 0.25:
                    self._event_registry[event] = event
                    self._time_registry[event] = time.time()
                    return True
                else:
                    return False
        else:
            self._event_registry[event] = event
            self._time_registry[event] = time.time()
            return False

    def _process_button(self, event: event_handler.Event) -> bool:
        """Process a button event.

        Args:
            event: the button event to process

        Returns:
            True if it should be processed, False otherwise
        """
        return True

    def _process_hat(self, event: event_handler.Event) -> bool:
        """Process a hat event.

        Args:
            event: the hat event to process

        Returns:
            True if it should be processed, False otherwise
        """
        return event.value != (0, 0)


class JoystickDecorator:

    """Creates customized decorators for physical joystick devices."""

    def __init__(self, name: str, device_guid: str, mode: str):
        """Creates a new instance with customized decorators.

        Args:
            name: name of the device
            device_guid: the device's guid in the system
            mode: the mode in which the decorated functions should be active
        """
        self.name = name
        self.mode = mode

        # Convert string-based GUID to the actual GUID object
        try:
            self.device_guid = uuid.UUID(device_guid)
        except ValueError:
            logging.getLogger("system").error(
                f"Invalid guid value '{device_guid}' received."
            )
            self.device_guid = diill.UUID_Invalid

        # Create decorators for the different input types
        self.axis = functools.partial(
            _input_callback,
            device_guid=self.device_guid,
            input_type=InputType.JoystickAxis,
            mode=self.mode
        )
        self.button = functools.partial(
            _input_callback,
            device_guid=self.device_guid,
            input_type=InputType.JoystickButton,
            mode=self.mode
        )
        self.hat = functools.partial(
            _input_callback,
            device_guid=self.device_guid,
            input_type=InputType.JoystickHat,
            mode=self.mode
        )


def _input_callback(
        device_guid: uuid.UUID,
        input_type: InputType,
        input_id: int,
        mode: str
):
    """Decorator for a specific input on a physical device.

    Args:
        device_guid: GUID of the physical device
        input_type: type of the input being wrapped in the decorator
        input_id: identifier of the axis, button, or hat being decorated
        mode: name of the mode the callback is active in
    """
    def wrap(callback):

        @functools.wraps(callback)
        def wrapper_fn(*args, **kwargs):
            callback(*args, **kwargs)

        event = event_handler.Event(
            event_type=input_type,
            identifier=input_id,
            device_guid=device_guid,
            mode=mode
        )
        callback_registry.add(wrapper_fn, event, mode)

        return wrapper_fn

    return wrap


def joystick_devices() -> list[dill.DeviceSummary]:
    """Returns the list of joystick like devices.

    Returns:
        List containing information about all joystick devices
    """
    return _joystick_devices


def vjoy_devices() -> list[dill.DeviceSummary]:
    """Returns the list of vJoy devices.

    Returns:
        List of vJoy devices
    """
    return [dev for dev in _joystick_devices if dev.is_virtual]


def physical_devices() -> list[dill.DeviceSummary]:
    """Returns the list of physical devices.

    Returns:
        List of physical devices
    """
    return [dev for dev in _joystick_devices if not dev.is_virtual]


def select_first_valid_vjoy_input(
        valid_types: list[InputType]
) -> dict[str, Any]|None:
    """Returns the first valid vjoy input.

    Args:
        valid_types: List of InputType values that are valid type to be returned

    Returns:
        Dictionary containing the information about the selected vJoy input
    """
    for dev in vjoy_devices():
        if InputType.JoystickAxis in valid_types and dev.axis_count > 0:
            return {
                "device_id": dev.vjoy_id,
                "input_type": InputType.JoystickAxis,
                "input_id": dev.axis_map[0].axis_index
            }
        elif InputType.JoystickButton in valid_types and dev.button_count > 0:
            return {
                "device_id": dev.vjoy_id,
                "input_type": InputType.JoystickButton,
                "input_id": 1
            }
        elif InputType.JoystickHat in valid_types and dev.hat_count > 0:
            return {
                "device_id": dev.vjoy_id,
                "input_type": InputType.JoystickHat,
                "input_id": 1
            }
    return None


def vjoy_id_from_guid(guid):
    """Returns the vJoy id corresponding to the given device GUID.

    Parameters
    ==========
    guid : GUID
        guid of the vjoy device in windows

    Return
    ======
    int
        vJoy id corresponding to the provided device
    """
    for dev in vjoy_devices():
        if dev.device_guid == guid:
            return dev.vjoy_id

    logging.getLogger("system").error(
        "Could not find vJoy matching guid {}".format(str(guid))
    )
    return 1


def linear_axis_index(axis_map, axis_index):
    """Returns the linear index for an axis based on the axis index.

    Parameters
    ==========
    axis_map : dill.AxisMap
        AxisMap instance which contains the mapping between linear and
        axis indices
    axis_index : int
        Index of the axis for which to return the linear index

    Return
    ======
    int
        Linear axis index
    """
    for entry in axis_map:
        if entry.axis_index == axis_index:
            return entry.linear_index
    raise error.GremlinError("Linear axis lookup failed")


def joystick_devices_initialization():
    """Initializes joystick device information.

    This function retrieves information about various joystick devices and
    associates them and collates their information as required.

    Amongst other things this also ensures that each vJoy device has a correct
    windows id assigned to it.
    """
    global _joystick_devices, _joystick_init_lock

    _joystick_init_lock.acquire()

    syslog = logging.getLogger("system")
    syslog.info("Initializing joystick devices")
    syslog.debug(
        "{:d} joysticks detected".format(dill.DILL.get_device_count())
    )

    # Process all connected devices in order to properly initialize the
    # device registry
    devices = []
    for i in range(dill.DILL.get_device_count()):
        info = dill.DILL.get_device_information_by_index(i)
        devices.append(info)

    # Process all devices again to detect those that have been added and those
    # that have been removed since the last time this function ran.

    # Compare existing versus observed devices and only proceed if there
    # is a change to avoid unnecessary work.
    device_added = False
    device_removed = False
    for new_dev in devices:
        if new_dev not in _joystick_devices:
            device_added = True
            syslog.debug("Added: name={} guid={}".format(
                new_dev.name,
                new_dev.device_guid
            ))
    for old_dev in _joystick_devices:
        if old_dev not in devices:
            device_removed = True
            syslog.debug("Removed: name={} guid={}".format(
                old_dev.name,
                old_dev.device_guid
            ))

    # Terminate if no change occurred
    if not device_added and not device_removed:
        _joystick_init_lock.release()
        return

    # In order to associate vJoy devices and their ids correctly with SDL
    # device ids a hash is constructed from the number of axes, buttons, and
    # hats. This information is used to attempt to find unambiguous mappings
    # between vJoy and SDL devices. If this is not possible Gremlin will
    # terminate as this is a non-recoverable error.

    vjoy_lookup = {}
    for dev in [dev for dev in devices if dev.is_virtual]:
        hash_value = (dev.axis_count, dev.button_count, dev.hat_count)
        syslog.debug(
            "vJoy guid={}: {}".format(dev.device_guid, hash_value)
        )

        # Only unique combinations of axes, buttons, and hats are allowed
        # for vJoy devices
        if hash_value in vjoy_lookup:
            raise error.GremlinError(
                "Indistinguishable vJoy devices present.\n\n"
                "vJoy devices have to differ in the number of "
                "(at least one of) axes, buttons, or hats in order to work "
                "properly with Joystick Gremlin."
            )

        vjoy_lookup[hash_value] = dev

    # Query all vJoy devices in sequence until all have been processed and
    # their matching SDL counterparts have been found.
    vjoy_proxy = VJoyProxy()
    should_terminate = False
    for i in range(1, 17):
        # Only process devices that actually exist
        if not vjoy.device_exists(i):
            continue

        # Compute a hash for the vJoy device and match it against the SDL
        # device hashes
        hash_value = (
            vjoy.axis_count(i),
            vjoy.button_count(i),
            vjoy.hat_count(i)
        )

        if not vjoy.hat_configuration_valid(i):
            error_string = "vJoy id {:d}: Hats are set to discrete but have " \
                           "to be set as continuous.".format(i)
            syslog.debug(error_string)
            util.display_error(error_string)

        # As we are ensured that no duplicate vJoy devices exist from
        # the previous step we can directly link the SDL and vJoy device
        if hash_value in vjoy_lookup:
            vjoy_lookup[hash_value].set_vjoy_id(i)
            syslog.debug("vjoy id {:d}: {} - MATCH".format(i, hash_value))
        else:
            should_terminate = True
            syslog.debug(
                "vjoy id {:d}: {} - ERROR - vJoy device exists "
                "but DILL does not see it".format(i, hash_value)
            )

        # If the device can be acquired, configure the mapping from
        # vJoy axis id, which may not be sequential, to the
        # sequential SDL axis id
        if hash_value in vjoy_lookup:
            try:
                vjoy_dev = vjoy_proxy[i]
            except error.VJoyError as e:
                syslog.debug("vJoy id {:} can't be acquired".format(i))

    if should_terminate:
        raise error.GremlinError(
            "Unable to match vJoy devices to windows devices."
        )

    # Reset all devices so we don't hog the ones we aren't actually using
    vjoy_proxy.reset()

    # Update device list which will be used when queries for joystick devices
    # are made. Order the devices such that vJoy devices are last and the
    # physical devices are ordered by name.
    sorted_devices = sorted(
        [dev for dev in devices if not dev.is_virtual],
        key=lambda x: x.name
    )
    sorted_devices.extend(sorted(
        [dev for dev in devices if dev.is_virtual],
        key=lambda x: x.vjoy_id
    ))

    _joystick_devices = sorted_devices
    _joystick_init_lock.release()


def keyboard(key_name: str, mode: str) -> Callable:
    """Decorator for keyboard key callbacks.

    Args:
        key_name: name of key triggering the callback
        mode: mode in which this callback is active
    """

    def wrap(callback):

        @functools.wraps(callback)
        def wrapper_fn(*args, **kwargs):
            callback(*args, **kwargs)

        key = gremlin.keyboard.key_from_name(key_name)
        event = event_handler.Event.from_key(key)
        callback_registry.add(wrapper_fn, event, mode)

        return wrapper_fn

    return wrap


def periodic(interval: float) -> Callable:
    """Decorator for periodic function callbacks.

    Args:
        interval: the duration between executions of the function
    """

    def wrap(callback):

        @functools.wraps(callback)
        def wrapper_fn(*args, **kwargs):
            callback(*args, **kwargs)

        periodic_registry.add(wrapper_fn, interval)

        return wrapper_fn

    return wrap


def deadzone(
        value: float,
        low: float,
        low_center: float,
        high_center: float,
        high: float
) -> float:
    """Returns the mapped value taking the provided deadzone into
    account.

    The following relationship between the limits has to hold.
    -1 <= low < low_center <= 0 <= high_center < high <= 1

    Args:
        value: the raw input value
        low: low deadzone limit
        low_center: lower center deadzone limit
        high_center: upper center deadzone limit
        high: high deadzone limit

    Returns:
        Corrected value
    """
    if value >= 0:
        return min(1.0, max(0.0, (value - high_center) / abs(high - high_center)))
    else:
        return max(-1.0, min(0.0, (value - low_center) / abs(low - low_center)))


def format_input(event: event_handler.Event) -> str:
    """Formats the input specified by the device and event into a string.

    Args:
        event: event to format

    Returns:
        Textual representation of the event
    """
    # Retrieve the device instance belonging to this event
    device = None
    for dev in joystick_devices():
        if dev.device_guid == event.device_guid:
            device = dev
            break

    # Retrieve device name
    label = ""
    if device is None:
        logging.warning(
            f"Unable to find a device with GUID {str(event.device_guid)}"
        )
        label = "Unknown"
    else:
        label = device.name

    # Retrive input name
    label += " - "
    label += gremlin.common.input_to_ui_string(
        event.event_type,
        event.identifier
    )

    return label
