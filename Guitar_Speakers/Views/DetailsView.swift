//
//  DetailsView.swift
//  Guitar_Speakers
//
//  Created by Patryk Drozd on 01/01/2025.
//

import SwiftUI
import Charts

struct DetailsView: View {
    
    enum Constants {
        static let low = (min: 20.0, max: 200.0, step: 20.0)
        static let mid = (min: 200.0, max: 2_000.0, step: 200.0)
        static let high = (min: 2_000.0, max: 20_000.0, step: 2_000.0)
    }
    
    let speaker: Speaker

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(speaker.description)
                Text("Resonance Frequency: \(speaker.resonanceFrequency)")
                Text("Sensitivity: \(speaker.sensitivity)")
            }
            .font(.body)
            .padding()
            Chart(speaker.frequesncyResponse) { point in
                LineMark(
                    x: .value("Frequency (Hz)", normalizeFrequency(point.frequency)),
                    y: .value("Sound Pressure (dB)", point.spl)
                )
                .foregroundStyle(.red)
            }
            .padding()
            .chartXScale(domain: 0...3.2)
            .chartXAxis {
                AxisMarks(values: generateLogarithmicXAxis()) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(denormalizeFrequency(doubleValue))
                        }
                    }
                    .foregroundStyle(.black)
                    AxisGridLine()
                        .foregroundStyle(.black)
                    AxisTick()
                }
            }
            .chartYScale(domain: 50...110) // Standard scale for Y-axis
            .chartYAxis() {
                AxisMarks(position: .leading, values: .stride(by: 10)) {
                    AxisValueLabel()
                        .foregroundStyle(.black)
                    AxisGridLine()
                        .foregroundStyle(.black)
                    AxisTick()
                }
            }
        }
        .navigationTitle(speaker.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helper Functions

    private func normalizeFrequency(_ frequency: Double) -> Double {
        func logNormalize(_ value: Double, range: (min: Double, max: Double), offset: Double) -> Double {
            return offset + (log10(value) - log10(range.min)) / (log10(range.max) - log10(range.min))
        }
        
        switch frequency {
        case ...Constants.low.max:
            return logNormalize(frequency, range: (Constants.low.min, Constants.low.max), offset: 0)
        case ...Constants.mid.max:
            return logNormalize(frequency, range: (Constants.mid.min, Constants.mid.max), offset: 1)
        default:
            return logNormalize(frequency, range: (Constants.high.min, Constants.high.max), offset: 2)
        }
    }
    
    private func denormalizeFrequency(_ value: Double) -> String {
        switch value {
        case normalizeFrequency(Constants.low.min):
            return format(frequency: Constants.low.min)
        case normalizeFrequency(Constants.low.max):
            return format(frequency: Constants.low.max)
        case normalizeFrequency(Constants.mid.max):
            return format(frequency: Constants.mid.max)
        case normalizeFrequency(Constants.high.max):
            return format(frequency: Constants.high.max)
        default:
            return ""
        }
    }
    
    private func format(frequency: Double) -> String {
        if frequency >= 1_000 {
            let kiloHertz = frequency / 1_000
            return "\(Int(kiloHertz))k"
        } else {
            return "\(Int(frequency))"
        }
    }
    
    private func generateLogarithmicXAxis() -> [Double] {
        let sections = [Constants.low, Constants.mid, Constants.high]
        return sections.flatMap { range in
            stride(from: range.min, through: range.max, by: range.step).map {
                normalizeFrequency($0)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailsView(speaker: Speaker.mockSpeakers.first!)
    }
}
