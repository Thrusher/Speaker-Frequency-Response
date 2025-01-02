//
//  Item.swift
//  Guitar_Speakers
//
//  Created by Patryk Drozd on 01/01/2025.
//

import SwiftData
import Foundation

struct FrequencyResponsePoint: Hashable, Equatable, Identifiable {
    var id = UUID()
    let frequency: Double
    let spl: Double
    
    init(frequency: Double, spl: Double) {
        self.frequency = frequency
        self.spl = spl
    }
    
    static func == (lhs: FrequencyResponsePoint, rhs: FrequencyResponsePoint) -> Bool {
        return lhs.frequency == rhs.frequency &&
               lhs.spl == rhs.spl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(frequency)
        hasher.combine(spl)
    }
}

struct Speaker: Hashable, Equatable, Identifiable {
    var id = UUID()
    let name: String
    let resonanceFrequency: Int
    let sensitivity: Int
    let description: String // Added for additional information
    let frequesncyResponse: [FrequencyResponsePoint]
    
    init(name: String,
         resonanceFrequency: Int,
         sensitivity: Int,
         description: String,
         frequesncyResponse: [FrequencyResponsePoint]) {
        self.name = name
        self.resonanceFrequency = resonanceFrequency
        self.sensitivity = sensitivity
        self.description = description
        self.frequesncyResponse = frequesncyResponse
    }
    
    static func == (lhs: Speaker, rhs: Speaker) -> Bool {
        return lhs.name == rhs.name &&
               lhs.resonanceFrequency == rhs.resonanceFrequency &&
               lhs.sensitivity == rhs.sensitivity &&
               lhs.description == rhs.description &&
               lhs.frequesncyResponse == rhs.frequesncyResponse
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(resonanceFrequency)
        hasher.combine(sensitivity)
        hasher.combine(description)
        hasher.combine(frequesncyResponse)
    }
}

extension Speaker {
    private static func generateSpeakerFrequencyResponse(
        name: String,
        resonanceFrequency: Int,
        sensitivity: Int,
        description: String,
        baseCurve: [(Double, Double)]
    ) -> Speaker {
        let lowRange = stride(from: 20.0, through: 200.0, by: 10.0)
        let midRange = stride(from: 200.0, through: 2000.0, by: 70.0)
        let highRange = stride(from: 2000.0, through: 20_000.0, by: 800.0)

        let interpolatedCurve = (Array(lowRange) + Array(midRange) + Array(highRange)).map { frequency in
            let matchingPoints = baseCurve.filter { $0.0 <= frequency }
            guard let lastPoint = matchingPoints.last, let nextPoint = baseCurve.first(where: { $0.0 > frequency }) else {
                return FrequencyResponsePoint(frequency: frequency, spl: matchingPoints.last?.1 ?? 80)
            }
            let slope = (nextPoint.1 - lastPoint.1) / (nextPoint.0 - lastPoint.0)
            let spl = lastPoint.1 + slope * (frequency - lastPoint.0)
            return FrequencyResponsePoint(frequency: frequency, spl: spl + generateRandomness())
        }

        return Speaker(
            name: name,
            resonanceFrequency: resonanceFrequency,
            sensitivity: sensitivity,
            description: description,
            frequesncyResponse: interpolatedCurve
        )
    }

    private static func generateRandomness() -> Double {
        Double.random(in: -0.5...0.5)
    }

    static let mockSpeakers: [Speaker] = [
        generateSpeakerFrequencyResponse(
            name: "A-Type",
            resonanceFrequency: 85,
            sensitivity: 97,
            description: "Warm, rounded tone suitable for blues and classic rock.",
            baseCurve: [
                (20, 70), (100, 85), (500, 95), (1_000, 98),
                (2_000, 95), (5_000, 90), (10_000, 80), (20_000, 75)
            ]
        ),
        generateSpeakerFrequencyResponse(
            name: "Classic Lead 80",
            resonanceFrequency: 85,
            sensitivity: 98,
            description: "Punchy midrange and tight lows, great for solos.",
            baseCurve: [
                (20, 68), (100, 84), (500, 94), (1_000, 97),
                (2_000, 93), (5_000, 88), (10_000, 78), (20_000, 72)
            ]
        ),
        generateSpeakerFrequencyResponse(
            name: "Seventy 80",
            resonanceFrequency: 90,
            sensitivity: 96,
            description: "Bright and articulate with a modern voice.",
            baseCurve: [
                (20, 66), (100, 82), (500, 92), (1_000, 95),
                (2_000, 92), (5_000, 86), (10_000, 76), (20_000, 70)
            ]
        ),
        generateSpeakerFrequencyResponse(
            name: "Blue Alnico",
            resonanceFrequency: 75,
            sensitivity: 100,
            description: "Iconic vintage tone with smooth highs and rich lows.",
            baseCurve: [
                (20, 72), (100, 88), (500, 98), (1_000, 100),
                (2_000, 97), (5_000, 91), (10_000, 81), (20_000, 76)
            ]
        ),
        generateSpeakerFrequencyResponse(
            name: "G12M-65 Creamback",
            resonanceFrequency: 85,
            sensitivity: 97,
            description: "Balanced sound with creamy mids and tight lows.",
            baseCurve: [
                (20, 69), (100, 86), (500, 96), (1_000, 99),
                (2_000, 96), (5_000, 89), (10_000, 79), (20_000, 73)
            ]
        ),
        generateSpeakerFrequencyResponse(
            name: "G12M Greenback",
            resonanceFrequency: 75,
            sensitivity: 98,
            description: "Classic rock speaker with crunchy mids and sweet highs.",
            baseCurve: [
                (20, 65), (100, 83), (500, 93), (1_000, 96),
                (2_000, 93), (5_000, 87), (10_000, 77), (20_000, 71)
            ]
        )
    ]
}
