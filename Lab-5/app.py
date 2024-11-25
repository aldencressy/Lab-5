from flask import Flask, request, jsonify
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline
import pandas as pd
import json

app = Flask(__name__)

# In-memory storage for feature data
feature_data = []

# Model storage
modelRF = None  # The trained model instance
modelKNN = None  # The trained model instance

# Define expected feature names (landmarks)
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

@app.route('/uploadRF', methods=['POST'])
def upload_featuresRF():
    global modelRF
    try:
        data = request.get_json()
        label = data['label']
        features = data['features']

        # Clean up feature keys to match expected features
        processed_features = {}
        for key, value in features.items():
            clean_key = key.replace("VNRecognizedPointKey(_rawValue: ", "").replace(")", "")
            processed_features[clean_key] = value

        # Add missing features with default 0.0
        complete_features = {key: processed_features.get(key, 0.0) for key in expected_features}
        complete_features['label'] = label

        # Add features to in-memory storage
        feature_data.append(complete_features)

        # Log the added features
        print(f"Uploaded features: {complete_features}")
        print(f"Total features in dataset: {len(feature_data)}")

        # Automatically train the model after every upload
        if len(feature_data) > 1:  # Ensure there's enough data to train
            print("Training model after upload...")
            # Train the model
            df = pd.DataFrame(feature_data)
            X = df.drop(columns=['label'])
            y = df['label']

            # Build and train the model
            imputer = SimpleImputer(strategy='mean')
            model_pipeline = Pipeline(steps=[
                ('impute', imputer),
                ('classifier', RandomForestClassifier(random_state=42))
            ])
            model_pipeline.fit(X, y)

            # Update the global model
            modelRF = model_pipeline
            print("Model trained successfully after upload.")

        return jsonify({"message": "Features uploaded and model trained successfully", "total_features": len(feature_data)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    
@app.route('/uploadKNN', methods=['POST'])
def upload_featuresKNN():
    global modelKNN
    try:
        data = request.get_json()
        label = data['label']
        features = data['features']

        # Clean up feature keys to match expected features
        processed_features = {}
        for key, value in features.items():
            clean_key = key.replace("VNRecognizedPointKey(_rawValue: ", "").replace(")", "")
            processed_features[clean_key] = value

        # Add missing features with default 0.0
        complete_features = {key: processed_features.get(key, 0.0) for key in expected_features}
        complete_features['label'] = label

        # Add features to in-memory storage
        feature_data.append(complete_features)

        # Log the added features
        print(f"Uploaded features: {complete_features}")
        print(f"Total features in dataset: {len(feature_data)}")

        # Automatically train the model after every upload
        if len(feature_data) > 1:  # Ensure there's enough data to train
            print("Training model after upload...")
            # Train the model
            df = pd.DataFrame(feature_data)
            X = df.drop(columns=['label'])
            y = df['label']

            # Build and train the model
            imputer = SimpleImputer(strategy='mean')
            model_pipeline = Pipeline(steps=[
                ('impute', imputer),
                ('classifier', KNeighborsClassifier(n_neighbors=5))
            ])
            model_pipeline.fit(X, y)

            # Update the global model
            modelKNN = model_pipeline
            print("Model trained successfully after upload.")

        return jsonify({"message": "Features uploaded and model trained successfully", "total_features": len(feature_data)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/predictRF', methods=['POST'])
def predictRF():
    try:
        global modelRF

        # Ensure the model exists
        if modelRF is None:
            print("Error: Model is not trained or loaded.")
            return jsonify({"error": "Model is not trained. Train the model first using the /train endpoint."}), 500

        # Parse the incoming data
        data = request.get_json()

        # Ensure 'features' key exists
        if 'features' not in data:
            return jsonify({"error": "'features' key is missing from request"}), 400

        raw_features = data['features']
        print("Raw Features Received:", json.dumps(raw_features, indent=2))

        # Clean and process features
        processed_features = {}
        for key, value in raw_features.items():
            clean_key = key.replace("VNRecognizedPointKey(_rawValue: ", "").replace(")", "")
            processed_features[clean_key] = value

        # Fill missing features with default values (0.0)
        complete_features = {key: processed_features.get(key, 0.0) for key in expected_features}
        print("Processed Features:", json.dumps(complete_features, indent=2))

        # Create a DataFrame for prediction
        df = pd.DataFrame([complete_features])
        print("DataFrame for Prediction:\n", df)

        # Predict using the trained model
        predictions = modelRF.predict(df)
        print("Prediction Result:", predictions)

        return jsonify({"predictions": predictions.tolist()}), 200
    except Exception as e:
        print("Error during prediction:", str(e))
        return jsonify({"error": str(e)}), 500
    
@app.route('/predictKNN', methods=['POST'])
def predictKNN():
    try:
        global modelKNN

        # Ensure the model exists
        if modelKNN is None:
            print("Error: Model is not trained or loaded.")
            return jsonify({"error": "Model is not trained. Train the model first using the /train endpoint."}), 500

        # Parse the incoming data
        data = request.get_json()

        # Ensure 'features' key exists
        if 'features' not in data:
            return jsonify({"error": "'features' key is missing from request"}), 400

        raw_features = data['features']
        print("Raw Features Received:", json.dumps(raw_features, indent=2))

        # Clean and process features
        processed_features = {}
        for key, value in raw_features.items():
            clean_key = key.replace("VNRecognizedPointKey(_rawValue: ", "").replace(")", "")
            processed_features[clean_key] = value

        # Fill missing features with default values (0.0)
        complete_features = {key: processed_features.get(key, 0.0) for key in expected_features}
        print("Processed Features:", json.dumps(complete_features, indent=2))

        # Create a DataFrame for prediction
        df = pd.DataFrame([complete_features])
        print("DataFrame for Prediction:\n", df)

        # Predict using the trained model
        predictions = modelKNN.predict(df)
        print("Prediction Result:", predictions)

        return jsonify({"predictions": predictions.tolist()}), 200
    except Exception as e:
        print("Error during prediction:", str(e))
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)