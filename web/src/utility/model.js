import { useEffect, useState } from 'react';
import * as tf from '@tensorflow/tfjs';

const ModelComponent = () => {
  const [model, setModel] = useState(null);
  const [prediction, setPrediction] = useState(null);

  useEffect(() => {
    const loadModel = async () => {
      const loadedModel = await tf.loadLayersModel('best.torchscript');
      setModel(loadedModel);
    };
    loadModel();
  }, []);

  const predict = async (input) => {
    if (model) {
      const inputTensor = tf.tensor(input);
      const output = model.predict(inputTensor);
      setPrediction(output.dataSync());
    }
  };

  return (
    <div>
      <button onClick={() => predict([1, 2, 3])}>Predict</button>
      {prediction && <p>Prediction: {prediction}</p>}
    </div>
  );
};

export default ModelComponent;