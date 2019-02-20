import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_example/pages/pager_indicator.dart';

class PageDragger extends StatefulWidget {
  final bool canDragLeftToRight;
  final bool canDragRightToLeft;
  final StreamController<SlideUpdate> slideUpdateStream;

  const PageDragger(
      {Key key,
      this.canDragLeftToRight,
      this.canDragRightToLeft,
      this.slideUpdateStream})
      : super(key: key);

  @override
  PageDraggerState createState() => new PageDraggerState();
}

class PageDraggerState extends State<PageDragger> {
  static const FULL_TRANSITION_PX = 300.0;

  Offset dragStart;
  SlideDirection slideDirection;
  double slidePercent = 0.0;

  onDragStart(DragStartDetails details) {
    dragStart = details.globalPosition;
  }

  onDragUpdate(DragUpdateDetails details) {
    if (dragStart != null) {
      final newPosition = details.globalPosition;
      final dx = dragStart.dx - newPosition.dx;
      if (dx > 0.0 && widget.canDragRightToLeft) {
        slideDirection = SlideDirection.rightToLeft;
      } else if (dx < 0.0 && widget.canDragLeftToRight) {
        slideDirection = SlideDirection.leftToRight;
      } else {
        slideDirection = SlideDirection.none;
      }

      if (slideDirection != SlideDirection.none) {
        slidePercent = (dx / FULL_TRANSITION_PX).abs().clamp(0.0, 1.0);
      } else {
        slidePercent = 0.0;
      }
      widget.slideUpdateStream.add(
          new SlideUpdate(UpdateType.dragging, slideDirection, slidePercent));

      print('Dragging $slideDirection at $slidePercent%');
    }
  }

  onDragEnd(DragEndDetails details) {
    widget.slideUpdateStream.add(
        new SlideUpdate(UpdateType.doneDragging, SlideDirection.none, 0.0));
    dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onHorizontalDragStart: onDragStart,
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  void didUpdateWidget(PageDragger oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }
}

enum UpdateType {
  dragging,
  doneDragging,
  animating,
  doneAnimating,
}

class AnimatedPageDragger {
  static const PERCENT_PER_MILLISECOND = 0.005;

  final slideDirection;
  final transitionGoal;

  AnimationController completionAnimationController;

  AnimatedPageDragger({
    this.slideDirection,
    this.transitionGoal,
    slidePercent,
    StreamController<SlideUpdate> slideUpdateStream,
    TickerProvider vsync,
  }) {

    final startSlidePercent = slidePercent;
    var endSlidePercent;
    var duration;

    if(transitionGoal == TransitionGoal.open){
      endSlidePercent = 1.0;
      final slideRemaining = 1.0 - slidePercent;
      duration = new Duration(
        milliseconds: (slideRemaining / PERCENT_PER_MILLISECOND).round()
      );
    }else {
      endSlidePercent = 0.0;
      duration = new Duration(
        milliseconds: (slidePercent / PERCENT_PER_MILLISECOND).round()
      );
    }

    completionAnimationController = new AnimationController(
      duration: duration,
      vsync: vsync,
    )..addListener((){
      print('startSlidePercent ${startSlidePercent} ; endSlidePercent ${endSlidePercent} ');
      slidePercent = lerpDouble(startSlidePercent, endSlidePercent, completionAnimationController.value);
      slideUpdateStream.add(
       new SlideUpdate(UpdateType.animating, slideDirection, slidePercent)
      );
    })..addStatusListener((AnimationStatus status){
      if(status ==  AnimationStatus.completed){
        slideUpdateStream.add(new SlideUpdate(UpdateType.doneAnimating, slideDirection, endSlidePercent));
      }
    });
  }


  run(){
    completionAnimationController.forward(from: 0.0);
  }

  dispose(){
    completionAnimationController.dispose();
  }

}

enum TransitionGoal {
  open,
  close,
}

class SlideUpdate {
  final updateType;
  final direction;
  final slidePercent;

  SlideUpdate(this.updateType, this.direction, this.slidePercent);
}