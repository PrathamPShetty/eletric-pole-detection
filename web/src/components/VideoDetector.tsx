import { useEffect, useRef, useState } from 'react';
import * as tf from '@tensorflow/tfjs';
import * as cocoSsd from '@tensorflow-models/coco-ssd';

const VideoDetector = () => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [model, setModel] = useState<cocoSsd.ObjectDetection | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Load the COCO-SSD model
  useEffect(() => {
    const loadModel = async () => {
      try {
        const loadedModel = await cocoSsd.load();
        setModel(loadedModel);
        setIsLoading(false);
      } catch (error) {
        console.error('Error loading model:', error);
      }
    };

    loadModel();
  }, []);

  // Start video stream and perform object detection
  useEffect(() => {
    if (!model || !videoRef.current || !canvasRef.current) return;

    const startVideo = async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ video: true });
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          videoRef.current.play();
        }
      } catch (error) {
        console.error('Error accessing camera:', error);
      }
    };

    startVideo();

    const detectFrame = async () => {
      if (videoRef.current && canvasRef.current && model) {
        const predictions = await model.detect(videoRef.current);

        // Draw bounding boxes and labels on the canvas
        const ctx = canvasRef.current.getContext('2d');
        if (ctx) {
          ctx.clearRect(0, 0, canvasRef.current.width, canvasRef.current.height);
          predictions.forEach((prediction) => {
            const [x, y, width, height] = prediction.bbox;
            ctx.strokeStyle = '#00FF00';
            ctx.lineWidth = 2;
            ctx.strokeRect(x, y, width, height);

            ctx.fillStyle = '#00FF00';
            ctx.font = '16px Arial';
            ctx.fillText(
              `${prediction.class} (${Math.round(prediction.score * 100)}%)`,
              x,
              y > 10 ? y - 5 : 10
            );
          });
        }
      }

      requestAnimationFrame(detectFrame);
    };

    detectFrame();
  }, [model]);

  return (
    <div style={{ textAlign: 'center', marginTop: '20px' }}>
      <h1>Real-Time Video Object Detection</h1>
      {isLoading ? (
        <p>Loading model...</p>
      ) : (
        <div style={{ position: 'relative' }}>
          <video
            ref={videoRef}
            width="640"
            height="480"
            style={{ display: 'none' }}
          />
          <canvas
            ref={canvasRef}
            width="640"
            height="480"
            style={{ border: '1px solid black' }}
          />
        </div>
      )}
    </div>
  );
};

export default VideoDetector;