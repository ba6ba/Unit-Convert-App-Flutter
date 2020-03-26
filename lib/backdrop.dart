import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterudacityapp/category.dart';

import 'dart:math' as math;

const double kFlingVelocity = 2.0;

class _BackdropPanel extends StatelessWidget {
  final VoidCallback onTap;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget title;
  final Widget child;

  const _BackdropPanel(
      {Key key,
      this.onTap,
      this.title,
      this.child,
      this.onVerticalDragEnd,
      this.onVerticalDragUpdate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2.0,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onVerticalDragUpdate,
            onVerticalDragEnd: onVerticalDragEnd,
            onTap: onTap,
            child: Container(
              height: 48.0,
              padding: EdgeInsetsDirectional.only(start: 16.0),
              alignment: AlignmentDirectional.centerStart,
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.subhead,
                child: title,
              ),
            ),
          ),
          Divider(
            height: 1.0,
          ),
          Expanded(
            child: child,
          )
        ],
      ),
    );
  }
}

class _BackdropTitle extends AnimatedWidget {
  final Widget frontTitle;
  final Widget backTitle;

  const _BackdropTitle(
      {Key key, Listenable listenable, this.backTitle, this.frontTitle})
      : super(key: key, listenable: listenable);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.listenable;
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.title,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      // Here, we do a custom cross fade between backTitle and frontTitle.
      // This makes a smooth animation between the two texts.
      child: Stack(
        children: <Widget>[
          Opacity(
            opacity: CurvedAnimation(
              parent: ReverseAnimation(animation),
              curve: Interval(0.5, 1.0)
            ).value,
            child: backTitle,
          ),
          Opacity(
            opacity: CurvedAnimation(
                parent: ReverseAnimation(animation),
                curve: Interval(0.5, 1.0)
            ).value,
            child: frontTitle,
          )
        ],
      ),
    );
  }
}

class Backdrop extends StatefulWidget {
  final Category currentCategory;
  final Widget frontPanel;
  final Widget backPanel;
  final Widget frontTitle;
  final Widget backTitle;

  const Backdrop({
    @required this.currentCategory,
    @required this.frontPanel,
    @required this.backPanel,
    @required this.frontTitle,
    @required this.backTitle,
}) : assert(currentCategory != null),
        assert(frontPanel != null),
        assert(backPanel != null),
        assert(frontTitle != null),
        assert(backTitle != null);

  @override
  _BackdropState createState()  => _BackdropState();
}

class _BackdropState extends State<Backdrop> with
    SingleTickerProviderStateMixin {

  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // This creates an [AnimationController] that can allows for animation for
    // the BackdropPanel. 0.00 means that the front panel is in "tab" (hidden)
    // mode, while 1.0 means that the front panel is open.
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      value: 1.0,
      vsync: this
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Backdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.currentCategory != oldWidget.currentCategory) {
      setState(() {
        _controller.fling(
          velocity: _backdropPanelVisible ? -kFlingVelocity : kFlingVelocity
        );
      });
    }
    else if(!_backdropPanelVisible) {
      setState(() {
        _controller.fling(velocity: kFlingVelocity);
      });
    }
  }

  bool get _backdropPanelVisible {
    return _controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.forward;
  }

  void _toggleBackdropPanelVisibility() {
    FocusScope.of(context).requestFocus(FocusNode());
    _controller.fling(
      velocity: _backdropPanelVisible ? -kFlingVelocity : kFlingVelocity;
    );
  }

  double get _backdropHeight {
    final RenderBox renderBox = _backdropKey.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  void _handleDragUpdate(DragUpdateDetails dragUpdateDetails) {
    if(_controller.isAnimating || _controller.status == AnimationStatus
        .completed) return;

    _controller.value -= dragUpdateDetails.primaryDelta / _backdropHeight;
  }

  void _handleDragEnd(DragEndDetails dragEndDetails) {
    if(_controller.isAnimating || _controller.status == AnimationStatus
        .completed) return;

    final double flingVelocity =
        dragEndDetails.velocity.pixelsPerSecond.dy / _backdropHeight;
    if(flingVelocity < 0.0) {
      _controller.fling(velocity: math.max(kFlingVelocity, -flingVelocity));
    }
    else if(flingVelocity > 0.0) {
      _controller.fling(velocity: math.min(-kFlingVelocity, -flingVelocity));
    }
    else {
      _controller.fling(
          velocity: _controller.value > 0.5 ? -kFlingVelocity : kFlingVelocity
      );
    }
  }

  Widget _buildStack(BuildContext context, BoxConstraints boxConstraints){
    const double panelTitleHeight = 48.0;
    final Size panelSize = boxConstraints.biggest;
    final double panelTop =  panelSize.height - panelTitleHeight;

    Animation<RelativeRect> panelAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(0.0, panelTop, 0.0, panelTop -
          panelTitleHeight),
      end: RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0)
    ).animate(_controller.view);

    return Container(
      key: _backdropKey,
      color: widget.currentCategory.color,
      child: Stack(
        children: <Widget>[
          widget.backPanel,
          PositionedTransition(
            rect: panelAnimation,
            child: _BackdropPanel(
              onTap: _toggleBackdropPanelVisibility,
              onVerticalDragUpdate: _handleDragUpdate,
              onVerticalDragEnd: _handleDragEnd,
              title: Text(widget.currentCategory.name),
              child: widget.frontPanel,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.currentCategory.color,
        elevation: 0.0,
        leading: IconButton(
          onPressed: _toggleBackdropPanelVisibility,
          icon: AnimatedIcon(
            icon: AnimatedIcons.close_menu,
            progress: _controller.view,
          ),
        ),
        title: _BackdropTitle(
          listenable: _controller.view,
          frontTitle: widget.frontTitle,
          backTitle: widget.backTitle,
        ),
      ),
      body: LayoutBuilder(
        builder: _buildStack,
      ),
    );
  }
}