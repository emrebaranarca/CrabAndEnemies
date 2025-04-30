import 'dart:math';

import 'package:flame/components.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class FishEnemy extends Enemy {
  FishEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : super(position: position, size: size, game: game) {
    // Balık özellikleri: daha hızlı ama zayıf
    health = 70;     // Daha az can
    damage = 8;      // Daha az hasar
    scoreValue = 15; // Daha fazla puan
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Balık sprite'ını yükle
    sprite = await game.loadSprite('enemies/fish.png');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Balığa özel hareket: daha hızlı ama daha zayıf
    position.y += 20 * dt; // Ek hız
    
    // Balık yüzme animasyonu - sallanma efekti
    angle = sin(game.currentTime() * 3) * 0.1; // Hafif sallanma
  }
}