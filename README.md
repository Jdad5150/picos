# Pico Controllers

Raspberry Pi Pico-based motor controller system for precise coordinate-driven actuation via UART.

## Overview

This project implements firmware for multiple Raspberry Pi Pico microcontrollers that receive coordinate commands over UART and control stepper motors or other actuators. Each controller can have custom actuation logic while sharing common coordinate parsing and communication infrastructure.

## Features

- **UART Communication**: Receives commands at 115200 baud
- **Coordinate Parsing**: Splits floating-point coordinates into whole and decimal parts for precise control
- **LED Visualization**: Blink patterns for testing without hardware (temporary)
- **Modular Design**: Shared parsing logic with controller-specific actuation
- **Zero-cost Abstractions**: Written in Zig for embedded systems

## Hardware Requirements

- Raspberry Pi Pico (RP2040)
- UART connection (GPIO0=TX, GPIO1=RX)
- Stepper motors or actuators (controller-specific)

## Building

Requires [Zig](https://ziglang.org/) and [MicroZig](https://github.com/ZigEmbeddedGroup/microzig).

```bash
# Build firmware
zig build

# Output: zig-out/firmware/pico_controller.uf2
```

## Flashing

1. Hold BOOTSEL button on Pico while connecting USB
2. Copy `pico_controller.uf2` to the mounted drive
3. Pico will reboot and run the firmware

## Testing

```bash
# Run unit tests
zig test src/CoordinateValue.zig

# Generate documentation
zig build-lib -femit-docs -fno-emit-bin src/CoordinateValue.zig
```

## Protocol

Send coordinate values as ASCII floats terminated by newline:

```
3.14\n      # Parsed as: whole=3, decimals=[1,4,0]
-123.456\n  # Parsed as: whole=-123, decimals=[4,5,6]
```

Special commands:
- `on` - Turn LED on
- `off` - Turn LED off
- `toggle` - Toggle LED

## Project Structure

```
src/
  main.zig            # UART handling and main loop
  CoordinateValue.zig # Coordinate parsing logic
  controller1.zig     # Controller 1 actuation (TODO)
  controller2.zig     # Controller 2 actuation (TODO)
  controller3.zig     # Controller 3 actuation (TODO)
```

## License

MIT
