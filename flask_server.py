from flask import Flask, request, send_file
from dotenv import load_dotenv
from openai import OpenAI
import whisper
import os
import time

app = Flask(__name__)

@app.route('/api', methods=['POST'])
def upload_file():
    start_time = time.time()

    if 'file' not in request.files:
        app.logger.error('No file part in the request')
        return 'No file part', 400

    file = request.files['file']

    if file.filename == '':
        app.logger.error('No selected file')
        return 'No selected file', 400

    download_start = time.time()
    path = os.path.join(os.getcwd(), "recording.m4a")
    file.save(path)
    download_end = time.time()

    transcribe_start = time.time()
    result = model.transcribe(path)
    transcribe_end = time.time()

    prompt = result["text"]

    gpt4_start = time.time()
    completion = client.chat.completions.create(
        model="gpt-4-1106-preview",
        max_tokens=80,
        messages=[
            {"role": "system", "content": "You are a helpful assistant. Give only short answers. Be extremely concise. If you hear a language that's not in English. Translate it to English."},
            {"role": "user", "content": prompt}
        ]
    )
    gpt4_end = time.time()

    print(completion.choices[0].message.content)

    upload_start = time.time()
    response = client.audio.speech.create(
        model="tts-1",
        voice="alloy",
        response_format="aac",
        input=completion.choices[0].message.content
    )

    response.stream_to_file("output.m4a")
    upload_end = time.time()

    total_time = time.time() - start_time

    print(f"Download Time: {download_end - download_start:.2f} seconds")
    print(f"Transcribe Time: {transcribe_end - transcribe_start:.2f} seconds")
    print(f"GPT-4 Response Time: {gpt4_end - gpt4_start:.2f} seconds")
    print(f"Upload Time: {upload_end - upload_start:.2f} seconds")
    print(f"Total Time: {total_time:.2f} seconds")

    return send_file("output.m4a", mimetype="audio/m4a")

if __name__ == '__main__':
    load_dotenv() 
    client = OpenAI()
    model = whisper.load_model("tiny")
    app.run(host='0.0.0.0', port=3000, debug=True)
