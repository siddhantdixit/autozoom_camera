import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_restart/flutter_restart.dart';

import 'dart:math' as math;

import 'models.dart';

typedef void Callback(List<dynamic> list, int h, int w);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  final String model;

  Camera(this.cameras, this.model, this.setRecognitions);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  bool isDetecting = false;

  double scale = 1.0;


  var verticalDistanceGap;
  var horizontalDistanceGap;


  var screenH;
  var screenW;

  void calcGaps(startX,startY,w,h)
  {
    var gapY = (screenH/2) - ((startY+h)/2);
    var gapX = (screenW/2) - ((startX+w)/2);
    verticalDistanceGap = gapY.abs();
    horizontalDistanceGap = gapX.abs();
  }

  percentageDecrease(startX, startY, w, h)
  {
      calcGaps(startX, startY, w, h);

      var L1 = screenH;
      var W1 = screenW;

      var Ls = h;
      var Ws = w;

      var x = horizontalDistanceGap;
      var y = verticalDistanceGap;
      var ans =  ( ( (L1 * W1) - (L1 * Ws) - (Ls*W1) + (Ls*Ws) + (2*x*L1) - (2*x*Ls) + (2*y*W1) - (2*y*Ws) ) / (L1*W1) ) * 100 ;
      return ans;
  }


  getPercentageDecrease(x9,w9,y9,h9, imgH,imgW)
  {
    var _x = x9;
    var _w = w9;
    var _y = y9;
    var _h = h9;
    var scaleW, scaleH, x, y, w, h;


    var previewH = imgH;
    var previewW = imgW;

    if (screenH / screenW > previewH / previewW) {
      scaleW = screenH / previewH * previewW;
      scaleH = screenH;
      var difW = (scaleW - screenW) / scaleW;
      x = (_x - difW / 2) * scaleW;
      w = _w * scaleW;
      if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
      y = _y * scaleH;
      h = _h * scaleH;
    } else {
      scaleH = screenW / previewW * previewH;
      scaleW = screenW;
      var difH = (scaleH - screenH) / scaleH;
      x = _x * scaleW;
      w = _w * scaleW;
      y = (_y - difH / 2) * scaleH;
      h = _h * scaleH;
      if (_y < difH / 2) h -= (difH / 2 - _y) * scaleH;
    }

    // x = math.max(0, x);
    // y = math.max(0, y);

    var res = percentageDecrease(x,y,w,h);
    return res;
  }

  percentageToZoomLevel(percentage)
  {
    // var maxZoom = await controller.getMaxZoomLevel();
    // print("Maximum Zoom Level => $maxZoom");
    // Max Zoom level = 10
    var declevl = (percentage/100);

    if(declevl < 0)
      return 1.0;
    return declevl + 1.0;
  }



  @override
  void initState() {
    super.initState();



    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        Size screen = MediaQuery.of(context).size;
        screenH = screen.height;
        screenW = screen.width;

        controller.startImageStream((CameraImage img) {
          if (!isDetecting) {
            isDetecting = true;

            int startTime = new DateTime.now().millisecondsSinceEpoch;

            if (widget.model == mobilenet) {
              Tflite.runModelOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(),
                imageHeight: img.height,
                imageWidth: img.width,
                numResults: 2,
              ).then((recognitions) {
                int endTime = new DateTime.now().millisecondsSinceEpoch;
                print("Detection took ${endTime - startTime}");

                widget.setRecognitions(recognitions, img.height, img.width);

                isDetecting = false;
              });
            } else if (widget.model == posenet) {
              Tflite.runPoseNetOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(),
                imageHeight: img.height,
                imageWidth: img.width,
                numResults: 2,
              ).then((recognitions) {
                int endTime = new DateTime.now().millisecondsSinceEpoch;
                print("Detection took ${endTime - startTime}");

                widget.setRecognitions(recognitions, img.height, img.width);

                isDetecting = false;
              });
            } else {
              Tflite.detectObjectOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(),
                model: widget.model == yolo ? "YOLO" : "SSDMobileNet",
                imageHeight: img.height,
                imageWidth: img.width,
                imageMean: widget.model == yolo ? 0 : 127.5,
                imageStd: widget.model == yolo ? 255.0 : 127.5,
                numResultsPerClass: 1,
                threshold: widget.model == yolo ? 0.2 : 0.4,
              ).then((recognitions) async {
                int endTime = new DateTime.now().millisecondsSinceEpoch;
                print("Detection took ${endTime - startTime}");

                widget.setRecognitions(recognitions, img.height, img.width);


                if(recognitions.isNotEmpty) {
                  recognitions.sort((b, a) =>
                  a["confidenceInClass"].compareTo(b["confidenceInClass"]));

                  var bestRecog = recognitions[0];
                  var truePercent = (bestRecog["confidenceInClass"] * 100);
                  var _x = bestRecog["rect"]["x"];
                  var _w = bestRecog["rect"]["w"];
                  var _y = bestRecog["rect"]["y"];
                  var _h = bestRecog["rect"]["h"];

                  print("==============Best Recognition =====================");
                  print("${bestRecog["detectedClass"]} : ${truePercent}          x=${_x} y=${_y} w=${_w} h=${_h}");
                  print("===================== ==============================");


                  var val  = getPercentageDecrease(_x,_w,_y,_h,img.height,img.width);

                  print("************    Percentage Decrease Req = $val");


                  var zoomReq = percentageToZoomLevel(val);
                  await controller.setZoomLevel(zoomReq);

                }
                isDetecting = false;
              });
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;


    var cameraPreview = new CameraPreview(controller);


    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: GestureDetector(
          //Making to Reset the Zoom Level on Double Tap
          onTap: () async {
            // Take the Picture in a try / catch block. If anything goes wrong,
            // catch the error.
            try {
              // Ensure that the camera is initialized.

              // Attempt to take a picture and get the file `image`
              // where it was saved.
              await controller.stopImageStream();
              final image = await controller.takePicture();

              if (!mounted) return;

              // If the picture was taken, display it on a new screen.
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(
                    // Pass the automatically generated path to
                    // the DisplayPictureScreen widget.
                    imagePath: image.path,
                  ),
                ),
              );

              final result = await FlutterRestart.restartApp();
              print(result);


            } catch (e) {
              // If an error occurs, log the error to the console.
              print(e);
            }
          },
          onDoubleTap: (){
            controller.setZoomLevel(1.0);
            setState(() {});
          },
          // onScaleUpdate:(one){
          //   print(one.scale);
          //
          //   scale = one.scale;
          //
          //   controller.setZoomLevel(scale);
          //
          //   setState(() {});
          // },

          child: cameraPreview

      )
    );

/*

    if (!controller.value.isInitialized) {
      return new Container();
    }

    var cameraPreview = new CameraPreview(controller);

    return new GestureDetector(
        onScaleUpdate:(one){
          print(one.scale);

          scale = one.scale;
          setState(() {});
        },

        child: new Transform.scale(
            scale: scale,
            child: new AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: cameraPreview
            )
        )


    );

 */
  }
}


// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
    );
  }
}
