# # pylint: disable=unresolved-import
# # pyright: reportMissingImports=false

# import flask
# from flask import Flask, jsonify, request
# import urllib.request
# from keras import models
# #from tensorflow.keras.models import load_model
# from keras.models import load_model
# import numpy as np
# import base64
# import io
# from PIL import Image

# model = load_model('best_weights.hdf5')

# app = Flask(__name__)


# @app.route('/recommend-outfit', methods={"POST"})
# def recommend_outfit():
#     try:
#         image_url = request.form['image_url']
#     except KeyError:
#         return jsonify({'error': 'image_url field is missing'}), 400
#     # image_url = request.form['image_url']
#     # Download the image from the URL
#     with urllib.request.urlopen(image_url) as response:
#         image_data = response.read()

#     # Preprocess the image for the Fashion MNIST model
#     image_array = np.frombuffer(image_data, np.uint8)
#     image_array = np.reshape(image_array, (28, 28, 1))
#     image_array = image_array / 255.0
#     image_array = np.expand_dims(image_array, axis=0)
#     prediction = model.predict(image_array)
#     outfit = get_outfit(prediction)
#     # Return the list of recommended outfits as a JSON response
#     response = {'outfit': outfit}
#     return jsonify(response)


# def get_outfit(prediction):
#     class_index = np.argmax(prediction)
#     # Define a dictionary of outfits for each class
#     outfits = {
#         0: 'T-shirt and jeans',
#         1: 'Blouse and skirt',
#         2: 'Sweatshirt and sweatpants',
#         3: 'Dress',
#         4: 'Coat and pants',
#         5: 'Sandal and shorts',
#         6: 'Shirt and trousers',
#         7: 'Sneakers and leggings',
#         8: 'Bag and accessories',
#         9: 'Ankle boots and pants'
#     }
#     # Get the recommended outfit for the predicted class
#     outfit = outfits.get(class_index, 'Unknown')

#     return outfit


# if __name__ == "__main__":
#     app.run(debug=True)


import base64
import io

from PIL import Image
from flask import Flask, jsonify, request
import numpy as np
import tensorflow as tf

app = Flask(__name__)

# Load the saved model
model = tf.keras.models.load_model('best_weights.hdf5')


# @app.route('/recommend-outfit', methods=['POST'])
# def recommend_outfit():
#     # Decode the base64-encoded image bytes from the request body
#     image_bytes = base64.b64decode(request.form['image_bytes'])

#     # Load the image bytes into a PIL image object
#     image = Image.open(io.BytesIO(image_bytes)).convert('L')

#     # Resize the image to 28x28 pixels to match the Fashion-MNIST dataset
#     image = image.resize((28, 28))

#     # Convert the image to a 1D NumPy array
#     image_array = np.array(image).reshape(1, 28, 28, 1) / 255.0

#     # Use the model to generate a prediction for the input image
#     prediction = model.predict(image_array)

#     # Map the predicted fashion item class indexto the corresponding item name
#     class_names = ['T-shirt/top', 'Trouser', 'Pullover', 'Dress',
#                    'Coat', 'Sandal', 'Shirt', 'Sneaker', 'Bag', 'Ankle boot']
#     outfit = class_names[np.argmax(prediction)]

#     # Encode the resulting image as base64
#     buffered = io.BytesIO()
#     image.save(buffered, format="PNG")
#     encoded_image = base64.b64encode(buffered.getvalue()).decode('utf-8')

#     # Return the recommended outfit and the encoded image as a JSON response
#     response = {'outfit': outfit, 'image_bytes': encoded_image}
#     return jsonify(response)


# @app.route('/recommend-outfit', methods=['POST'])
# def recommend_outfit():
#     # Decode the base64-encoded image bytes from the request body
#     image_bytes = base64.b64decode(request.form['image_bytes'])

#     # Load the image bytes into a PIL image object
#     image = Image.open(io.BytesIO(image_bytes))

#     # Resize the image to a fixed size of 224x224 pixels
#     image = image.resize((32, 32))

#     # Convert the image to a 3D NumPy array and normalize its values
#     image_array = np.array(image).astype(np.float32) / 255.0
#     image_array = np.expand_dims(image_array, axis=0)

#     # Use the model to generate a prediction for the input image
#     prediction = model.predict(image_array)

#     # Map the predicted fashion item class index to the corresponding item name
#     class_names = ['T-shirt/top', 'Trouser', 'Pullover', 'Dress',
#                    'Coat', 'Sandal', 'Shirt', 'Sneaker', 'Bag', 'Ankle boot']
#     outfit = class_names[np.argmax(prediction)]

#     # if outfit == null:
#     #     print("no suitable outrit found")

#     # Encode the resulting image as base64
#     buffered = io.BytesIO()
#     image.save(buffered, format="PNG")
#     encoded_image = base64.b64encode(buffered.getvalue()).decode('utf-8')

#     # Return the recommended outfit and the encoded image as a JSON response
#     response = {'outfit': outfit, 'image_bytes': encoded_image}
#     return jsonify(response)


# if __name__ == '__main__':
#     app.run(debug=True)


app = Flask(__name__)

# Load the saved model
# model = tf.keras.models.load_model('best_weights.hdf5')
model = tf.keras.models.load_model('model.weights.hdf5')


@app.route('/recommend-outfit', methods=['POST'])
def recommend_outfit():
    # Get the list of base64-encoded images from the request
    image_bytes_list = request.json['image_bytes_list']

    # Decode the images and store them in a list
    images = []
    for image_bytes in image_bytes_list:
        img_data = base64.b64decode(image_bytes)
        img_pil = Image.open(io.BytesIO(img_data))
        images.append(img_pil)

    # Preprocess the images and run them through the model
    predictions = []
    for image in images:
        # Resize the image to a fixed size of 32x32 pixels
        image = image.resize((28, 28))

        # Convert the image to a 3D NumPy array and normalize its values
        image_array = np.array(image.convert('L')).astype(np.float32) / 255.0
        # image_array = np.expand_dims(image_array, axis=0)
        image_array = np.reshape(image_array, (1, 28, 28))
        # image_array = np.expand_dims(image_array, axis=1)

        # Use the model to generate a prediction for the input image
        prediction = model.predict(image_array, batch_size=1)

        # Map the predicted fashion item class index to the corresponding item name
        class_names = ['T-shirt/top', 'Trouser', 'Pullover', 'Dress',
                       'Coat', 'Sandal', 'Shirt', 'Sneaker', 'Bag', 'Ankle boot']
        outfit = class_names[np.argmax(prediction)]

        # Append the predicted outfit to the list of predictions
        predictions.append(outfit)

    # Encode the resulting images as base64
    encoded_images = []
    for image in images:
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        encoded_image = base64.b64encode(buffered.getvalue()).decode('utf-8')
        encoded_images.append(encoded_image)

    # Return the recommended outfits and the encoded images as a JSON response
    response = {'outfits': predictions, 'image_bytes_list': encoded_images}
    return jsonify(response)


if __name__ == '__main__':
    app.run(debug=True)
