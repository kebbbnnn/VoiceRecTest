//
//  AudioPlayer.swift
//  VoiceRecTest
//
//  Created by Umayanga Alahakoon on 2022-07-21.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

public final class _Recording {
    public var createdAt: Date?
    public var id: UUID?
    public var name: String?
    public var recordingData: Data?
    
    public init(recording: Recording) {
        self.createdAt = recording.createdAt
        self.id = recording.id
        self.name = recording.name
        self.recordingData = recording.recordingData
    }
    
    public init(id: UUID?, name: String?, createdAt: Date?, recordingData: Data?) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.recordingData = recordingData
    }
}

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {

    @Published var currentlyPlaying: _Recording?
    @Published var isPlaying = false
    
    var audioPlayer: AVAudioPlayer?
    let animated: Bool
    
    init(animated: Bool = true) {
        self.animated = animated
    }
    
    func startPlayback(recording: _Recording) {
        if let recordingData = recording.recordingData {
            let playbackSession = AVAudioSession.sharedInstance()
            
            do {
                try playbackSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.spokenAudio)
                try playbackSession.setActive(true)
                print("Start Recording - Playback session setted")
            } catch {
                print("Play Recording - Failed to set up playback session")
            }
            
            do {
                audioPlayer = try AVAudioPlayer(data: recordingData)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                isPlaying = true
                print("Play Recording - Playing")
                withAnimation(animated ? .spring() : nil) {
                    currentlyPlaying = recording
                }
            } catch {
                print("Play Recording - Playback failed: - \(error)")
                withAnimation(animated ? .default : nil) {
                    currentlyPlaying = nil
                }
            }
        } else {
            print("Play Recording - Could not get the recording data")
            withAnimation(animated ? .default : nil) {
                currentlyPlaying = nil
            }
        }
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        print("Play Recording - Paused")
    }
    
    func resumePlayback() {
        audioPlayer?.play()
        isPlaying = true
        print("Play Recording - Resumed")
    }
    
    func stopPlayback() {
        if audioPlayer != nil {
            audioPlayer?.stop()
            isPlaying = false
            print("Play Recording - Stopped")
            withAnimation(animated ? .spring() : nil) {
                self.currentlyPlaying = nil
            }
        } else {
            print("Play Recording - Failed to Stop playing - Coz the recording is not playing")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            isPlaying = false
            print("Play Recording - Recoring finished playing")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(self.animated ? .spring() : nil) {
                    self.currentlyPlaying = nil
                }
            }
        }
    }
    
}
