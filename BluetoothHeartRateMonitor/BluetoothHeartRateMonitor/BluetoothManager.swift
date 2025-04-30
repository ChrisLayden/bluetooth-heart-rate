//
//  BluetoothManager.swift
//  BluetoothHeartRateMonitor
//
//  Created by Christopher Layden on 4/28/25.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral?
    
    @Published var latestHeartRate: Int? = nil
    
    // Heart Rate Service UUID (standardized by Bluetooth SIG)
    private let heartRateServiceCBUUID = CBUUID(string: "180D")
    private let heartRateMeasurementCBUUID = CBUUID(string: "2A37")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Called when Bluetooth state changes
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is ON. Scanning for heart rate monitors...")
            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID], options: nil)
        default:
            print("Bluetooth is not available: \(central.state.rawValue)")
        }
    }

    // Found a peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(peripheral.name ?? "Unknown Device")")

        // Stop scanning and connect
        self.heartRatePeripheral = peripheral
        self.heartRatePeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    // Connected to peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "device"). Discovering services...")
        peripheral.discoverServices([heartRateServiceCBUUID])
    }

    // Discovered services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid)")
            if service.uuid == heartRateServiceCBUUID {
                peripheral.discoverCharacteristics([heartRateMeasurementCBUUID], for: service)
            }
        }
    }

    // Discovered characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == heartRateMeasurementCBUUID {
                print("Found heart rate measurement characteristic. Subscribing...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    // Received heart rate update
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if characteristic.uuid == heartRateMeasurementCBUUID,
           let data = characteristic.value {
            let bpm = parseHeartRate(from: data)
            DispatchQueue.main.async {
                self.latestHeartRate = bpm
            }
            print("Heart Rate: \(bpm) BPM")
        }
    }

    // Parse heart rate from raw BLE data
    private func parseHeartRate(from data: Data) -> Int {
        let byteArray = [UInt8](data)
        let flag = byteArray[0]
        let isHeartRateInUInt16 = (flag & 0x01) == 1
        if isHeartRateInUInt16 {
            return Int(UInt16(byteArray[1]) | UInt16(byteArray[2]) << 8)
        } else {
            return Int(byteArray[1])
        }
    }
}
