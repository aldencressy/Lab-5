from flask import Flask, request, jsonify, send_file
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.impute import SimpleImputer
from sklearn.metrics import accuracy_score
from sklearn.pipeline import Pipeline
import pandas as pd
import json
import pandas as pd
import kagglehub
import os
import shutil

app = Flask(__name__)

# In-memory storage for feature data
feature_data = []

# Model storage
modelRF = None  # The trained model instance
modelKNN = None  # The trained model instance

total_feedback_rf = 0
correct_feedback_rf = 0

total_feedback_knn = 0
correct_feedback_knn = 0

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
    
@app.route('/validate_rf', methods=['POST'])
def validate_prediction_rf():
    global total_feedback_rf, correct_feedback_rf

    try:
        data = request.get_json()

        if 'correct' not in data:
            return jsonify({"error": "'correct' key is missing from the request"}), 400

        total_feedback_rf += 1
        if data['correct']:
            correct_feedback_rf += 1

        #calculate accuracy
        accuracy = (correct_feedback_rf / total_feedback_rf) * 100

        #return the accuracy
        return jsonify({
            "message": "Feedback received successfully",
            "total_feedback": total_feedback_rf,
            "correct_feedback": correct_feedback_rf,
            "accuracy": accuracy
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route('/validate_knn', methods=['POST'])
def validate_prediction_knn():
    global total_feedback_knn, correct_feedback_knn

    try:
        data = request.get_json()

        if 'correct' not in data:
            return jsonify({"error": "'correct' key is missing from the request"}), 400
        
        total_feedback_knn += 1
        if data['correct']:
            correct_feedback_knn += 1

        #calculate accuracy
        accuracy = (correct_feedback_knn / total_feedback_knn) * 100

        #return the accuracy
        return jsonify({
            "message": "Feedback received successfully",
            "total_feedback": total_feedback_knn,
            "correct_feedback": correct_feedback_knn,
            "accuracy": accuracy
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
"""THIS IS FOR LOCAL PREPROCESSING"""

@app.route('/process_kaggle_dataset', methods=['GET'])
def process_kaggle_dataset():
    try:
        # Download the dataset through Kagglehub
        dataset_path = kagglehub.dataset_download("niharika41298/yoga-poses-dataset")
        print(f"Dataset downloaded to: {dataset_path}")

        # Define the path
        CREATE_ML_FOLDER = './datasets/createml_ready'
        os.makedirs(CREATE_ML_FOLDER, exist_ok=True)

        # Find and assign the train and test datasets
        train_source = os.path.join(dataset_path, 'DATASET', 'Train')
        test_source = os.path.join(dataset_path, 'DATASET', 'Test')

        if not os.path.exists(train_source) or not os.path.exists(test_source):
            return jsonify({"error": "Train or Test folder not found in the dataset."}), 404

        # Prepare train and test data
        train_dest = os.path.join(CREATE_ML_FOLDER, 'Train')
        test_dest = os.path.join(CREATE_ML_FOLDER, 'Test')

        # Copy train and test folders
        shutil.copytree(train_source, train_dest, dirs_exist_ok=True)
        shutil.copytree(test_source, test_dest, dirs_exist_ok=True)

        return jsonify({
            "message": "Dataset downloaded and processed.",
            "processed_folder": CREATE_ML_FOLDER
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/export_createml_dataset', methods=['GET'])
def export_createml_dataset():
    try:
        CREATE_ML_FOLDER = './datasets/createml_ready'

        # Compress the CreateML dataset
        zip_path = './datasets/createml_ready.zip'

        # Remove old file if it exists
        if os.path.exists(zip_path):
            os.remove(zip_path)

        # Zip the CreateML dataset
        shutil.make_archive(CREATE_ML_FOLDER, 'zip', CREATE_ML_FOLDER)

        # Check if the zip file was created
        if not os.path.exists(zip_path):
            return jsonify({"error": "Failed to create dataset zip file."}), 500

        # Send the zip file
        return send_file(zip_path, as_attachment=True)
    except Exception as e:
        return jsonify({"error": str(e)}), 500




if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)