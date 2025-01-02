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
            }
            .font(.body)
            .padding()
            GeometryReader { geometry in
                Chart {
                    ForEach(speaker.frequesncyResponse) { point in
                        LineMark(
                            x: .value("Frequency (Hz)", normalizeFrequency(point.frequency)),
                            y: .value("Sound Pressure (dB)", point.spl)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.teal)
                    }
                    
                    if let selectedPoint {
                        PointMark(
                            x: .value("Frequency (Hz)", normalizeFrequency(selectedPoint.frequency)),
                            y: .value("Sound Pressure (dB)", selectedPoint.spl)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
                        
                        RuleMark(x: .value("Frequency (Hz)", normalizeFrequency(selectedPoint.frequency)))
                            .foregroundStyle(.orange)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        
                        RuleMark(y: .value("Sound Pressure (dB)", selectedPoint.spl))
                            .foregroundStyle(.orange)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }
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
                            .foregroundStyle(.gray)
                        AxisTick()
                    }
                }
                .chartXAxisLabel("Frequency (Hz)", position: .bottom)
                .chartYAxisLabel("Sound Pressure (dB)", position: .leading)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            updateSelectedPoint(from: value.location, chartSize: geometry.size)
                        }
                )
                .onTapGesture { location in
                    updateSelectedPoint(from: location, chartSize: geometry.size)
                }
            }
            .padding()
        }
        .navigationTitle(speaker.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: speaker) {
            selectedPoint = nil
        }
    }

    // MARK: - Helper Functions
    
    private func updateSelectedPoint(from location: CGPoint, chartSize: CGSize) {
        let normalizedX = (location.x / chartSize.width) * 3.2
        let frequency: Double
        if normalizedX <= 1.0 {
            frequency = pow(10, log10(Constants.low.min) + normalizedX * (log10(Constants.low.max) - log10(Constants.low.min)))
        } else if normalizedX <= 2.0 {
            let offsetX = normalizedX - 1.0
            frequency = pow(10, log10(Constants.mid.min) + offsetX * (log10(Constants.mid.max) - log10(Constants.mid.min)))
        } else {
            let offsetX = normalizedX - 2.0
            frequency = pow(10, log10(Constants.high.min) + offsetX * (log10(Constants.high.max) - log10(Constants.high.min)))
        }

        guard let lowerPoint = speaker.frequesncyResponse.last(where: { $0.frequency <= frequency }),
              let upperPoint = speaker.frequesncyResponse.first(where: { $0.frequency > frequency }) else {
            return
        }

        if lowerPoint.frequency == frequency {
            selectedPoint = lowerPoint
            return
        } else if upperPoint.frequency == frequency {
            selectedPoint = upperPoint
            return
        }

        let slope = (upperPoint.spl - lowerPoint.spl) / (upperPoint.frequency - lowerPoint.frequency)
        let interpolatedSPL = lowerPoint.spl + slope * (frequency - lowerPoint.frequency)

        selectedPoint = FrequencyResponsePoint(frequency: frequency, spl: interpolatedSPL)
    }
    
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
