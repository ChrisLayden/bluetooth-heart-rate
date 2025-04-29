//
//  ContentView.swift
//  BluetoothHeartRateMonitor
//
//  Created by Christopher Layden on 4/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject var bluetoothManager = BluetoothManager()

    var body: some View {
        VStack {
            Text(bluetoothManager.deviceName)
                .font(.title)
                .padding()

            Text("Heart Rate: \(bluetoothManager.heartRate) bpm")
                .font(.largeTitle)
                .padding()
                .foregroundColor(.red)
                .bold()
        }
        .onAppear {
            // Any setup when the view appears
        }
    }
}

#Preview {
    ContentView()
}
