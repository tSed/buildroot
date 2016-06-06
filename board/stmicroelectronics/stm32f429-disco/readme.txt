STM32F429 Discovery
===================

This tutorial describes how to use the predefined Buildroot
configuration for the STM32F429 Discovery evaluation platform.

Building
--------

  make stm32f429_disco_defconfig
  make

Wire the UART
-------------

Use a USB to TTL adapter, and connect:

 - RX to PA9 (or the RX pin on the stm32f429i-disc1 board)
 - TX to PA10 (or the TX pin on the stm32f429i-disc1 board)
 - GND to one of the GND available on the board

The UART is configured at 115200.

Flashing
--------

  ./board/stmicroelectronics/stm32f429-disco/flash.sh output/ \
      {stm32f429discovery|stm32f429disc1}

It will flash the minimal bootloader, the Device Tree Blob, and the
kernel image which includes the root filesystem as initramfs.
