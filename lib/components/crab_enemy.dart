import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class CrabEnemy extends Enemy {
  final Random _random = Random();
  double _sideMovementTimer = 0;
  double _sideMovementFrequency = 1.5; // Yatay hareket sıklığı
  double _sideSpeed = 80.0;
  int _sideDirection = 1;
  bool _isDefending = false;
  
  CrabEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : super(position: position, size: size, game: game) {
    // Düşman yengeç özellikleri: savunmacı ve dayanıklı
    health = 190;    // Çok daha fazla can
    damage = 10;     // Normal hasar
    scoreValue = 30; // Orta seviye puan
    
    // Başlangıçta rastgele yön seç
    _sideDirection = _random.nextBool() ? 1 : -1;
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Düşman yengeç sprite'ını yükle
    sprite = await game.loadSprite('enemies/crab_enemy.png');
    
    // Düşman yengeç ana karakterin yengecinden daha küçük olsun
    scale = Vector2.all(0.9);
  }
  
  @override
  void update(double dt) {
    // Ana update metodunu çağır
    super.update(dt);
    
    // Aşağı doğru hareket (daha yavaş)
    position.y += 70 * dt;
    
    // Yatay hareket
    _sideMovementTimer += dt;
    if (_sideMovementTimer >= _sideMovementFrequency) {
      _sideMovementTimer = 0;
      _sideDirection = -_sideDirection; // Yön değiştir
      
      // Rastgele savunma durumuna geç
      if (_random.nextDouble() < 0.3 && !_isDefending) { // %30 ihtimalle
        _enterDefenseMode();
      } else {
        _isDefending = false;
      }
    }
    
    // Yatay hareket
    position.x += _sideDirection * _sideSpeed * dt;
    
    // Ekranın dışına çıkmasını önle
    if (position.x < 0) {
      position.x = 0;
      _sideDirection = 1;
    } else if (position.x > game.size.x - size.x) {
      position.x = game.size.x - size.x;
      _sideDirection = -1;
    }
    
    // Yengeç makaslama hareketi (savunma durumunda değilse)
    if (!_isDefending) {
      scale = Vector2(
        0.9 + sin(game.currentTime() * 6) * 0.05, 
        0.9 + cos(game.currentTime() * 6) * 0.05
      );
    }
  }
  
  void _enterDefenseMode() {
    _isDefending = true;
    
    // Savunma efekti (mavi parlama)
    final defenseEffect = ColorEffect(
      const Color.fromARGB(150, 0, 100, 255),
      EffectController(duration: _sideMovementFrequency),
      opacityTo: 0.5,
    );
    add(defenseEffect);
    
    // Savunma pozisyonunu göstermek için küçült
    add(ScaleEffect.to(
      Vector2.all(0.8), 
      EffectController(duration: 0.2),
    ));
    
    // Normal boyuta geri dön
    Future.delayed(Duration(milliseconds: (_sideMovementFrequency * 1000).toInt() - 200), () {
      if (isMounted) {
        add(ScaleEffect.to(
          Vector2.all(0.9), 
          EffectController(duration: 0.2),
        ));
      }
    });
  }
  
  @override
  void takeDamage(int damage) {
    // Savunma durumundaysa çok daha az hasar al
    if (_isDefending) {
      int reducedDamage = (damage * 0.2).toInt(); // %80 hasar azaltma
      print('CrabEnemy defense active! Damage reduced: $damage -> $reducedDamage');
      super.takeDamage(reducedDamage);
    } else {
      super.takeDamage(damage);
    }
  }
}