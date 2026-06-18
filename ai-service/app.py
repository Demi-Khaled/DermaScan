from flask import Flask, request, jsonify
import os
import tempfile
import uuid

# Load predictor.py
import predictor

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

# Map specific skin conditions to general risk levels for the Node.js backend
RISK_MAPPING = {
    'Melanoma': 'high',
    'BCC': 'high',
    'Actinic_Keratosis': 'medium',
    'Nevus': 'low',
    'Benign_Keratosis': 'low',
    'Dermatofibroma': 'low',
    'Vascular': 'low'
}

RECOMMENDATIONS = {
    'high': '⚠️ Seek immediate medical attention. This lesion requires professional examination.',
    'medium': 'Schedule a dermatologist appointment within the next 2–4 weeks.',
    'low': 'Continue regular self-monitoring every 3 months. Apply sunscreen.'
}

EXPLANATIONS = {
    'Melanoma': 'High risk of Melanoma detected. This is a serious type of skin cancer.',
    'BCC': 'High risk of Basal Cell Carcinoma (BCC) detected. It is a common and treatable skin cancer.',
    'Actinic_Keratosis': 'Medium risk. Actinic Keratosis is a precancerous skin growth.',
    'Nevus': 'Low risk. This appears to be a common mole (Nevus).',
    'Benign_Keratosis': 'Low risk. Benign Keratosis is a non-cancerous skin growth.',
    'Dermatofibroma': 'Low risk. Dermatofibroma is a harmless skin growth.',
    'Vascular': 'Low risk. This is a vascular lesion, typically benign.'
}

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400

    file = request.files['image']
    
    # Save image temporarily using a UUID to avoid race conditions
    # when multiple requests are handled concurrently by ECS
    ext = os.path.splitext(file.filename or 'image.jpg')[1] or '.jpg'
    temp_path = os.path.join(tempfile.gettempdir(), f"{uuid.uuid4().hex}{ext}")
    file.save(temp_path)

    try:
        # Run prediction
        pred_idx, conf = predictor.predict_image(temp_path)
        
        class_name = predictor.class_names[pred_idx]
        risk_level = RISK_MAPPING.get(class_name, 'medium')
        
        # Format response to match Node.js expected format
        response = {
            'risk_level': risk_level,
            'confidence': float(conf),
            'explanation': EXPLANATIONS.get(class_name, 'Analysis complete.'),
            'recommendation': RECOMMENDATIONS.get(risk_level, 'Monitor the lesion.'),
            'class_name': class_name
        }
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        # Clean up temporary file
        if os.path.exists(temp_path):
            os.remove(temp_path)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
