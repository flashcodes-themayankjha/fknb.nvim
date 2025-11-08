import base64
import tempfile
import os

def save_image(base64_data):
    """Saves base64 encoded image data to a temporary file and returns the path."""
    try:
        image_data = base64.b64decode(base64_data)
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            f.write(image_data)
            return f.name
    except Exception as e:
        return str(e)
