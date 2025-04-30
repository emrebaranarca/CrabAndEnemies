import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class TextBubble extends PositionComponent {
  final String text;
  final double lifespan;
  double _timer = 0;
  late TextComponent _textComponent;
  late RectangleComponent _bubble;
  late PolygonComponent _triangle;
  bool _isFading = false;

  TextBubble({
    required this.text,
    required Vector2 position,
    this.lifespan = 2.0,
  }) : super(position: position);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final textSize = _textComponent.size;
    final padding = 10.0;

    _bubble = RectangleComponent(
      size: Vector2(textSize.x + padding * 2, textSize.y + padding * 2),
      position: Vector2(-padding, -padding),
      paint: Paint()
        ..color = Colors.white.withOpacity(0.8) // Şeffaflık eklendi
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0), // Köşeleri yumuşat
    );

    _triangle = PolygonComponent(
      [
        Vector2(textSize.x / 2 - 10, textSize.y + padding),
        Vector2(textSize.x / 2 + 10, textSize.y + padding),
        Vector2(textSize.x / 2, textSize.y + padding + 15),
      ],
      paint: Paint()
        ..color = Colors.white.withOpacity(0.8) // Şeffaflık eklendi
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0), // Köşeleri yumuşat
    );

    add(_bubble);
    add(_triangle);
    add(_textComponent);

    scale = Vector2.all(0);
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.3, curve: Curves.elasticOut),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);

    _timer += dt;
    if (_timer >= lifespan && !_isFading) {
      _isFading = true;
      add(ScaleEffect.to(
        Vector2.all(0.0),
        EffectController(duration: 0.3),
        onComplete: () {
          removeFromParent();
        },
      ));
    }
  }
}