import torch
from PIL import Image
import numpy as np
import cv2

# Load the TorchScript model
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = torch.jit.load('best.torchscript').to(device)
model.eval()

# Function to preprocess the image
def preprocess_image(image_path, input_size=640):
    image = Image.open(image_path).convert('RGB')
    original_image = np.array(image)
    img = cv2.resize(original_image, (input_size, input_size))  # Resize to model's input size
    img = img.transpose((2, 0, 1))  # Change from HWC to CHW format
    img = np.expand_dims(img, axis=0)  # Add batch dimension
    img = img / 255.0  # Normalize to [0, 1]
    img = torch.from_numpy(img).float().to(device)
    return img, original_image

# Perform inference and post-process
def detect_objects(model, img, original_image, conf_threshold=0.25, input_size=640):
    with torch.no_grad():
        predictions = model(img)[0]  # Model output shape: [1, num_boxes, num_features]

    predictions = predictions.squeeze(0)  # Remove batch dimension

    # Filter detections by confidence
    detections = predictions[predictions[:, 4] > conf_threshold]  # Filter confidence

    results = []
    for det in detections:
        values = det.cpu().numpy()
        print(f"Detection values: {values}")  # Debugging output
        x1, y1, x2, y2, confidence, class_id = values[:6]  

        orig_h, orig_w = original_image.shape[:2]
        scale_x = orig_w / input_size
        scale_y = orig_h / input_size

        x1, x2 = x1 * scale_x, x2 * scale_x
        y1, y2 = y1 * scale_y, y2 * scale_y

        results.append({
            "box": [int(x1), int(y1), int(x2), int(y2)],
            "confidence": float(confidence),
            "class_id": int(class_id)
        })

    return results


def draw_boxes(image, detections, class_names):
    for det in detections:
        x1, y1, x2, y2 = det["box"]
        confidence = det["confidence"]
        class_id = det["class_id"]

        color = (0, 255, 0)  
        cv2.rectangle(image, (x1, y1), (x2, y2), color, 2)

      
        label = f"{class_names[class_id]}: {confidence:.2f}"
        cv2.putText(image, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)
    return image

def main():
    
    image_path = '2.jpg'
    class_names = ['Electric Pole', 'Electric Wire', 'Tree']  

    img, original_image = preprocess_image(image_path)

    # Perform object detection
    detections = detect_objects(model, img, original_image)

    # Draw and save the result image
    output_image = draw_boxes(original_image, detections, class_names)
    output_path = 'output.jpg'
    cv2.imwrite(output_path, cv2.cvtColor(output_image, cv2.COLOR_RGB2BGR))

    # Print detections
    print(f"Detections saved to {output_path}")
    for det in detections:
        print(f"Box: {det['box']}, Confidence: {det['confidence']:.2f}, Class ID: {det['class_id']}")

if __name__ == "__main__":
    main()
