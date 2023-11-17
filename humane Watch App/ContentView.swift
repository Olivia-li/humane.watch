import SwiftUI

struct ContentView: View {
    @StateObject var recordingManager = AudioRecorder()

    var body: some View {
        VStack {
            if recordingManager.isRecording {
                Button("Stop Recording") {
                    recordingManager.stopRecording()
                }
            } else {
                Button("Start Recording") {
                    recordingManager.startRecording()
                }
            }
        }
    }
}
