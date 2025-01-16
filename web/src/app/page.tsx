"use client"
import type { NextPage } from 'next';
import { useEffect, useRef, useState } from 'react';

const Home: NextPage = () => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Start the camera
  const startCamera = async () => {
    if (typeof window === 'undefined' || !navigator.mediaDevices) {
      setError('Camera access is not supported in this environment.');
      return;
    }
  
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({ video: true });
      setStream(mediaStream);
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
      }
    } catch (err) {
      setError('Unable to access the camera. Please ensure you have granted permission.');
      console.error(err);
    }
  };
  // Stop the camera
  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
      setStream(null);
    }
  };

  // Clean up the stream when the component unmounts
  useEffect(() => {
    return () => {
      if (stream) {
        stream.getTracks().forEach((track) => track.stop());
      }
    };
  }, [stream]);

  return (
    <div style={styles.container}>
      <h1 style={styles.title}>Camera Interface</h1>
      {error && <p style={styles.error}>{error}</p>}
      <div style={styles.videoContainer}>
        <video
          ref={videoRef}
          autoPlay
          playsInline
          muted
          style={styles.video}
        />
      </div>
      <div style={styles.buttonContainer}>
        {!stream ? (
          <button onClick={startCamera} style={styles.button}>
            Start Camera
          </button>
        ) : (
          <button onClick={stopCamera} style={styles.button}>
            Stop Camera
          </button>
        )}
      </div>
    </div>
  );
};

export default Home;

// CSS Styles
const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: '100vh',
    backgroundColor: '#f5f5f5',
    padding: '20px',
    fontFamily: 'Arial, sans-serif',
  },
  title: {
    fontSize: '2rem',
    marginBottom: '20px',
    color: '#333',
  },
  error: {
    color: 'red',
    marginBottom: '20px',
  },
  videoContainer: {
    width: '100%',
    maxWidth: '500px',
    borderRadius: '10px',
    overflow: 'hidden',
    boxShadow: '0 4px 8px rgba(0, 0, 0, 0.2)',
  },
  video: {
    width: '100%',
    height: 'auto',
    display: 'block',
  },
  buttonContainer: {
    marginTop: '20px',
  },
  button: {
    padding: '10px 20px',
    fontSize: '1rem',
    color: '#fff',
    backgroundColor: '#0070f3',
    border: 'none',
    borderRadius: '5px',
    cursor: 'pointer',
    transition: 'background-color 0.3s ease',
  },
};