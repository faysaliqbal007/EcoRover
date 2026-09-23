/*
   ===================================================================
                    ECOROVER ESP32-CAM STREAMING NODE
   ===================================================================

   Target Board : AI-Thinker ESP32-CAM / GC2145 or OV2640 Sensor
   Role         : Dedicated wireless video streaming node (Station Mode)
   Network SSID : EcoRover (hosted by ESP32-S3 main controller at 192.168.4.1)
   Static IP    : 192.168.4.200
   Stream URL   : http://192.168.4.200/stream
   Snapshot URL : http://192.168.4.200/snapshot

   Integration Notes:
   - Operates as an independent node on the local EcoRover Wi-Fi network.
   - Requires regulated 5V power and common ground with the main chassis.
   - Low-latency single-buffer MJPEG HTTP chunked multipart stream.
   ===================================================================
*/

#include "esp_camera.h"
#include <WiFi.h>
#include "esp_timer.h"
#include "img_converters.h"
#include "Arduino.h"
#include "fb_gfx.h"
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "esp_http_server.h"

// -------------------------------------------------------------------
// Wi-Fi Configuration
// -------------------------------------------------------------------
const char* WIFI_SSID     = "EcoRover";
const char* WIFI_PASSWORD = "12345678";

IPAddress staticIP(192, 168, 4, 200);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);
IPAddress dns(192, 168, 4, 1);

// -------------------------------------------------------------------
// Camera Model Pin Definitions: AI-Thinker / GC2145 / OV2640
// -------------------------------------------------------------------
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27

#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// -------------------------------------------------------------------
// HTTP Multipart Stream Boundary
// -------------------------------------------------------------------
#define PART_BOUNDARY "123456789000000000000987654321"
static const char* _STREAM_CONTENT_TYPE = "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char* _STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char* _STREAM_PART = "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";

httpd_handle_t stream_httpd = NULL;

// -------------------------------------------------------------------
// MJPEG Stream Handler
// -------------------------------------------------------------------
static esp_err_t stream_handler(httpd_req_t *req) {
    camera_fb_t * fb = NULL;
    esp_err_t res = ESP_OK;
    size_t _jpg_buf_len = 0;
    uint8_t * _jpg_buf = NULL;
    char part_buf[64];

    res = httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
    if (res != ESP_OK) return res;

    httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");

    while (true) {
        fb = esp_camera_fb_get();
        if (!fb) {
            Serial.println("[CAM] Camera capture failed");
            res = ESP_FAIL;
        } else {
            if (fb->format != PIXFORMAT_JPEG) {
                bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &_jpg_buf_len);
                esp_camera_fb_return(fb);
                fb = NULL;
                if (!jpeg_converted) {
                    Serial.println("[CAM] JPEG compression failed");
                    res = ESP_FAIL;
                }
            } else {
                _jpg_buf_len = fb->len;
                _jpg_buf = fb->buf;
            }
        }

        if (res == ESP_OK) {
            size_t hlen = snprintf((char *)part_buf, 64, _STREAM_PART, _jpg_buf_len);
            res = httpd_resp_send_chunk(req, (const char *)part_buf, hlen);
        }
        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, (const char *)_jpg_buf, _jpg_buf_len);
        }
        if (res == ESP_OK) {
            res = httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY));
        }

        if (fb) {
            esp_camera_fb_return(fb);
            fb = NULL;
            _jpg_buf = NULL;
        } else if (_jpg_buf) {
            free(_jpg_buf);
            _jpg_buf = NULL;
        }

        if (res != ESP_OK) {
            break;
        }
        // Small yield to allow background Wi-Fi tasks to process
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    return res;
}

// -------------------------------------------------------------------
// Single Snapshot Handler
// -------------------------------------------------------------------
static esp_err_t capture_handler(httpd_req_t *req) {
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
        httpd_resp_send_500(req);
        return ESP_FAIL;
    }

    httpd_resp_set_type(req, "image/jpeg");
    httpd_resp_set_hdr(req, "Content-Disposition", "inline; filename=capture.jpg");
    httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");

    esp_err_t res = httpd_resp_send(req, (const char *)fb->buf, fb->len);
    esp_camera_fb_return(fb);
    return res;
}

// -------------------------------------------------------------------
// Start Web Server
// -------------------------------------------------------------------
void startCameraServer() {
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.server_port = 80;

    httpd_uri_t stream_uri = {
        .uri       = "/stream",
        .method    = HTTP_GET,
        .handler   = stream_handler,
        .user_ctx  = NULL
    };

    httpd_uri_t capture_uri = {
        .uri       = "/snapshot",
        .method    = HTTP_GET,
        .handler   = capture_handler,
        .user_ctx  = NULL
    };

    if (httpd_start(&stream_httpd, &config) == ESP_OK) {
        httpd_register_uri_handler(stream_httpd, &stream_uri);
        httpd_register_uri_handler(stream_httpd, &capture_uri);
        Serial.println("[CAM] Web server started on port 80");
        Serial.println("[CAM] Stream ready at: http://192.168.4.200/stream");
    }
}

// -------------------------------------------------------------------
// Setup & Initialization
// -------------------------------------------------------------------
void setup() {
    WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); // Disable brownout detector
    Serial.begin(115200);
    Serial.println("\n[CAM] ========================================");
    Serial.println("[CAM] EcoRover ESP32-CAM Streaming Node Initializing");
    Serial.println("[CAM] ========================================");

    camera_config_t config;
    config.ledc_channel = LEDC_CHANNEL_0;
    config.ledc_timer   = LEDC_TIMER_0;
    config.pin_d0       = Y2_GPIO_NUM;
    config.pin_d1       = Y3_GPIO_NUM;
    config.pin_d2       = Y4_GPIO_NUM;
    config.pin_d3       = Y5_GPIO_NUM;
    config.pin_d4       = Y6_GPIO_NUM;
    config.pin_d5       = Y7_GPIO_NUM;
    config.pin_d6       = Y8_GPIO_NUM;
    config.pin_d7       = Y9_GPIO_NUM;
    config.pin_xclk     = XCLK_GPIO_NUM;
    config.pin_pclk     = PCLK_GPIO_NUM;
    config.pin_vsync    = VSYNC_GPIO_NUM;
    config.pin_href     = HREF_GPIO_NUM;
    config.pin_sccb_sda = SIOD_GPIO_NUM;
    config.pin_sccb_scl = SIOC_GPIO_NUM;
    config.pin_pwdn     = PWDN_GPIO_NUM;
    config.pin_reset    = RESET_GPIO_NUM;
    config.xclk_freq_hz = 20000000;
    config.pixel_format = PIXFORMAT_JPEG;
    config.frame_size   = FRAMESIZE_VGA;   // 640x480 resolution (responsive and stable)
    config.jpeg_quality = 12;              // 10-63 lower number means higher quality
    config.fb_count     = 2;               // Double buffering for smooth framerate
    config.grab_mode    = CAMERA_GRAB_LATEST;

    // Camera Init
    esp_err_t err = esp_camera_init(&config);
    if (err != ESP_OK) {
        Serial.printf("[CAM] Camera init failed with error 0x%x\n", err);
        return;
    }
    Serial.println("[CAM] Camera sensor initialized successfully.");

    // Sensor Orientation Adjustments
    sensor_t * s = esp_camera_sensor_get();
    if (s != NULL) {
        s->set_vflip(s, 1);    // Adjust for rover mounting orientation
        s->set_hmirror(s, 0);
        s->set_brightness(s, 1);
        s->set_contrast(s, 1);
    }

    // Connect to EcoRover Wi-Fi AP
    WiFi.mode(WIFI_STA);
    if (!WiFi.config(staticIP, gateway, subnet, dns)) {
        Serial.println("[CAM] Static IP configuration failed.");
    }

    Serial.printf("[CAM] Connecting to Wi-Fi SSID '%s'...\n", WIFI_SSID);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 30) {
        delay(500);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("\n[CAM] Connected to EcoRover Network!");
        Serial.print("[CAM] Node IP Address: ");
        Serial.println(WiFi.localIP());
        startCameraServer();
    } else {
        Serial.println("\n[CAM] Wi-Fi connection timed out. Retrying in background...");
    }
}

void loop() {
    // Reconnect to AP if dropped
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[CAM] Wi-Fi link lost. Attempting reconnection...");
        WiFi.disconnect();
        WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
        vTaskDelay(pdMS_TO_TICKS(5000));
    } else {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
