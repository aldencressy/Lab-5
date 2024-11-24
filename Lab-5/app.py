from flask import Flask, request, jsonify
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
import pandas as pd
import os
import pickle
import json

app = Flask(__name__)

# In-memory storage for feature data
feature_data = []

# Model storage
model_file = "pose_model.pkl"

# Path to the preprocessed JSON file
json_file_path = "training_dataset.json"


# Load landmarks from JSON file
def load_landmarks_from_json(json_path):
    global feature_data
    try:
        with open(json_path, 'r') as f:
            data = json.load(f)

        for entry in data:
            label = entry['label']
            landmarks = entry['landmarks']

            # Flatten the landmarks into a single feature vector
            features = {}
            for joint_name, values in landmarks.items():
                features[f"{joint_name}_x"] = values['x']
                features[f"{joint_name}_y"] = values['y']
                features[f"{joint_name}_confidence"] = values['confidence']

            features['label'] = label
            feature_data.append(features)
        print(f"Loaded {len(feature_data)} samples from JSON.")
    except Exception as e:
        print(f"Error loading JSON: {str(e)}")


# Load data when the server starts
load_landmarks_from_json(json_file_path)


# Endpoint to upload labeled feature data
@app.route('/upload', methods=['POST'])
def upload_features():
    try:
        data = request.get_json()
        label = data['label']
        features = data['features']

        # Add data to in-memory storage
        for feature in features:
            feature['label'] = label
            feature_data.append(feature)

        return jsonify({"message": "Features uploaded successfully", "count": len(features)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# Endpoint to train the model
@app.route('/train', methods=['POST'])
def train_model():
    try:
        if not feature_data:
            return jsonify({"error": "No feature data available for training"}), 400

        # Convert in-memory feature data to a Pandas DataFrame
        df = pd.DataFrame(feature_data)
        if 'label' not in df.columns:
            return jsonify({"error": "Missing labels in data"}), 400

        # Separate features and labels
        X = df.drop(columns=['label'])
        y = df['label']

        # Handle missing values with an imputer
        imputer = SimpleImputer(strategy='mean')
        model_pipeline = Pipeline(steps=[
            ('impute', imputer),
            ('classifier', RandomForestClassifier(random_state=42))
        ])

        # Train/test split
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        # Train the model
        model_pipeline.fit(X_train, y_train)

        # Save the model to disk
        with open(model_file, 'wb') as f:
            pickle.dump(model_pipeline, f)

        accuracy = model_pipeline.score(X_test, y_test)
        return jsonify({"message": "Model trained successfully", "accuracy": accuracy}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# Endpoint to make predictions
@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Log raw request data
        print("Headers:", request.headers)
        print("Data:", request.data.decode("utf-8"))

        # Parse the incoming JSON
        data = request.get_json()
        print("Parsed JSON:", data)

        features = data['features']

        # Preprocess the feature names to match the expected format
        processed_features = []
        for feature in features:
            processed_feature = {}
            for key, value in feature.items():
                # Remove the prefix and convert to the expected format
                clean_key = key.replace("VNRecognizedPointKey(_rawValue: ", "").replace(")", "")
                processed_feature[clean_key] = value
            processed_features.append(processed_feature)

        # Load the model
        with open(model_file, 'rb') as f:
            model = pickle.load(f)

        # Define the expected feature order (used during training)
        expected_features = [
            'right_shoulder_1_joint_x', 'right_shoulder_1_joint_y', 'right_shoulder_1_joint_confidence',
            'right_eye_joint_x', 'right_eye_joint_y', 'right_eye_joint_confidence',
            'left_upLeg_joint_x', 'left_upLeg_joint_y', 'left_upLeg_joint_confidence',
            'left_hand_joint_x', 'left_hand_joint_y', 'left_hand_joint_confidence',
            'root_x', 'root_y', 'root_confidence',
            'neck_1_joint_x', 'neck_1_joint_y', 'neck_1_joint_confidence',
            'head_joint_x', 'head_joint_y', 'head_joint_confidence',
            'left_shoulder_1_joint_x', 'left_shoulder_1_joint_y', 'left_shoulder_1_joint_confidence',
            'right_ear_joint_x', 'right_ear_joint_y', 'right_ear_joint_confidence',
            'left_leg_joint_x', 'left_leg_joint_y', 'left_leg_joint_confidence',
            'left_eye_joint_x', 'left_eye_joint_y', 'left_eye_joint_confidence',
            'left_foot_joint_x', 'left_foot_joint_y', 'left_foot_joint_confidence',
            'right_upLeg_joint_x', 'right_upLeg_joint_y', 'right_upLeg_joint_confidence',
            'right_leg_joint_x', 'right_leg_joint_y', 'right_leg_joint_confidence',
            'right_forearm_joint_x', 'right_forearm_joint_y', 'right_forearm_joint_confidence',
            'right_foot_joint_x', 'right_foot_joint_y', 'right_foot_joint_confidence',
            'right_hand_joint_x', 'right_hand_joint_y', 'right_hand_joint_confidence',
            'left_forearm_joint_x', 'left_forearm_joint_y', 'left_forearm_joint_confidence',
            'left_ear_joint_x', 'left_ear_joint_y', 'left_ear_joint_confidence'
        ]

        # Order the features to match the expected order
        ordered_features = []
        for feature in processed_features:
            ordered_feature = {key: feature.get(key, 0) for key in expected_features}  # Default missing keys to 0
            ordered_features.append(ordered_feature)

        # Predict the label
        df = pd.DataFrame(ordered_features)
        predictions = model.predict(df)

        response = {"predictions": predictions.tolist()}
        print("Response:", response)
        return jsonify(response), 200
    except Exception as e:
        error_message = {"error": str(e)}
        print("Error:", error_message)
        return jsonify(error_message), 400


@app.route('/inspect_model', methods=['GET'])
def inspect_model():
    try:
        with open(model_file, 'rb') as f:
            model = pickle.load(f)

        # Extract expected feature names from the model
        feature_names = model.named_steps['impute'].feature_names_in_

        return jsonify({"expected_features": list(feature_names)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)