import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class StingrayEnemy extends Enemy {
  final Random _random = Random();
  bool _isDiving = false;
  double _diveTimer = 0;
  double _diveCooldown = 5.0; // 5 saniyede bir dalış
  double _diveSpeed = 300.0;
  double _normalSpeed = 60.0;
  Vector2 _diveTarget = Vector2.zero();
  
  // İz bırakma
  bool _isLeadingTrail = false;
  final List<StingrayTrail> _trails = [];
  double _trailSpawnTimer = 0;
  
  // Saldırı için düşme alanı
  PositionComponent? _targetMarker;
  
  StingrayEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
  }) : super(position: position, size: size, game: game) {
    // Vatoz özellikleri: hızlı dalışlar ve iz bırakır
    health = 130;     // Orta-yüksek düzey can
    damage = 15;      // Yüksek hasar
    scoreValue = 40;  // Yüksek seviye puan
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Vatoz sprite'ını yükle
    sprite = await game.loadSprite('enemies/stingray.png');
  }
  
  @override
  void update(double dt) {
    if (_isDiving) {
      _updateDiving(dt);
    } else {
      super.update(dt);
      
      // Normal hareket - yatay gezinme ve yavaş aşağı iniş
      _updateNormalMovement(dt);
      
      // Dalış zamanlaması
      _diveTimer += dt;
      if (_diveTimer >= _diveCooldown) {
        _prepareDive();
      }
    }
    
    // İz bırakma
    if (_isLeadingTrail) {
      _updateTrail(dt);
    }
  }
  
  void _updateNormalMovement(double dt) {
    // Geniş yatay hareketler
    position.x += sin(game.currentTime()) * 2;
    position.y += _normalSpeed * dt;
    
    // Vatoz yüzme animasyonu - kanat çırpma
    scale = Vector2(
      1.0, 
      1.0 + sin(game.currentTime() * 8) * 0.1
    );
    
    // Ekranın altından çıkarsa yok et
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }
  
  void _prepareDive() {
    _diveTimer = 0;
    
    // Dalış hedefini belirle - genellikle oyuncuya doğru
    double targetX;
    
    // %80 ihtimalle oyuncunun mevcut veya tahmin edilen konumunu hedefle
    if (_random.nextDouble() < 0.8) {
      // Oyuncunun konumunu tahmin et (hareket yönüne göre)
      targetX = game.player.position.x;
      
      // Oyuncunun X konumunu biraz rastgele ayarla
      targetX += (_random.nextDouble() * 100) - 50;
    } else {
      // Rastgele bir yere dalış
      targetX = _random.nextDouble() * game.size.x;
    }
    
    // Ekran sınırlarını aşmayacak şekilde ayarla
    targetX = targetX.clamp(size.x, game.size.x - size.x);
    
    // Hedef genellikle ekranın alt kısmında olacak
    _diveTarget = Vector2(targetX, game.size.y - size.y);
    
    // Dalış hazırlığı göstergesi
    _createTargetMarker();
    
    // Dalış hazırlığı efekti
    add(ScaleEffect.to(
      Vector2(1.2, 0.8), // Yassılaş (dalış için hazırlan)
      EffectController(duration: 0.5),
      onComplete: () {
        _startDive();
      }
    ));
  }
  
  void _createTargetMarker() {
    // Hedef işaretçisi oluştur
    _targetMarker = PositionComponent(
      position: Vector2(_diveTarget.x, _diveTarget.y - 20),
      size: Vector2(30, 30),
    );
    
    // Hedef işaretçisi efekti (uyarı işareti)
    final markerComponent = CircleComponent(
      radius: 15,
      paint: Paint()..color = Colors.red.withOpacity(0.5),
    );
    
    // Yanıp sönme efekti
    markerComponent.add(
      ColorEffect(
        Colors.red,
        EffectController(
          duration: 0.3,
          reverseDuration: 0.3,
          infinite: true,
        ),
        opacityFrom: 0.2,
        opacityTo: 0.8,
      ),
    );
    
    _targetMarker!.add(markerComponent);
    game.add(_targetMarker!);
  }
  
  void _startDive() {
    _isDiving = true;
    _isLeadingTrail = true;
    angle = _calculateDiveAngle();
    
    // Dalış başlangıç efekti
    add(ColorEffect(
      const Color.fromARGB(255, 200, 50, 50),
      EffectController(duration: 0.3),
    ));
    
    // Hızlanma efekti
    add(ScaleEffect.to(
      Vector2(1.0, 1.0), // Normal boyuta dön
      EffectController(duration: 0.2),
    ));
    
    print('Stingray diving to: ${_diveTarget.x}, ${_diveTarget.y}');
  }
  
  double _calculateDiveAngle() {
    // Dalış açısını hedef konuma göre hesapla
    final direction = _diveTarget - position;
    return atan2(direction.y, direction.x);
  }
  
  void _updateDiving(double dt) {
    // Hedef yöne doğru hızlı hareket
    final direction = _diveTarget - position;
    final distance = direction.length;
    
    if (distance > 10) { // Hedefe yeterince yaklaşmadıysa
      direction.normalize();
      position += direction * _diveSpeed * dt;
    } else {
      // Hedefe ulaşıldı, normal harekete dön
      _completeDive();
    }
    
    // İz bırakma güncelleme
    _updateTrail(dt);
  }
  
  void _completeDive() {
    _isDiving = false;
    _isLeadingTrail = false;
    angle = 0;
    
    // Hedef işaretçisini kaldır
    if (_targetMarker != null && _targetMarker!.isMounted) {
      _targetMarker!.removeFromParent();
      _targetMarker = null;
    }
    
    // Dalış sonrası kısa bir sersemleme - OpacityEffect yerine ColorEffect kullan
    add(ColorEffect(
      Colors.white.withOpacity(0.7),
      EffectController(duration: 0.5),
    ));
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (isMounted) {
        add(ColorEffect(
          Colors.white,
          EffectController(duration: 0.5),
        ));
      }
    });
    
    print('Stingray dive completed');
  }
  
  void _updateTrail(double dt) {
    _trailSpawnTimer += dt;
    
    // Her 0.1 saniyede bir iz parçası oluştur
    if (_trailSpawnTimer >= 0.1) {
      _trailSpawnTimer = 0;
      _createTrail();
    }
    
    // Eski izleri temizle
    _trails.removeWhere((trail) => !trail.isMounted);
  }
  
  void _createTrail() {
    final trail = StingrayTrail(
      position: position.clone(),
      size: Vector2(20, 20),
    );
    
    game.add(trail);
    _trails.add(trail);
  }
  
  @override
  void onRemove() {
    // Düşman yok edildiğinde izleri ve hedef işaretçisini de temizle
    for (final trail in _trails) {
      if (trail.isMounted) {
        trail.removeFromParent();
      }
    }
    
    if (_targetMarker != null && _targetMarker!.isMounted) {
      _targetMarker!.removeFromParent();
    }
    
    super.onRemove();
  }
  
  @override
  void takeDamage(int damage) {
    super.takeDamage(damage);
    
    // Hasar aldığında tepki ver - belirli bir can seviyesinin altındaysa dalış başlat
    if (health < 60 && !_isDiving && _random.nextDouble() < 0.7) {
      // Mevcut etkinliği iptal et ve hemen dalışa geç
      _prepareDive();
    }
  }
}

// Vatoz için iz parçası
class StingrayTrail extends PositionComponent {
  late Paint _paint;
  double _lifespan = 0.8; // Saniye cinsinden iz ömrü
  double _timer = 0;
  double _initialOpacity = 0.6;
  
  StingrayTrail({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _paint = Paint()
      ..color = Color.fromARGB((150 * _initialOpacity).toInt(), 100, 200, 255) // Mavi tonlu
      ..style = PaintingStyle.fill;
    
    // Kaybolma efekti - ScaleEffect ile boyutu küçült
    add(ScaleEffect.by(
      Vector2.all(0.5),
      EffectController(duration: _lifespan),
    ));
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Küçük bir daire çiz
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 * (1 - (_timer / _lifespan)), // Zamanla küçülen yarıçap
      _paint,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _timer += dt;
    if (_timer >= _lifespan) {
      removeFromParent();
    }
    
    // Rengi zamanla değiştir
    double currentOpacity = _initialOpacity * (1 - (_timer / _lifespan));
    _paint.color = Color.fromARGB(
      (150 * currentOpacity).toInt(),
      100, 
      200, 
      255
    );
  }
}