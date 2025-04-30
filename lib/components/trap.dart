import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class Trap extends SpriteComponent with HasGameRef<ProveOfSurviveGame>, CollisionCallbacks {
  final ProveOfSurviveGame game;
  final double _lifespan = 5.0; // Tuzağın kalma süresi (saniye)
  double _timer = 0;
  int damage = 30; // Verdiği hasar
  int health = 3;  // Tuzağın kaç düşmanı yakalayabileceği
  bool isActive = true;
  
  Trap({
    required Vector2 position,
    required Vector2 size,
    required this.game,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Tuzak sprite'ını yükle
    sprite = await game.loadSprite('items/trap.png');
    
    // Çarpışma kutusu ekle - active yapıyoruz ki düşmanlarla etkileşime girebilsin
    add(RectangleHitbox()..collisionType = CollisionType.active);
    
    // Tuzak yerleştirildiğinde büyüyerek ortaya çıkma animasyonu
    scale = Vector2.all(0.1);
    final appearEffect = ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.3, curve: Curves.elasticOut),
    );
    add(appearEffect);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Yaşam süresini takip et
    _timer += dt;
    if (_timer >= _lifespan && isActive) {
      // Yaşam süresi dolduysa yok olma animasyonu
      disappear();
    }
    
    // Tuzağın hafifçe dalgalanması (su altında olduğu hissi için)
    angle = sin(game.currentTime() * 2) * 0.05;
  }
  
  void takeDamage(int amount) {
    if (!isActive) return;
    
    health -= amount;
    print('Trap health: $health');
    
    if (health <= 0) {
      disappear();
    } else {
      // Hasar aldığında efekt göster
      final hitEffect = ColorEffect(
        const Color.fromARGB(255, 100, 100, 255),
        EffectController(duration: 0.2),
      );
      add(hitEffect);
    }
  }
  
  void disappear() {
    if (!isActive) return;
    
    isActive = false;
    
    // Yok olma animasyonu
    final disappearEffect = ScaleEffect.to(
      Vector2.all(0.1),
      EffectController(duration: 0.5),
      onComplete: removeFromParent,
    );
    add(disappearEffect);
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // Düşmanla çarpışma tespiti
    if (other is Enemy && isActive) {
      print('Trap caught an enemy!');
      // Düşmana hasar ver
      other.takeDamage(damage);
    }
  }
}