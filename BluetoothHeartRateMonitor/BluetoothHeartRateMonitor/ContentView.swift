//
//  ContentView.swift
//  BluetoothHeartRateMonitor
//
//  Created by Christopher Layden on 4/28/25.
//

import SwiftUI
import Charts

struct HeartRateSample: Identifiable {
    let id = UUID()
    let time: Date
    let bpm: Int
}

struct ContentView: View {
    @StateObject var bluetoothManager = BluetoothManager()
    
    @State private var isRecording = false
    @State private var recordedData: [HeartRateSample] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // 🫀 Live Heart Rate Display (always visible)
            if let bpm = bluetoothManager.latestHeartRate {
                Text("❤️ Heart Rate: \(bpm) BPM")
                    .font(.largeTitle)
                    .bold()
            } else {
                Text("Looking for heart rate...")
                    .foregroundColor(.gray)
            }

            // 🎛 Start/Stop Recording Button
            Button(action: {
                isRecording.toggle()
                if isRecording {
                    recordedData = [] // Reset data
                }
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // 📈 Heart Rate vs Time Chart (only when recording data)
            if !recordedData.isEmpty {
                Chart(recordedData) { sample in
                    LineMark(
                        x: .value("Time", sample.time),
                        y: .value("Heart Rate", sample.bpm)
                    )
                }
                .chartYScale(domain: 40...180)
                .frame(height: 300)
                .padding(.top)
            } else {
                Text("No recorded data yet.")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onReceive(bluetoothManager.$latestHeartRate) { newBPM in
            if isRecording, let bpm = newBPM {
                recordedData.append(HeartRateSample(time: Date(), bpm: bpm))
            }
        }
    }
}
