//
//  InterfaceController.swift
//  humane Watch App
//
//  Created by Olivia Li on 11/15/23.
//

import WatchKit
import Foundation
import AVFoundation

class InterfaceController: WKInterfaceController, AVAudioRecorderDelegate {

    var audioRecorder: AVAudioRecorder!
    let audioEngine = AVAudioEngine()

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure and prepare the audio recorder
        setupAudioRecorder()
    }

    func setupAudioRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default)
        try? audioSession.setActive(true)

        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
        } catch {
            // Handle error
        }
    }
    
    func uploadAudioFile() {
        let audioURL = audioRecorder.url

        let url = URL(string: "http://192.168.86.82:3000/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()

        // Append audio data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        if let audioData = try? Data(contentsOf: audioURL) {
            data.append(audioData)
        }
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        // URLSession upload task
        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                print(error)
                return
            }
            // Handle response here
        }
        task.resume()
    }

    @IBAction func startRecording() {
        if !audioRecorder.isRecording {
            audioRecorder.record()
            // Update UI to reflect recording state
        }
    }

    @IBAction func stopRecording() {
        if audioRecorder.isRecording {
            audioRecorder.stop()
            // Update UI and handle the recorded audio file
        }
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    // Implement AVAudioRecorderDelegate methods if needed
}
