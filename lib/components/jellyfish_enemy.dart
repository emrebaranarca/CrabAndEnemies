import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class JellyfishEnemy extends Enemy {
  final Random _random = Random();
  double _floatTimer = 0;
  double _floatDuration = 2.0;
  late Vector2 _initialSize;
  late ColorEffect _pulseEffect;
  bool _isElectrified = false;
  double _electroTimer = 0;
  double _electroCooldown = 5.0; // 5 saniyede bir elektriklenme
  
  JellyfishEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : super(position: position, size: size, game: game) {
    // Denizanası özellikleri: yavaş ama zehirli/elektrikli
    health = 80;      // Daha az can (hassas)
    damage = 15;      // Normal-yüksek hasar
    scoreValue = 20;  // Orta seviye puan
    _initialSize = size.clone();
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Denizanası sprite'ını yükle
    sprite = await game.loadSprite('enemies/jellyfish.png');
    
    // Nabız efekti ekle (sürekli)
    _setupPulsingEffect();
  }
  
  void _setupPulsingEffect() {
    // Sürekli nabız efekti
    _pulseEffect = ColorEffect(
      const Color.fromARGB(150, 200, 100, 255),
      EffectController(
        duration: 1.5,
        reverseDuration: 1.5,
        infinite: true,
      ),
      opacityFrom: 0.3,
      opacityTo: 0.8,
    );
    add(_pulseEffect);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Dalga benzeri yukarı-aşağı hareket
    _floatTimer += dt;
    double floatPhase = _floatTimer % _floatDuration / _floatDuration;
    
    // Sinüs dalgası şeklinde yukarı-aşağı hareket
    double verticalMovement = sin(floatPhase * 2 * pi) * 30;
    position.y += verticalMovement * dt;
    
    // Aşağı doğru genel hareket (daha yavaş)
    position.y += 40 * dt;
    
    // Ekranın altından çıkarsa yok et
    if (position.y > game.size.y + size.y) {
      removeFromParent();
      return;
    }
    
    // Nabız atışı efekti için büyüyüp küçülme
    scale = Vector2.all(0.9 + sin(game.currentTime() * 3) * 0.1);
    
    // Elektriklenme zamanlayıcı
    _electroTimer += dt;
    if (_electroTimer >= _electroCooldown && !_isElectrified) {
      _electrify();
    }
    
    // Elektrikliyken zaman aşımını kontrol et
    if (_isElectrified) {
      if (_electroTimer >= 2.0) { // 2 saniye elektrikli kalır
        _deelectrify();
      }
    }
    
    // Denizanası tentaküllerini sallandır
    angle = sin(game.currentTime() * 1.3) * 0.05;
  }
  
  void _electrify() {
    _isElectrified = true;
    _electroTimer = 0;
    damage *= 2; // Elektriklendiğinde hasarı iki katına çıkar
    
    // Elektriklenme efekti
    removeAll(children.whereType<ColorEffect>());
    final electricEffect = ColorEffect(
      const Color.fromARGB(200, 100, 200, 255),
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,
        infinite: true,
      ),
    );
    add(electricEffect);
    
    // Boyut efekti
    add(ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(duration: 0.5),
    ));
    
    // Etraftaki diğer düşmanlara elektrik çarpması efekti eklemek için
    // oyuncuya mesajı ilet
    _createElectricityEffect();
  }
  
  void _deelectrify() {
    _isElectrified = false;
    _electroTimer = 0;
    damage ~/= 2; // Hasarı normale döndür
    
    // Efektleri kaldır ve yeniden normal nabız efektini ekle
    removeAll(children.whereType<ColorEffect>());
    _setupPulsingEffect();
    
    // Normal boyuta dön
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.5),
    ));
  }
  
  void _createElectricityEffect() {
    // Çevreye elektrik yayılması efekti
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3; // 6 farklı yöne
      final distance = 30.0;
      
      final sparkPosition = Vector2(
        position.x + cos(angle) * distance,
        position.y + sin(angle) * distance,
      );
      
      // Oyunun çocuk bileşeni olarak elektrik kıvılcımı efekti ekle
      game.add(
        ElectricSpark(
          position: sparkPosition,
          duration: 0.8, // 0.8 saniye sürecek
        )
      );
    }
  }
  
  @override
  void takeDamage(int damage) {
    super.takeDamage(damage);
    
    // Hasar alınca elektriklenme ihtimali
    if (health > 0 && !_isElectrified && _random.nextDouble() < 0.4) { // %40 ihtimalle
      _electrify();
    }
  }
}

// Elektrik kıvılcımı efekti için yardımcı bileşen
class ElectricSpark extends PositionComponent {
  final double duration;
  late Paint _paint;
  double _timer = 0;
  final Random _random = Random();
  
  ElectricSpark({
    required Vector2 position,
    required this.duration,
  }) : super(position: position, size: Vector2.all(10));
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _paint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    add(ScaleEffect.by(
      Vector2.all(3.0),
      EffectController(duration: duration),
    ));
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Rastgele elektrik kıvılcımları çiz
    for (int i = 0; i < 4; i++) {
      final startPoint = Vector2(0, 0);
      final endPoint = Vector2(
        _random.nextDouble() * 10 - 5,
        _random.nextDouble() * 10 - 5,
      );
      
      canvas.drawLine(startPoint.toOffset(), endPoint.toOffset(), _paint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
    }
    
    // Zamanla solan kıvılcım
    _paint.color = _paint.color.withOpacity(1 - (_timer / duration));
  }
}