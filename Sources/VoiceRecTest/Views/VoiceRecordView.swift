//
//  ContentView.swift
//  VoiceRecTest
//
//  Created by Umayanga Alahakoon on 2022-07-21.
//

import SwiftUI
import CoreData

public struct VoiceRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject var audioPlayer = AudioPlayer()
    
    @ObservedObject var audioRecorder = AudioRecorder()
    
    @State private var isSelecting = false
    @State private var selectedItem: Recording? = nil
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    let selection: (Recording) -> Void
    
    public init(selection: @escaping (Recording) -> Void) {
        self.selection = selection
    }
    
    public var body: some View {
        NavigationView {
            RecordingsList(audioPlayer: audioPlayer, isSelecting: self.$isSelecting, selectedItem: self.$selectedItem)
                .safeAreaInset(edge: .bottom) {
                    bottomBar
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Voice Records")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            self.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isSelecting ? "Done" : "Select") {
                            withAnimation(.spring()) {
                                isSelecting.toggle()
                                if !isSelecting, let selectedItem {
                                    self.selection(selectedItem)
                                    //selectedItem = nil
                                    self.dismiss()
                                }
                            }
                        }
                    }
                }
        }
    }
    
    var bottomBar: some View {
        VStack {
            PlayerBar(audioPlayer: audioPlayer)
            RecorderBar(audioPlayer: audioPlayer)
        }
        .background(.thinMaterial)
    }
    
}

struct VoiceRecordView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceRecordView { _ in
            
        }.environment(\.managedObjectContext, VoiceRecordPersistenceController.preview.container.viewContext)
    }
}

public struct PlayerBarView: View {
    @StateObject var audioPlayer = AudioPlayer(animated: false)
    
    let recording: _Recording
    
    @State private var isPresentingPlayerBar: Bool = false
    @State private var viewSize: CGSize = .zero
    
    public init(recording: _Recording) {
        self.recording = recording
    }
    
    public var body: some View {
        Rectangle()
            .fill(Color.gray)
            //.frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .center) {
                Image(systemName: "waveform")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .tint(.gray.opacity(0.8))
                    .frame(width: 32, height: 32)
            }
            .onTapGesture {
                //audioPlayer.startPlayback(recording: recording)
                self.isPresentingPlayerBar = true
            }
            .sheet(isPresented: self.$isPresentingPlayerBar) {
                /*if !audioPlayer.isPlaying && audioPlayer.currentlyPlaying == nil && self.isPresentngPlayerBar {
                    DispatchQueue.main.async {
                        self.isPresentngPlayerBar = false
                    }
                }*/
                VStack {
                    PlayerBar(audioPlayer: audioPlayer)
                    
                    Spacer()
                }
                .background(GeometryReader { geometry in
                    if !self.viewSize.equalTo(geometry.size) {
                        self.viewSize = geometry.size
                    }
                    return Color.clear
                })
                .onChange(of: audioPlayer.isPlaying) { isPlaying in
                    guard !isPlaying else { return }
                    self.isPresentingPlayerBar = false
                }
                .background(.thinMaterial)
                .onAppear {
                    audioPlayer.startPlayback(recording: recording)
                }
                .presentationDragIndicator(.hidden)
                .presentationDetents([.fraction(0.35)])
                //.presentationDetents([.height(self.viewSize.height)])
            }
    }
}
