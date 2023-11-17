from flask import Flask, request, send_file
from dotenv import load_dotenv
from openai import OpenAI
import whisper
import os

app = Flask(__name__)

@app.route('/api', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        app.logger.error('No file part in the request')
        return 'No file part', 400

    file = request.files['file']

    if file.filename == '':
        app.logger.error('No selected file')
        return 'No selected file', 400

    path = os.path.join(os.getcwd(), "recording.m4a")
    file.save(path)

    result = model.transcribe(path)
    
    prompt = result["text"]
    
    completion = client.chat.completions.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": "You are a helpful assistant. Give short and concise answers. If you hear a language that's not in English. Translate it to English."},
            {"role": "user", "content": prompt}
        ]
    )

    print(completion.choices[0].message.content)

    response = client.audio.speech.create(
        model="tts-1",
        voice="alloy",
        response_format="aac",
        input=completion.choices[0].message.content
    )

    response.stream_to_file("output.m4a")
    
    return send_file("output.m4a", mimetype="audio/m4a")

if __name__ == '__main__':
    load_dotenv() 
    client = OpenAI()
    model = whisper.load_model("tiny")
    app.run(host='0.0.0.0', port=3000, debug=True)

