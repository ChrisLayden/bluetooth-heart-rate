//
//  BluetoothManager.swift
//  BluetoothHeartRateMonitor
//
//  Created by Christopher Layden on 4/28/25.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var heartRateMonitor: CBPeripheral?

    @Published var deviceName: String = "Searching for Heart Monitor..."
    @Published var heartRate: Int = 0 // Heart rate value to display

    let heartRateServiceUUID = CBUUID(string: "180D")
    let heartRateMeasurementCharacteristicUUID = CBUUID(string: "2A37") // Heart Rate Measurement Characteristic

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is On. Scanning...")
            centralManager.scanForPeripherals(withServices: [heartRateServiceUUID], options: nil)
        } else {
            print("Bluetooth not available")
            deviceName = "Bluetooth not available"
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        print("Discovered: \(peripheral.name ?? "Unknown Device")")
        heartRateMonitor = peripheral
        heartRateMonitor?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.name ?? "Unknown")")
        deviceName = "Connected to: \(peripheral.name ?? "Unknown")"

        // Discover services
        heartRateMonitor?.discoverServices([heartRateServiceUUID])
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("Failed to connect")
        deviceName = "Failed to connect"
    }

    // Discover characteristics after services are discovered
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == heartRateServiceUUID {
                    peripheral.discoverCharacteristics([heartRateMeasurementCharacteristicUUID], for: service)
                }
            }
        }
    }

    // Handle characteristics (heart rate data)
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if service.uuid == heartRateServiceUUID {
            for characteristic in service.characteristics ?? [] {
                if characteristic.uuid == heartRateMeasurementCharacteristicUUID {
                    peripheral.setNotifyValue(true, for: characteristic) // Start notifications
                }
            }
        }
    }

    // Receive heart rate data from the monitor
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if characteristic.uuid == heartRateMeasurementCharacteristicUUID {
            // Parse the heart rate data
            if let heartRateData = characteristic.value {
                let heartRateValue = parseHeartRateData(data: heartRateData)
                DispatchQueue.main.async {
                    self.heartRate = heartRateValue // Update heart rate on the main thread
                }
            }
        }
    }

    // Parse the heart rate data (assuming it's in the standard format for HRM)
    func parseHeartRateData(data: Data) -> Int {
        var heartRate = 0

        // The heart rate data format is usually 1 byte for flags, and 1 byte for the heart rate
        if data.count > 1 {
            heartRate = Int(data[1]) // The heart rate is in the second byte
        }
        return heartRate
    }
}
