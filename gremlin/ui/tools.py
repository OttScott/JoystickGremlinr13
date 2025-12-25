# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

import logging
import uuid

from PySide6 import QtCore
from PySide6 import QtQml

import dill
from gremlin import auto_mapper, swap_devices
from gremlin.ui import backend
from gremlin.ui.profile_devices_model import ProfileDeviceListModel

QML_IMPORT_NAME = "Gremlin.Tools"
QML_IMPORT_MAJOR_VERSION = 1


@QtQml.QmlElement
class Tools(QtCore.QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

    @QtCore.Slot(str, dict, dict, bool, bool, result=str)
    def createMappings(
        self, mode, physical_devices, vjoy_devices, overwrite, repeat
    ) -> str:
        """
        Create mappings between physical and vJoy devices.

        Args:
            physical_devices: Dictionary of {device_guid: is_selected} for physical devices
            vjoy_devices: Dictionary of {vjoy_id: is_selected} for vJoy devices
            overwrite: Whether to overwrite existing mappings
            repeat: Whether to repeat vJoy mappings

        Returns:
            A string report for the user summarizing new mappings.
        """
        logging.getLogger("system").info(
            f"Creating mappings from physical devices {physical_devices} to vJoy devices "
            f" {vjoy_devices}, options overwrite: {overwrite}, repeat: {repeat}"
        )
        mapper = auto_mapper.AutoMapper(backend.Backend().profile)
        return mapper.generate_mappings(
            [
                dill.GUID.from_str(guid)
                for (guid, chosen) in physical_devices.items()
                if chosen
            ],
            [int(vjoy_id) for (vjoy_id, chosen) in vjoy_devices.items() if chosen],
            auto_mapper.AutoMapperOptions(mode, repeat, overwrite),
        )

    @QtCore.Slot(str, str, result=str)
    def swapDevices(self, source_device_uuid: str, target_device_uuid: str) -> str:
        """
        Swaps the specified two devices in the profile.

        Args:
            source_device_uuid: The UUID of the source (from profile) device.
            target_device_uuid: The UUID of the target (connected) device.

        Returns:
            The number of action and input swaps performed.
        """
        logging.getLogger("system").info(
            f"Swapping devices {source_device_uuid} and {target_device_uuid}"
        )
        result = swap_devices.swap_devices(
            backend.Backend().profile,
            uuid.UUID(source_device_uuid),
            uuid.UUID(target_device_uuid),
        )
        return result.as_string()
