//
//  RecordingsList.swift
//  VoiceRecTest
//
//  Created by Umayanga Alahakoon on 2022-07-21.
//

import SwiftUI
import CoreData
import AVFoundation

struct RecordingsList: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject var audioPlayer: AudioPlayer
    
    @Binding var isSelecting: Bool
    @Binding var selectedItem: Recording?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recording.createdAt, ascending: false)],
        animation: .default)
    private var recordings: FetchedResults<Recording>
    
    var body: some View {
        List {
            ForEach(recordings, id: \.id) { recording in
                RecordingRow(audioPlayer: audioPlayer, recording: recording, isSelecting: self.$isSelecting, selectedItem: self.$selectedItem)
            }
            .onDelete(perform: delete)
        }
    }
    
    func delete(at offsets: IndexSet) {
        withAnimation {
            offsets.map { recordings[$0] }.forEach(managedObjectContext.delete)

            do {
                try managedObjectContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct RecordingRow: View {
    @ObservedObject var audioPlayer: AudioPlayer
    var recording: Recording
    @Binding var isSelecting: Bool
    @Binding var selectedItem: Recording?
    
    var isPlayingThisRecording: Bool {
        audioPlayer.currentlyPlaying?.id == recording.id
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(recording.name ?? "Recording")
                        .fontWeight(isPlayingThisRecording ? .bold : .regular)
                    Group {
                        if let recordingData = recording.recordingData, let duration = getDuration(of: recordingData) {
                            Text(DateComponentsFormatter.positional.string(from: duration) ?? "0:00")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                Button {
                    audioPlayer.startPlayback(recording: _Recording(recording: recording))
                } label: {
                    Image(systemName: "play.circle.fill")
                        .imageScale(.large)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.primary, .tertiary)
                }
                .contentShape(Rectangle())
                //.buttonStyle(PlainButtonStyle())
                .buttonStyle(.automatic)
                .tint(isPlayingThisRecording ? .green : .blue)
            }
            .padding(.leading, isSelecting ? 38 : 0)
            
            RadioButton(isSelected: selectedItem == recording, isSelecting: self.$isSelecting)
                .padding(.trailing)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        selectedItem = selectedItem == recording ? nil : recording
                    }
                }
                .zIndex(isSelecting ? 1000 : -1)
        }
    }
    
    func getDuration(of recordingData: Data) -> TimeInterval? {
        do {
            return try AVAudioPlayer(data: recordingData).duration
        } catch {
            print("Failed to get the duration for recording on the list: Recording Name - \(recording.name ?? "")")
            return nil
        }
    }
}

struct RadioButton: View {
    var isSelected: Bool
    @Binding var isSelecting: Bool
    
    var body: some View {
        Circle()
            .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
            .frame(width: 22, height: 22)
            .background(
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 14, height: 14)
            )
            .scaleEffect(isSelecting ? 1 : 0) // Scale animation
            .animation(.spring(), value: isSelecting) // Smooth animation
            //.animation(.easeInOut, value: isSelected)
    }
}
