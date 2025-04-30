import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class PufferfishEnemy extends Enemy {
  final Random _random = Random();
  bool _isInflated = false;
  double _inflateTimer = 0;
  double _inflateCooldown = 3.0; // 3 saniyede bir şişme
  double _inflateDuration = 2.0; // 2 saniye şişkin kalır
  double _baseSpeed = 80.0;
  int _baseDamage;
  double _explosionRadius = 100.0;
  bool _isExploding = false;
  
  PufferfishEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : _baseDamage = 12,
       super(position: position, size: size, game: game) {
    // Balon balığı özellikleri: şişebilir, yakında patlayabilir
    health = 110;     // Orta düzey can
    damage = _baseDamage; // Normal hasar (şiştiğinde artacak)
    scoreValue = 30;  // Orta-yüksek seviye puan
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Balon balığı sprite'ını yükle
    sprite = await game.loadSprite('enemies/pufferfish.png');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isExploding) {
      return; // Patlama animasyonu sırasında hareket etme
    }
    
    // Normal hareket - aşağı doğru ve yatay salınım
    if (!_isInflated) {
      position.y += _baseSpeed * dt;
      position.x += sin(game.currentTime() * 2) * dt * 40;
      
      // Şişme zamanlayıcısı
      _inflateTimer += dt;
      if (_inflateTimer >= _inflateCooldown) {
        _inflate();
      }
    } else {
      // Şişkin durumdayken daha yavaş hareket
      position.y += (_baseSpeed * 0.5) * dt;
      
      // Şişkin kalma süresi
      _inflateTimer += dt;
      if (_inflateTimer >= _inflateDuration) {
        _deflate();
      }
      
      // Oyuncuya yakınsa ve şişkinse, patlama olasılığını kontrol et
      if (_isNearPlayer() && _random.nextDouble() < 0.01) { // %1 ihtimalle her frame
        _explode();
      }
    }
    
    // Ekranın altından çıkarsa yok et
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
  
  bool _isNearPlayer() {
    double distance = position.distanceTo(game.player.position);
    return distance < _explosionRadius;
  }
  
  void _inflate() {
    if (_isInflated) return;
    
    _isInflated = true;
    _inflateTimer = 0;
    damage = _baseDamage * 2; // Şiştiğinde hasar artar
    
    print('Pufferfish inflating!');
    
    // Şişme animasyonu
    add(ScaleEffect.to(
      Vector2.all(1.8), // Boyutu 1.8 kat büyüt
      EffectController(duration: 0.5, curve: Curves.elasticOut),
    ));
    
    // Renk değişimi - daha tehlikeli görünsün
    add(ColorEffect(
      const Color.fromARGB(255, 255, 100, 100), // Kırmızımsı renk
      EffectController(duration: 0.3),
    ));
    
    // Dikenler daha belirgin olsun - sınır çiz
    add(RotateEffect.by(
      0.1, // Hafif döndür
      EffectController(duration: 0.5, curve: Curves.bounceOut),
    ));
  }
  
  void _deflate() {
    if (!_isInflated) return;
    
    _isInflated = false;
    _inflateTimer = 0;
    damage = _baseDamage; // Normal hasara dön
    
    print('Pufferfish deflating');
    
    // Küçülme animasyonu
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.5),
    ));
    
    // Normal renge dön
    add(ColorEffect(
      Colors.white,
      EffectController(duration: 0.3),
    ));
    
    // Normal dönüşe dön
    add(RotateEffect.to(
      0.0,
      EffectController(duration: 0.3),
    ));
  }
  
  void _explode() {
    if (_isExploding) return;
    
    _isExploding = true;
    print('Pufferfish exploding!');
    
    // Patlama animasyonu
    add(ScaleEffect.to(
      Vector2.all(3.0),
      EffectController(duration: 0.3, curve: Curves.easeOut),
    ));
    
    // Parlama efekti
    add(ColorEffect(
      const Color.fromARGB(255, 255, 200, 50), // Sarı/turuncu patlama
      EffectController(duration: 0.3),
    ));
    
    // Çevredeki düşmanlara ve oyuncuya hasar ver
    _damageNearbyEntities();
    
    // Patlama sonrası kendini yok et
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isMounted) {
        die();
      }
    });
  }
  
  void _damageNearbyEntities() {
    // Oyuncuya hasar ver (eğer menzildeyse)
    double distanceToPlayer = position.distanceTo(game.player.position);
    if (distanceToPlayer < _explosionRadius) {
      // Uzaklığa göre hasar azalır
      double damageFactor = 1.0 - (distanceToPlayer / _explosionRadius);
      int explosionDamage = (damage * 1.5 * damageFactor).toInt();
      
      // Oyuncuya hasar ver (sağlığı doğrudan azalt)
      if (explosionDamage > 0) {
        game.health -= explosionDamage;
        print('Pufferfish explosion damaged player! Damage: $explosionDamage');
      }
    }
    
    // Diğer düşmanlara da hasar verebilir (isteğe bağlı - eklenmezse sadece oyuncuya hasar verir)
    // Bu özellik eklenmek istenirse burada diğer düşmanları kontrol edip onlara da hasar verilebilir
  }
  
  @override
  void takeDamage(int damage) {
    super.takeDamage(damage);
    
    // Kritik hasar aldığında şişmek veya patlamak için
    if (health < 40 && !_isInflated && _random.nextDouble() < 0.6) {
      _inflate();
      
      // Düşük sağlıkta patlama olasılığı
      if (_random.nextDouble() < 0.4) { // %40 ihtimalle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (isMounted && !isDestroyed) {
            _explode();
          }
        });
      }
    }
  }
}