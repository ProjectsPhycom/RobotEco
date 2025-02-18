import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:walle_app/core/config.dart';

import 'package:walle_app/core/ui-system/colors.dart';
import 'package:walle_app/features/wall-e/arm/domain/arm.dart';



class ArmSlide extends StatefulWidget {
  late Arm arm;
  double heightSlide;
  ArmSlide(this.arm, {
    Key? key,
    this.heightSlide = 200,
  }) : super(key: key);

  @override
  State<ArmSlide> createState() => _ArmSlideState(
    this.arm,
    this.arm.assetName, 
    this.arm.actualPosition,
    heightSlide: this.heightSlide,
    thumbSize: 48,
    trackHeight: 8,
    activeTrackColor: yellow,
    inactiveTrackColor: sky_blue,

  );
}

class _ArmSlideState extends State<ArmSlide> {
  Arm arm;
  double _value;
  String assetName;
  ui.Image? customThumb;

  int thumbSize;
  double trackHeight;
  Color activeTrackColor;
  Color inactiveTrackColor;

  double heightSlide;

  
  _ArmSlideState(this.arm, this.assetName, this._value,{
    required this.heightSlide,
    required this.thumbSize,
    required this.trackHeight,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
  });
  
  /// Extensions supported: SVG
  Future<ui.Image> loadSvg(String asset) async {
    String svgString = await DefaultAssetBundle.of(context).loadString(asset);
    print(svgString);
    final PictureInfo pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), context);
    
    // to have a nice rendering it is important to have the exact original height and width,
    // the easier way to retrieve it is directly from the svg string
    // but be careful, this is an ugly fix for a flutter_svg problem that works
    // with my images
    String temp = svgString.substring(svgString.indexOf('width="')+7);
    int originalWidth = int.parse(temp.substring(0, temp.indexOf('"')));
    temp = svgString.substring(svgString.indexOf('height="')+8);
    int originalHeight = int.parse(temp.substring(0, temp.indexOf('"')));
    print("Dimensiones: ");
    print(originalWidth);
    print(originalHeight);

    // toPicture() and toImage() don't seem to be pixel ratio aware, so we calculate the actual sizes here
    /*double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    print("devicePixelRatio");
    print(devicePixelRatio);
    int width = (originalHeight * devicePixelRatio).toInt(); // where 32 is your SVG's original width
    int height = (originalWidth * devicePixelRatio).toInt(); // same thing
    print("Dimensiones: ");
    print(width);
    print(height);
    */
    
    ui.Image image = await pictureInfo.picture.toImage(originalWidth, originalHeight);
    //ui.Image image = await pictureInfo.picture.toImage(width, height);

    ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    ui.Codec codec = await ui.instantiateImageCodec(
      data!.buffer.asUint8List(),
      targetHeight: this.thumbSize,
      targetWidth: this.thumbSize,
    );
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
  
  /// Extensions supported: JPEG, PNG, GIF, Animated GIF, WebP, Animated WebP, BMP, and WBMP
  Future<ui.Image> load(String asset) async {
    ByteData data = await rootBundle.load(asset);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: this.thumbSize,
      targetWidth: this.thumbSize,
    );
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }
  
  @override
  void initState() {
    loadSvg(this.assetName).then((image) {
      setState(() {
        customThumb = image;
      });
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightSlide,
      child: SfSliderTheme(
        data: SfSliderThemeData(
          overlayRadius: 24,
          activeTrackColor: this.activeTrackColor,
          inactiveTrackColor: this.inactiveTrackColor,
          activeTrackHeight: this.trackHeight,
          inactiveTrackHeight: this.trackHeight,
        ),
        child: SfSlider.vertical(
          min: arm.minPosition,
          max: arm.maxPosition,
          thumbShape: customThumb != null
              ? _SfThumbShape(this.customThumb!)
              : const SfThumbShape(),
          value: _value,
          showTicks: false,    // separadores
          showLabels: false,   // valor en separadores
          enableTooltip: false,// label con el valor actual mientras lo muevo
          onChanged: (dynamic newValue){
            setState(() {
              _value = newValue;
              this.arm.setPosition(_value);
              wall_e.sendMessage();
            });
          },
        ),
      ),
    );
  }
  
  /*
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        //overlayRadius: 24,
        activeTrackColor: this.activeTrackColor,
        inactiveTrackColor: this.inactiveTrackColor,
        trackHeight: this.trackHeight,
        thumbShape: this.customThumb != null
          ? SliderThumbImage(this.customThumb!)
          : const RoundSliderThumbShape(),
      ),
      child: Slider.adaptive(
        min: arm.minPosition.toDouble(),
        max: arm.maxPosition.toDouble(),
        value: _value,
        onChanged: (dynamic newValue){
          setState(() {
            _value = newValue;
            this.arm.setPosition(_value);
          });
        },

      ),
    );
        
  }
  */
}



class _SfThumbShape extends SfThumbShape {

  late final ui.Image image;

  _SfThumbShape(this.image);
  

  @override
  void paint(PaintingContext context, Offset center,
    {required RenderBox parentBox,
    required RenderBox? child,
    required SfSliderThemeData themeData,
    SfRangeValues? currentValues,
    dynamic currentValue,
    required Paint? paint,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required SfThumb? thumb}
    ) {
    
    var canvas = context.canvas;
    final picWidth = image.width;
    final picHeight = image.height;

    Offset picOffset = Offset(
      (center.dx - (picWidth / 2)),
      (center.dy - (picHeight / 2)),
    );

    Paint paint = Paint()..filterQuality = FilterQuality.high;
    if (image != null) {
      canvas.drawImage(
        image, 
        picOffset, 
        paint
      );
    }
    
  }
}


class SliderThumbImage extends SliderComponentShape {
  final ui.Image image;

  SliderThumbImage(this.image);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
      return Size(10, 10);
  }

  @override
  void paint(PaintingContext context, Offset center,{
    required Animation<double> activationAnimation, 
    required Animation<double> enableAnimation, 
    required bool isDiscrete, 
    required TextPainter labelPainter, 
    required RenderBox parentBox, 
    required Size sizeWithOverflow, 
    required SliderThemeData sliderTheme, 
    required TextDirection textDirection, 
    required double textScaleFactor, 
    required double value
    }) {
    var canvas = context.canvas;
    final picWidth = image.width;
    final picHeight = image.height;

    Offset picOffset = Offset(
      (center.dx - (picWidth / 2)),
      (center.dy - (picHeight / 2)),
    );

    Paint paint = Paint()..filterQuality = FilterQuality.high;
    if (image != null) {
      canvas.drawImage(
        image, 
        picOffset, 
        paint
      );
    }
  }
}
