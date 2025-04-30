import 'dart:math';
import 'package:flame/components.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class SharkEnemy extends Enemy {
  final Random _random = Random();
  bool _isCharging = false;
  double _chargeTimer = 0;
  double _chargeCooldown = 3.0; // 3 saniyede bir saldırı
  double _normalSpeed = 60.0;
  double _chargeSpeed = 300.0;
  Vector2 _targetPosition = Vector2.zero();
  
  SharkEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : super(position: position, size: size, game: game) {
    // Köpekbalığı özellikleri: güçlü ve hızlı saldırı
    health = 160;    // Daha fazla can
    damage = 20;     // Çok daha fazla hasar
    scoreValue = 35; // Daha fazla puan
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Köpekbalığı sprite'ını yükle
    sprite = await game.loadSprite('enemies/shark.png');
    
    // Başlangıçta hedefi oyuncuya ayarla
    _updateTargetPosition();
  }
  
  void _updateTargetPosition() {
    // Oyuncunun konumuna doğru hedef belirle
    _targetPosition = game.player.position.clone();
    // Hafif rastgele sapma ekle
    _targetPosition.x += _random.nextDouble() * 100 - 50;
  }
  
  @override
  void update(double dt) {
    // Önce parent sınıfın update metodunu çağırma - kendi hareketimizi yöneteceğiz
    super.update(dt);
    
    if (_isCharging) {
      // Saldırı modunda - hedef konuma doğru hızlıca hareket et
      _moveTowardsTarget(dt, _chargeSpeed);
      
      _chargeTimer += dt;
      if (_chargeTimer >= 1.0) { // 1 saniye saldırı süresi
        _isCharging = false;
        _chargeTimer = 0;
      }
    } else {
      // Normal hareket - aşağı doğru yavaş hareket
      position.y += _normalSpeed * dt;
      
      // Ekranın altından çıkarsa yok et
      if (position.y > game.size.y + size.y) {
        removeFromParent();
        return;
      }
      
      // Şarj saldırısı için zamanlayıcı
      _chargeTimer += dt;
      if (_chargeTimer >= _chargeCooldown) {
        _updateTargetPosition();
        _isCharging = true;
        _chargeTimer = 0;
        // Saldırıya geçerken köpekbalığını oyuncuya çevir
        angle = angleTo(_targetPosition);
      }
    }
    
    // Köpekbalığı salınım efekti (saldırıda değilken)
    if (!_isCharging) {
      angle = sin(game.currentTime() * 1.5) * 0.1; // Hafif sallanma
    }
  }
  
  void _moveTowardsTarget(double dt, double speed) {
    // Hedef yöne doğru hareket
    final direction = _targetPosition - position;
    if (direction.isZero()) return;
    
    direction.normalize();
    position += direction * speed * dt;
  }
  
  double angleTo(Vector2 target) {
    // İki nokta arasındaki açıyı hesapla
    final diff = target - position;
    return atan2(diff.y, diff.x);
  }
  
  @override
  void takeDamage(int damage) {
    super.takeDamage(damage);
    
    // Hasar alınca daha agresif olur - şarj süresini kısalt
    if (health > 0 && _chargeCooldown > 1.0) {
      _chargeCooldown *= 0.9; // Şarj süresini %10 azalt
    }
  }
}