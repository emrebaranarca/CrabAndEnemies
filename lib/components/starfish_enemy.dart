import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/prove_of_survive_game.dart';
import 'enemy.dart';

class StarfishEnemy extends Enemy {
  final Random _random = Random();
  bool _isAttached = false;
  bool _isSpinning = false;
  double _spinTimer = 0;
  double _spinCooldown = 3.0; // 3 saniyede bir dönme saldırısı
  double _baseSpeed = 70.0;
  int _baseDamage = 8;
  
  // Bölünme özelliği için
  int _splitCount = 0;
  final int _maxSplits = 2; // En fazla 2 kez bölünebilir
  bool _canSplit = true;
  
  // Zehir bırakma
  double _poisonTimer = 0;
  double _poisonInterval = 2.0; // 2 saniyede bir zehir bırakır
  final List<StarfishPoison> _poisonPuddles = [];
  
  StarfishEnemy({
    required Vector2 position,
    required Vector2 size,
    required ProveOfSurviveGame game,
    int splitLevel = 0,
  }) : super(position: position, size: size, game: game) {
    // Denizyıldızı özellikleri: bölünebilir, yapışkan, zehir bırakır
    _splitCount = splitLevel;
    
    // Bölünme seviyesine göre özellikleri ayarla
    switch (_splitCount) {
      case 0: // Ana denizyıldızı
        health = 150;
        damage = _baseDamage;
        scoreValue = 50;
        break;
      case 1: // İlk bölünme
        health = 80;
        damage = (_baseDamage * 0.7).toInt();
        scoreValue = 25;
        scale = Vector2.all(0.8); // %80 boyut
        break;
      case 2: // İkinci bölünme
        health = 40;
        damage = (_baseDamage * 0.5).toInt();
        scoreValue = 15;
        scale = Vector2.all(0.6); // %60 boyut
        _canSplit = false; // Daha fazla bölünemez
        break;
    }
  }
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Denizyıldızı sprite'ını yükle
    sprite = await game.loadSprite('enemies/starfish.png');
    
    // Rastgele bir renk tonu ekle (farklı denizyıldızları için)
    Color tintColor;
    if (_splitCount == 0) {
      tintColor = const Color.fromARGB(100, 255, 100, 100); // Kırmızımsı
    } else if (_splitCount == 1) {
      tintColor = const Color.fromARGB(100, 255, 200, 100); // Turuncumsu
    } else {
      tintColor = const Color.fromARGB(100, 255, 255, 100); // Sarımsı
    }
    
    add(ColorEffect(
      tintColor,
      EffectController(duration: 0.3),
    ));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_isAttached) {
      _updateAttachedBehavior(dt);
    } else {
      _updateFloatingBehavior(dt);
    }
    
    // Zehir bırakma zamanlayıcısı
    _poisonTimer += dt;
    if (_poisonTimer >= _poisonInterval) {
      _dropPoison();
      _poisonTimer = 0;
    }
    
    // Eskimiş zehir birikintilerini temizle
    _poisonPuddles.removeWhere((poison) => !poison.isMounted);
  }
  
  void _updateFloatingBehavior(double dt) {
    // Aşağı doğru yavaş hareket
    position.y += _baseSpeed * dt;
    
    // Yüzen denizyıldızı hareketi - hafif dönme ve yatay salınım
    angle += dt * 0.2; // Sürekli yavaş dönüş
    position.x += sin(game.currentTime() * 1.5) * dt * 20;
    
    // Ekranın altından çıkarsa yok et
    if (position.y > game.size.y + size.y) {
      removeFromParent();
      return;
    }
    
    // Oyuncuya yakınsa yapışmaya çalış
    double distanceToPlayer = position.distanceTo(game.player.position);
    if (distanceToPlayer < 100 && _random.nextDouble() < 0.005) { // Her frame %0.5 ihtimalle
      _tryToAttach();
    }
  }
  
  void _tryToAttach() {
    // Oyuncuya yapışma denemesi
    final direction = game.player.position - position;
    if (direction.length < 100) {
      _isAttached = true;
      _isSpinning = false;
      
      // Yapışma efekti
      add(ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(duration: 0.3, curve: Curves.bounceOut),
      ));
      
      print('Starfish attached to player!');
    }
  }
  
  void _updateAttachedBehavior(double dt) {
    // Oyuncuya yapışık - konumu güncelle
    position = game.player.position.clone() + Vector2(0, -20);
    
    // Dönme saldırısı için zamanlama
    _spinTimer += dt;
    if (_spinTimer >= _spinCooldown && !_isSpinning) {
      _startSpinAttack();
    }
    
    if (_isSpinning) {
      // Dönme saldırısı sırasında hızlı döndür
      angle += dt * 10;
      
      // Dönme sırasında oyuncuya sürekli hasar ver
      if (_spinTimer % 0.5 < dt) { // Her 0.5 saniyede bir
        game.health -= damage;
        game.showTextBubble(); // Düşmana vurulduğunda metin göster
        print('Starfish dealing damage: $damage. Player health: ${game.health}');
      }
      
      // Dönme süresi bitince normal duruma dön
      if (_spinTimer >= _spinCooldown + 2.0) { // 2 saniye dönme
        _isSpinning = false;
        _spinTimer = 0;
      }
    }
    
    // Oyuncudan uzaklaşırsa kopmasını sağla
    double distanceToPlayer = position.distanceTo(game.player.position);
    if (distanceToPlayer > 100) {
      _detach();
    }
  }
  
  void _startSpinAttack() {
    _isSpinning = true;
    _spinTimer = 0;
    
    // Dönme başlangıç efekti
    add(ColorEffect(
      const Color.fromARGB(200, 255, 50, 50),
      EffectController(duration: 0.3),
    ));
    
    print('Starfish spin attack!');
  }
  
  void _detach() {
    _isAttached = false;
    _isSpinning = false;
    
    // Kopma efekti
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.3),
    ));
    
    // Kısa sersemlik - ColorEffect kullan
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
    
    print('Starfish detached');
  }
  
  void _dropPoison() {
    if (!isMounted) return;
    
    // Zehir birikintisi bırak
    final poison = StarfishPoison(
      position: position.clone(),
      size: Vector2(30, 30),
      damage: (damage * 0.5).toInt(),
      game: game,
    );
    
    game.add(poison);
    _poisonPuddles.add(poison);
    
    print('Starfish dropped poison');
  }
  
  void _split() {
    if (!_canSplit || _splitCount >= _maxSplits || health > 0) return;
    
    print('Starfish splitting! Level: ${_splitCount + 1}');
    
    // İki küçük denizyıldızına bölün
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(
        _random.nextDouble() * 60 - 30,
        _random.nextDouble() * 60 - 30,
      );
      
      final childStarfish = StarfishEnemy(
        position: position + offset,
        size: size * 0.8, // %80 boyut
        game: game,
        splitLevel: _splitCount + 1,
      );
      
      game.add(childStarfish);
    }
  }
  
  @override
  void takeDamage(int damage) {
    super.takeDamage(damage);
    
    // Hasar alınca yapışık ise kopma olasılığı
    if (_isAttached && _random.nextDouble() < 0.3) { // %30 ihtimalle
      _detach();
    }
    
    // Öldüğünde bölünme özelliği
    if (health <= 0 && _canSplit) {
      _split();
    }
  }
  
  @override
  void onRemove() {
    // Düşman yok edildiğinde zehir birikintilerini temizle
    for (final poison in _poisonPuddles) {
      if (poison.isMounted) {
        poison.removeFromParent();
      }
    }
    
    super.onRemove();
  }
}

// Denizyıldızı zehir birikintisi
class StarfishPoison extends PositionComponent with HasGameRef<ProveOfSurviveGame> {
  final ProveOfSurviveGame game;
  final int damage;
  late Paint _paint;
  double _lifespan = 6.0; // 6 saniye sürer
  double _timer = 0;
  double _damageInterval = 1.0; // Saniyede bir hasar
  double _damageCooldown = 0;
  double _initialScale = 1.0;
  double _initialAlpha = 150.0;
  
  StarfishPoison({
    required Vector2 position,
    required Vector2 size,
    required this.damage,
    required this.game,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _paint = Paint()
      ..color = Color.fromARGB(_initialAlpha.toInt(), 255, 100, 200)
      ..style = PaintingStyle.fill;
    
    // Yavaşça genişleme efekti
    add(ScaleEffect.to(
      Vector2.all(1.5),
      EffectController(duration: 2.0),
    ));
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Zehir birikintisi çiz - hafif titreyen bir daire
    double wobble = sin(game.currentTime() * 5) * 3;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + wobble,
      _paint,
    );
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _timer += dt;
    if (_timer >= _lifespan) {
      removeFromParent();
      return;
    }
    
    // Son 1 saniyede kaybolma efekti
    if (_timer >= _lifespan - 1.0) {
      double disappearFactor = (_lifespan - _timer);
      scale = Vector2.all(_initialScale * disappearFactor);
    }
    
    // Renk efektini zamanla değiştir - daha şeffaf hale getir
    _paint.color = Color.fromARGB(
      (_initialAlpha * (1 - _timer / _lifespan)).toInt(),
      255,
      100,
      200,
    );
    
    // Oyuncuya hasar verme kontrolü
    _damageCooldown += dt;
    if (_damageCooldown >= _damageInterval) {
      _checkPlayerDamage();
      _damageCooldown = 0;
    }
  }
  
  void _checkPlayerDamage() {
    // Oyuncu zehir birikintisine yakınsa hasar ver
    final distanceToPlayer = position.distanceTo(game.player.position);
    if (distanceToPlayer < size.x / 2 + 20) {
      game.health -= damage;
      print('Poison damaging player! Damage: $damage, Player health: ${game.health}');
      
      // Zehirlenme efekti
      _showPoisonEffect();
    }
  }
  
  void _showPoisonEffect() {
    // Oyuncuya zehirlenme efekti ekleme (opsiyonel)
    // Burada game.player'a geçici bir renk efekti eklenebilir
  }
}