import urllib.request
import os
import predictor

RISK_MAPPING = {
    'Melanoma': 'High Risk',
    'BCC': 'High Risk',
    'Actinic_Keratosis': 'Medium Risk',
    'Nevus': 'Low Risk',
    'Benign_Keratosis': 'Low Risk',
    'Dermatofibroma': 'Low Risk',
    'Vascular': 'Low Risk'
}

IMAGES = {
    "Melanoma Image": "https://upload.wikimedia.org/wikipedia/commons/6/6c/Melanoma.jpg",
    "BCC Image": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Basal_cell_carcinoma.jpg/640px-Basal_cell_carcinoma.jpg"
}

def test_model():
    print("=== DermaScan AI Model Diagnostic Test ===")
    
    for name, url in IMAGES.items():
        try:
            filename = f"temp_{name.replace(' ', '_')}.jpg"
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response, open(filename, 'wb') as out_file:
                out_file.write(response.read())
            
            print(f"Testing: {name}")
            pred_idx, conf = predictor.predict_image(filename)
            class_name = predictor.class_names[pred_idx]
            risk_level = RISK_MAPPING.get(class_name, 'Unknown')
            
            print(f"Prediction (Raw): {class_name}")
            print(f"Confidence: {conf * 100:.2f}%")
            print(f"==> Final Risk Level: {risk_level.upper()} <==\n")
            
            os.remove(filename)
        except Exception as e:
            print(f"Error testing {name}: {e}\n")

if __name__ == "__main__":
    test_model()
