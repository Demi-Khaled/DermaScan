import torch
import torch.nn as nn
from torchvision import models
import numpy as np
from PIL import Image
import albumentations as A
from albumentations.pytorch import ToTensorV2

# =========================
# CLASS NAMES
# =========================
class_names = {
    0: 'Melanoma',
    1: 'Nevus',
    2: 'BCC',
    3: 'Actinic_Keratosis',
    4: 'Benign_Keratosis',
    5: 'Dermatofibroma',
    6: 'Vascular'
}

# =========================
# DEVICE
# =========================
DEVICE = torch.device("cpu")

# =========================
# TRANSFORMS
# =========================
val_test_transforms = A.Compose([
    A.Resize(224, 224),
    A.Normalize(mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]),
    ToTensorV2(),
])

# =========================
# LOAD MODEL
# =========================
NUM_CLASSES = len(class_names)

model = models.resnet101(weights=None)
num_ftrs = model.fc.in_features

model.fc = nn.Sequential(
    nn.Linear(num_ftrs, 512),
    nn.BatchNorm1d(512),
    nn.ReLU(),
    nn.Dropout(0.4),
    nn.Linear(512, 256),
    nn.BatchNorm1d(256),
    nn.ReLU(),
    nn.Dropout(0.3),
    nn.Linear(256, NUM_CLASSES)
)

model.load_state_dict(
    torch.load("best_resnet101_model.pth", map_location=DEVICE)
)

model = model.to(DEVICE)
model.eval()

print("Model loaded")

# =========================
# PREDICTION FUNCTION
# =========================
def predict_image(image_path):
    image = np.array(Image.open(image_path).convert("RGB"))

    transformed = val_test_transforms(image=image)
    image_tensor = transformed["image"].unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        output = model(image_tensor)
        probs = torch.softmax(output, dim=1)

    probs = probs.cpu().numpy()[0]
    pred = np.argmax(probs)

    return pred, probs[pred]
