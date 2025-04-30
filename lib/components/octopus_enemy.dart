import 'dart:math';
import 'package:flame/components.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class OctopusEnemy extends Enemy {
  final Random _random = Random();
  double _directionChangeTimer = 0;
  double _directionChangeCooldown = 2.0; // 2 saniyede bir yön değiştir
  double _horizontalSpeed = 0;
  
  OctopusEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : super(position: position, size: size, game: game) {
    // Ahtapot özellikleri: daha güçlü ve dayanıklı
    health = 140;    // Daha fazla can
    damage = 15;     // Daha fazla hasar
    scoreValue = 25; // Daha fazla puan
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Ahtapot sprite'ını yükle
    sprite = await game.loadSprite('enemies/octopus.png');
    
    // Ahtapot daha yavaş ama daha güçlü
    _horizontalSpeed = _random.nextDouble() * 100 - 50; // -50 ile 50 arası rastgele hız
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Ahtapota özel hareket: daha kompleks ve kurnaz
    _directionChangeTimer += dt;
    if (_directionChangeTimer >= _directionChangeCooldown) {
      _horizontalSpeed = _random.nextDouble() * 140 - 70; // -70 ile 70 arası rastgele hız
      _directionChangeTimer = 0;
      _directionChangeCooldown = 1.0 + _random.nextDouble() * 2.0; // 1-3 saniye arası
    }
    
    // Yatay hareket
    position.x += _horizontalSpeed * dt;
    
    // Ekranın dışına çıkmasını önle
    if (position.x < 0) {
      position.x = 0;
      _horizontalSpeed *= -1;
    } else if (position.x > game.size.x - size.x) {
      position.x = game.size.x - size.x;
      _horizontalSpeed *= -1;
    }
    
    // Tentacle animasyonu (kolların salınması)
    angle = sin(game.currentTime() * 2) * 0.05; // Hafif sallanma
    
    // Pulsing efekti (büyüyüp küçülme)
    final pulseFactor = 1.0 + sin(game.currentTime() * 3) * 0.05;
    scale = Vector2.all(pulseFactor);
  }
  
  @override
  void takeDamage(int damage) {
    // Ahtapot daha dayanıklı, daha az hasar alır
    print('Octopus taking damage: $damage, with damage reduction');
    super.takeDamage((damage * 0.7).toInt());
    
    // Hasar alınca kaçmaya çalışır - yön değiştirme
    _horizontalSpeed = (_random.nextBool() ? 1 : -1) * (_random.nextDouble() * 150 + 50);
  }
}