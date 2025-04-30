import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class Crab extends SpriteComponent with HasGameRef<ProveOfSurviveGame>, KeyboardHandler, CollisionCallbacks {
  final ProveOfSurviveGame game;
  final double _speed = 1200.0;
  final double _attackCooldown = 0.5; // saniye cinsinden
  final int _attackDamage = 40; // Yengeç saldırısının verdiği hasar
  double _attackTimer = 0;
  bool _canAttack = true;
  bool _isAttacking = false;
  
  Crab({
    required Vector2 position,
    required Vector2 size,
    required this.game,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Yengeç sprite'ını yükle
    sprite = await game.loadSprite('characters/crab.png');
    
    // Çarpışma kutusu ekle
    add(RectangleHitbox()..collisionType = CollisionType.active);
    
    print('Crab loaded successfully');
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Saldırı bekleme süresini kontrol et
    if (!_canAttack) {
      _attackTimer += dt;
      if (_attackTimer >= _attackCooldown) {
        _canAttack = true;
        _attackTimer = 0;
      }
    }
    
    // Saldırı süresi bittiyse saldırıyı sonlandır
    if (_isAttacking) {
      _isAttacking = false;
    }
  }
  
@override
bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  try {
    // Klavye kontrollerini işle
    final isKeyDown = event is KeyDownEvent;
    
    // Sabit bir delta time değeri kullanıyoruz (60 FPS için yaklaşık 0.0167 saniye)
    const fixedDeltaTime = 1/60;
    
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || 
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      position.x -= _speed * fixedDeltaTime;
      // Ekrandan çıkmayı önle
      if (position.x < 0) position.x = 0;
    }
    
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || 
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      position.x += _speed * fixedDeltaTime;
      // Ekrandan çıkmayı önle
      if (position.x > game.size.x - size.x) position.x = game.size.x - size.x;
    }
    
    // Saldırı tuşu
    if (isKeyDown && _canAttack && !_isAttacking) {
      if (event.logicalKey == LogicalKeyboardKey.space || 
          event.logicalKey == LogicalKeyboardKey.keyK) {
        attack();
      }
    }
    
    return true;
  } catch (e) {
    print('Error in onKeyEvent: $e');
    return false;
  }
}
  
  void attack() {
    try {
      if (!_canAttack || _isAttacking) return;
      
      _canAttack = false;
      _isAttacking = true;
      
      print('Crab attacking!');
      
      // "Let's prove it!" yazısını göster
      game.showTextBubble();
      
      // Etraftaki düşmanlara hasar ver - güvenli bir şekilde
      final enemiesNearby = <Enemy>[];
      
      // Önce yakın düşmanları topla
      for (final component in game.children) {
        if (component is Enemy && _isEnemyInAttackRange(component)) {
          enemiesNearby.add(component);
        }
      }
      
      // Sonra hasar ver (concurrent modification hatası olmaması için)
      for (final enemy in enemiesNearby) {
        enemy.takeDamage(_attackDamage);
      }
      
      // Saldırı cooldown'ı başlat
      Future.delayed(const Duration(milliseconds: 200), () {
        _isAttacking = false;
      });
    } catch (e) {
      print('Error in attack method: $e');
      _isAttacking = false;
      _canAttack = true;
    }
  }
  
  bool _isEnemyInAttackRange(Enemy enemy) {
    try {
      // Yengeç ile düşman arasındaki mesafeyi kontrol et
      final distance = position.distanceTo(enemy.position);
      return distance < size.x * 1.5; // Saldırı menzili
    } catch (e) {
      print('Error checking enemy range: $e');
      return false;
    }
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    try {
      super.onCollision(intersectionPoints, other);
      
      // Düşmanlarla çarpışma kontrolü
      if (other is Enemy && !other.isDestroyed) {
        game.health -= other.damage; // Sağlık azalt
        print('Crab hit by enemy! Health: ${game.health}');
        
        // Düşman yengece çarptığında hasar alabilir (opsiyonel)
        if (_isAttacking) {
          other.takeDamage(_attackDamage);
        }
      }
    } catch (e) {
      print('Error in onCollision: $e');
    }
  }
}