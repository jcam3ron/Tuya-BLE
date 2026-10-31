"""Check local configuration using Nix dependencies without runtime pip installs."""

import asyncio
import os

from homeassistant import loader
from homeassistant.config_entries import ConfigEntries
from homeassistant.core import HomeAssistant
from homeassistant.helpers import area_registry, device_registry, entity_registry
from homeassistant.helpers import issue_registry
from homeassistant.helpers.check_config import async_check_ha_config_file


async def main():
    hass = HomeAssistant(os.environ["HA_DEV_CONFIG"])
    hass.config.skip_pip = True
    loader.async_setup(hass)
    hass.config_entries = ConfigEntries(hass, {})
    try:
        await hass.config_entries.async_initialize()
        device_registry.async_setup(hass)
        await area_registry.async_load(hass)
        await device_registry.async_load(hass)
        await entity_registry.async_load(hass)
        await issue_registry.async_load(hass, read_only=True)
        result = await async_check_ha_config_file(hass)
        for warning in result.warnings:
            print(f"Warning: {warning.message}")
        for error in result.errors:
            print(f"Error: {error.message}")
        if not result.errors:
            print("Home Assistant configuration is valid.")
        return bool(result.errors)
    finally:
        await hass.async_stop(force=True)


raise SystemExit(asyncio.run(main()))
