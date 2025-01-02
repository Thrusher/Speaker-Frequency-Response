//
//  ContentView.swift
//  Guitar_Speakers
//
//  Created by Patryk Drozd on 01/01/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    private var speakers: [Speaker] = Speaker.mockSpeakers
    
    @State private var selectedSpeaker: Speaker?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSpeaker) {
                ForEach(speakers) { speaker in
                    NavigationLink(value: speaker) {
                        Text(speaker.name)
                    }
                }
            }
            .navigationTitle("Select Speaker")
        } detail: {
            if let selectedSpeaker {
                DetailsView(speaker: selectedSpeaker)
            } else {
                Text("Select a speaker from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
