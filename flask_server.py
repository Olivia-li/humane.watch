from flask import Flask, request
import os

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        app.logger.error('No file part in the request')
        return 'No file part', 400

    file = request.files['file']

    if file.filename == '':
        app.logger.error('No selected file')
        return 'No selected file', 400

    if file:
        # Save in the current directory
        file.save(os.path.join(os.getcwd(), file.filename))
        return 'File uploaded successfully', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)

