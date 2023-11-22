import WatchKit
import Foundation
import AVFoundation
import Combine


class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    @Published var isRecording = false

    override init() {
        super.init()
        setupAudioRecorder()
    }

    private func setupAudioRecorder() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .long)
            let uniqueFilename = "recording_\(timestamp).m4a"
            let audioFilename = getDocumentsDirectory().appendingPathComponent(uniqueFilename)


            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
        } catch {
            print("Failed to set up audio recorder: \(error)")
        }
    }

    func startRecording() {
        setupAudioRecorder()
        audioRecorder?.record()
        isRecording = true
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
       if !flag {
           print("Recording finished unsuccessfully")
       } else {
           uploadAudioFile()
       }
   }


    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func uploadAudioFile() {
        guard let audioURL = audioRecorder?.url else { return }

        let url = URL(string: "http://localhost:3000/api")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        if let audioData = try? Data(contentsOf: audioURL) {
            data.append(audioData)
        }
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: data) { [weak self] data, response, error in
            if let error = error {
                print("Upload error: \(error)")
                return
            }
            guard let responseData = data else {
                print("No data received")
                return
            }
            self?.playAudio(data: responseData)
        }
        task.resume()
    }

    private func playAudio(data: Data) {
        DispatchQueue.main.async {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt)
                try AVAudioSession.sharedInstance().setActive(true)

                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.volume = 1.0
                self.audioPlayer?.play()
            } catch {
                print("Audio playback error: \(error)")
            }
        }
    }

}
