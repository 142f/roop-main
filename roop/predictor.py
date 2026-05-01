import threading
import cv2
import numpy
import opennsfw2
from PIL import Image
from tensorflow.keras import Model

from roop.typing import Frame

PREDICTOR = None
THREAD_LOCK = threading.Lock()
MAX_PROBABILITY = 0.85


def get_predictor() -> Model:
    global PREDICTOR

    with THREAD_LOCK:
        if PREDICTOR is None:
            PREDICTOR = opennsfw2.make_open_nsfw_model()
    return PREDICTOR


def clear_predictor() -> None:
    global PREDICTOR

    PREDICTOR = None


def predict_frame(target_frame: Frame) -> bool:
    image = Image.fromarray(target_frame)
    image = opennsfw2.preprocess_image(image, opennsfw2.Preprocessing.YAHOO)
    views = numpy.expand_dims(image, axis=0)
    _, probability = get_predictor().predict(views)[0]
    return probability > MAX_PROBABILITY


def predict_image(target_path: str) -> bool:
    try:
        return opennsfw2.predict_image(target_path) > MAX_PROBABILITY
    except Exception as exception:
        print(f'[ROOP.PREDICTOR] Skipping image NSFW prediction: {exception}')
        return False


def predict_video(target_path: str) -> bool:
    capture = None
    try:
        capture = cv2.VideoCapture(target_path)
        if not capture.isOpened():
            return False
        frame_number = 0
        while True:
            has_frame, frame = capture.read()
            if not has_frame:
                return False
            if frame_number % 100 == 0:
                frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                if predict_frame(frame):
                    return True
            frame_number += 1
    except Exception as exception:
        print(f'[ROOP.PREDICTOR] Skipping video NSFW prediction: {exception}')
        return False
    finally:
        if capture:
            capture.release()
