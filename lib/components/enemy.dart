import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import '../game/prove_of_survive_game.dart';
import 'trap.dart';

// Temel düşman sınıfı (soyut sınıf)
abstract class Enemy extends SpriteComponent with HasGameRef<ProveOfSurviveGame>, CollisionCallbacks {
  final ProveOfSurviveGame game;
  final Random _random = Random();
  double _speed = 100.0;
  
  // Bu değişkenleri alt sınıfların değiştirebilmesi için protected yapıyoruz
  int health = 100;
  int damage = 10;
  int scoreValue = 10;
  bool isDestroyed = false; // Düşmanın zaten yok edilip edilmediğini takip etmek için
  
  Enemy({
    required Vector2 position,
    required Vector2 size,
    required this.game,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Çarpışma kutusu ekle
    add(RectangleHitbox()..collisionType = CollisionType.active);
    
    // Rastgele hareket yönü belirle
    _randomizeDirection();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Aşağı doğru hareket
    position.y += _speed * dt;
    
    // Ekranın altından çıkarsa yok et
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
    
    // X yönünde yavaşça hareket et (salınım efekti)
    position.x += sin(game.currentTime() * 2) * dt * 30;
  }
  
  void _randomizeDirection() {
    // Hareket hızını ve yönünü biraz değiştir
    _speed = _speed * (0.8 + _random.nextDouble() * 0.4); // %80-120 arası rastgele hız
  }
  
  void takeDamage(int damage) {
    health -= damage;
    
    // Debug amaçlı konsola yazdırma
    print('Enemy taking damage: $damage, health remaining: $health');
    
    // Zarar alındığında efekt göster
    final hitEffect = ColorEffect(
      const Color.fromARGB(255, 255, 100, 100),
      EffectController(duration: 0.2),
    );
    add(hitEffect);
    
    // Öldü mü kontrolü
    if (health <= 0 && !isDestroyed) {
      die();
    }
  }
  
  void die() {
    if (isDestroyed) return; // Zaten öldüyse işlem yapma
    
    isDestroyed = true;
    
    // Puan ekle
    game.score += scoreValue;
    print('Enemy died! Adding score: $scoreValue, New score: ${game.score}');
    
    // Ölüm animasyonu
    final deathEffect = ScaleEffect.to(
      Vector2.all(0.1),
      EffectController(duration: 0.3),
      onComplete: removeFromParent,
    );
    add(deathEffect);
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    // Tuzak ile çarpışma
    if (other is Trap && !isDestroyed) {
      print('Enemy collided with trap!');
      takeDamage(other.damage);
      // Tuzağa da hasar ver (opsiyonel - tek kullanımlık tuzak istiyorsanız)
      other.takeDamage(1);
    }
  }
}