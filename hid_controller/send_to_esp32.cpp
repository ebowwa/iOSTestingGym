/*
 * Send commands to ESP32-S3 HID Controller
 * Compile: g++ send_to_esp32.cpp -lcurl -o send_to_esp32
 */

#include <iostream>
#include <string>
#include <curl/curl.h>

class ESP32Controller {
private:
    std::string esp32_ip;
    CURL* curl;
    
public:
    ESP32Controller(const std::string& ip) : esp32_ip(ip) {
        curl = curl_easy_init();
    }
    
    ~ESP32Controller() {
        if (curl) curl_easy_cleanup(curl);
    }
    
    void sendCommand(const std::string& json) {
        if (!curl) return;
        
        std::string url = "http://" + esp32_ip + ":8080";
        
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json.c_str());
        
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            std::cerr << "Failed to send: " << curl_easy_strerror(res) << std::endl;
        } else {
            std::cout << "Sent: " << json << std::endl;
        }
    }
    
    void click(float x, float y) {
        std::string json = "{\"type\":\"click\",\"x\":" + std::to_string(x) + 
                          ",\"y\":" + std::to_string(y) + "}";
        sendCommand(json);
    }
    
    void executeHomeButton() {
        // Send the home button recording
        std::string json = R"({
            "type": "recording",
            "actions": [
                {"type": "click", "x": 0.5, "y": 0.05},
                {"type": "wait", "ms": 500},
                {"type": "click", "x": 0.85, "y": 0.02},
                {"type": "wait", "ms": 1000}
            ]
        })";
        sendCommand(json);
    }
};

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "Usage: " << argv[0] << " <ESP32_IP>" << std::endl;
        std::cout << "Example: " << argv[0] << " 192.168.1.100" << std::endl;
        return 1;
    }
    
    ESP32Controller controller(argv[1]);
    
    std::cout << "ESP32-S3 Controller" << std::endl;
    std::cout << "===================" << std::endl;
    std::cout << "Commands:" << std::endl;
    std::cout << "  h - Execute home button" << std::endl;
    std::cout << "  c - Click center" << std::endl;
    std::cout << "  q - Quit" << std::endl;
    std::cout << std::endl;
    
    char cmd;
    while (true) {
        std::cout << "> ";
        std::cin >> cmd;
        
        if (cmd == 'q') break;
        
        switch(cmd) {
            case 'h':
                controller.executeHomeButton();
                break;
            case 'c':
                controller.click(0.5, 0.5);
                break;
            default:
                std::cout << "Unknown command" << std::endl;
        }
    }
    
    return 0;
}