# AutoZoom Camera using Realtime Detection


Auto-zoom camera using real-time object detection in Flutter involves using the device camera to detect objects in real-time and automatically zooming in or out to focus on the detected object.




Steps involved:

- Firstly, We set up a camera preview in Flutter using the camera plugin. This will allow us to stream the camera feed to your app.

- Used a real-time object detection library such as tflite_flutter to detect objects in the camera feed. These libraries use the following machine learning models to identify objects in the camera feed in real-time.

1. SSD Mobilenet
2. YOLO

- Calculate the bounding box of the detected objects. The bounding box is a rectangle that encompasses the detected object. Get the boundary box of most accurate object.

- Use the bounding box information to zoom in on the object. You can use the camera_controller to set the zoom level based on the size of the bounding box.





# Referred Codebase for Realtime Object Detection


For details: https://medium.com/@shaqian629/real-time-object-detection-in-flutter-b31c7ff9ef96

# flutter_realtime_detection

Real-time object detection in Flutter using [camera](https://pub.dartlang.org/packages/camera) and [tflite](https://pub.dartlang.org/packages/tflite) plugin. 

## Install 

```
flutter packages get
```

## Run

```
flutter run
```

## Models

- Image Classification
  - MobileNet

- Object Detection
  - SSD MobileNet
  - Yolov2 Tiny

- Pose Estimation 
  - PoseNet

## Previews

![](preview.jpg) 

