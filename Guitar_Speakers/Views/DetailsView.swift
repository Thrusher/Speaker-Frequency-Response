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
    
    @State private var selectedPoint: FrequencyResponsePoint?
    @State private var interactionLocation: CGPoint = .zero

    let speaker: Speaker

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text(speaker.description)
                Text("Resonance Frequency: \(speaker.resonanceFrequency)")
                Text("Sensitivity: \(speaker.sensitivity)")
                Text("Selected Hz: \(Int(selectedPoint?.frequency ?? 0)), dB: \(Int(selectedPoint?.spl ?? 0))")
                    .font(.title)
                    .padding(5)
                    .background(Color.white.opacity(0.8))
            }
            .font(.body)
            .padding()
            GeometryReader { geometry in
                Chart(speaker.frequesncyResponse) { point in
                    LineMark(
                        x: .value("Frequency (Hz)", normalizeFrequency(point.frequency)),
                        y: .value("Sound Pressure (dB)", point.spl)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.teal]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    PointMark(
                        x: .value("Frequency (Hz)", normalizeFrequency(point.frequency)),
                        y: .value("Sound Pressure (dB)", point.spl)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(15)
                }
                .chartXScale(domain: 0...3.2)
                .chartYScale(domain: 50...110)
                .chartXAxis {
                    AxisMarks(values: generateLogarithmicXAxis()) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(denormalizeFrequency(doubleValue))
                            }
                        }
                        .foregroundStyle(.black)
                        AxisGridLine()
                            .foregroundStyle(.gray)
                        AxisTick()
                    }
                }
                .chartYAxis() {
                    AxisMarks(position: .leading, values: .stride(by: 10)) {
                        AxisValueLabel()
                            .foregroundStyle(.black)
                        AxisGridLine()
                            .foregroundStyle(.black)
                        AxisTick()
                    }
                }
                .chartXAxisLabel("Frequency (Hz)", position: .bottom)
                .chartYAxisLabel("Sound Pressure (dB)", position: .leading)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            interactionLocation = value.location
                            if let closestPoint = findClosestPoint(to: interactionLocation.x, in: speaker.frequesncyResponse, chartSize: geometry.size) {
                                selectedPoint = closestPoint
                            }
                        }
                )
                .onTapGesture { location in
                    interactionLocation = location
                    if let closestPoint = findClosestPoint(to: interactionLocation.x, in: speaker.frequesncyResponse, chartSize: geometry.size) {
                        selectedPoint = closestPoint
                    }
                }
            }
            .padding()
        }
        .navigationTitle(speaker.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helper Functions
    
    private func findClosestPoint(to x: CGFloat, in points: [FrequencyResponsePoint], chartSize: CGSize) -> FrequencyResponsePoint? {
        let normalizedX = (x / chartSize.width) * (20_000 - 20) + 20
        let closest = points.min(by: { abs($0.frequency - normalizedX) < abs($1.frequency - normalizedX) })
        return closest
    }
    
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
