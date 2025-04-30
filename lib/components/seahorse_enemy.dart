import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class SeahorseEnemy extends Enemy {
  final Random _random = Random();
  bool _isTeleporting = false;
  double _teleportTimer = 0;
  double _teleportCooldown = 4.0; // 4 saniyede bir ışınlanma
  late Vector2 _startPosition;
  Vector2? _teleportTarget;
  bool _isCloaked = false;
  double _cloakTimer = 0;
  
  SeahorseEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : super(position: position, size: size, game: game) {
    // Denizatı özellikleri: hızlı, zor hedef alınır
    health = 100;     // Orta düzey can
    damage = 12;      // Orta düzey hasar
    scoreValue = 25;  // Orta seviye puan
    _startPosition = position.clone();
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Denizatı sprite'ını yükle
    sprite = await game.loadSprite('enemies/seahorse.png');
  }
  
  @override
  void update(double dt) {
    if (_isTeleporting) {
      _updateTeleportation(dt);
    } else {
      super.update(dt);
      
      // Normal hareket - spiral şeklinde aşağı doğru
      _updateNormalMovement(dt);
      
      // Görünmezlik sürecini kontrol et
      if (_isCloaked) {
        _cloakTimer += dt;
        if (_cloakTimer >= 1.5) { // 1.5 saniye görünmez kalır
          _uncloak();
        }
      }
      
      // Teleportasyon zamanlaması
      _teleportTimer += dt;
      if (_teleportTimer >= _teleportCooldown && !_isCloaked) {
        _startTeleport();
      }
    }
  }
  
  void _updateNormalMovement(double dt) {
    // Spiral hareket
    double time = game.currentTime();
    double radius = 40; // Spiral genişliği
    double speed = 70 * dt; // Aşağı hareket hızı
    
    // Spiral yörünge için yatay hareket hesapla
    position.x = _startPosition.x + sin(time * 2) * radius;
    
    // Aşağı doğru sabit hareket
    position.y += speed;
    
    // Denizatının duruşunu ayarla (yüzme animasyonu)
    angle = sin(time * 3) * 0.1; // Hafif salınım
    
    // Ekranın altından çıkarsa yok et
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
  
  void _startTeleport() {
    _isTeleporting = true;
    _teleportTimer = 0;
    
    // Teleport hedefini belirle - ekran içinde rastgele bir nokta
    double targetX = _random.nextDouble() * (game.size.x - size.x);
    // Her zaman aşağı doğru hareket etsin - şu anki konumdan biraz aşağıda
    double targetY = position.y + 100 + _random.nextDouble() * 100;
    // Ekranın altından çıkmasını önle
    if (targetY > game.size.y - size.y) {
      targetY = game.size.y - size.y - 50;
    }
    
    _teleportTarget = Vector2(targetX, targetY);
    
    // Kaybolma efekti - OpacityEffect yerine ScaleEffect kullan
    add(ScaleEffect.to(
      Vector2.all(0.1),
      EffectController(duration: 0.3),
      onComplete: () {
        // Konumu değiştir
        position = _teleportTarget!;
        // Tekrar görünür ol
        add(ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.3),
          onComplete: () {
            _isTeleporting = false;
            // Teleport sonrası kısa süre görünmez ol
            _cloak();
          },
        ));
      },
    ));
  }
  
  void _updateTeleportation(double dt) {
    // Teleportasyon sırasında özel bir şey yapmaya gerek yok, efektler halledecek
  }
  
  void _cloak() {
    if (_isCloaked) return;
    
    _isCloaked = true;
    _cloakTimer = 0;
    
    // Yarı saydam görünüm - OpacityEffect yerine ColorEffect kullan 
    add(ColorEffect(
      const Color.fromARGB(100, 255, 255, 255),
      EffectController(duration: 0.5),
    ));
  }
  
  void _uncloak() {
    if (!_isCloaked) return;
    
    _isCloaked = false;
    
    // Normal görünüme dön
    add(ColorEffect(
      Colors.white,
      EffectController(duration: 0.5),
    ));
  }
  
  @override
  void takeDamage(int damage) {
    // Görünmez durumdayken daha az hasar al
    if (_isCloaked) {
      int reducedDamage = (damage * 0.5).toInt(); // %50 hasar azaltma
      print('Seahorse cloaked! Damage reduced: $damage -> $reducedDamage');
      super.takeDamage(reducedDamage);
      
      // Hasar almak görünmezliği bozabilir
      if (_random.nextDouble() < 0.7) { // %70 ihtimalle
        _uncloak();
      }
    } else {
      super.takeDamage(damage);
      
      // Kritik hasar aldığında ışınlanabilir
      if (health < 50 && !_isTeleporting && _random.nextDouble() < 0.6) {
        _startTeleport();
      }
    }
  }
}