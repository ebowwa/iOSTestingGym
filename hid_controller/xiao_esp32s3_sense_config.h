/*
 * Configuration for Seeed Studio XIAO ESP32S3 Sense
 * 
 * Board Specifications:
 * - ESP32-S3R8 (8MB PSRAM)
 * - 8MB Flash
 * - OV2640 Camera (we won't use this)
 * - USB-C connector
 * - Built-in LED on GPIO21
 * - Charge LED on GPIO13
 */

#ifndef XIAO_ESP32S3_SENSE_CONFIG_H
#define XIAO_ESP32S3_SENSE_CONFIG_H

// Pin definitions for XIAO ESP32S3 Sense
#define BUILTIN_LED 21      // User LED (orange)
#define CHARGE_LED 13       // Charge LED (yellow)

// USB Settings for HID
#define USB_MANUFACTURER "Seeed Studio"
#define USB_PRODUCT "XIAO ESP32S3 HID"
#define USB_SERIAL "12345678"

// Camera pins (not used for HID, but good to know)
#define CAMERA_PIN_PWDN -1
#define CAMERA_PIN_RESET -1
#define CAMERA_PIN_XCLK 10
#define CAMERA_PIN_SIOD 40
#define CAMERA_PIN_SIOC 39
#define CAMERA_PIN_D7 48
#define CAMERA_PIN_D6 11
#define CAMERA_PIN_D5 12
#define CAMERA_PIN_D4 14
#define CAMERA_PIN_D3 16
#define CAMERA_PIN_D2 18
#define CAMERA_PIN_D1 17
#define CAMERA_PIN_D0 15
#define CAMERA_PIN_VSYNC 38
#define CAMERA_PIN_HREF 47
#define CAMERA_PIN_PCLK 13

#endif