import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/crab.dart';
import '../components/enemy.dart';
import '../components/fish_enemy.dart';
import '../components/octopus_enemy.dart';
import '../components/text_bubble.dart';
import '../components/trap.dart';
import 'game_config.dart';
import '../components/shark_enemy.dart';
import '../components/crab_enemy.dart';
import '../components/jellyfish_enemy.dart';
import '../components/seahorse_enemy.dart';
import '../components/pufferfish_enemy.dart';
import '../components/stingray_enemy.dart';
import '../components/starfish_enemy.dart';

class ProveOfSurviveGame extends FlameGame with TapDetector, HasCollisionDetection, KeyboardEvents {
  late Crab player;
  final Random _random = Random();
  double _enemySpawnTimer = 0;
  int score = 0;
  int health = GameConfig.initialHealth;
  int trapsPlaced = 0;
  double _trapCooldown = 0;
  bool canPlaceTrap = true;
  late RectangleComponent scoreBox;
  late RectangleComponent healthBox;
  late RectangleComponent trapBox;
  late TextComponent scoreText;
  late TextComponent healthText;
  late TextComponent trapText;
  bool _isGameInitialized = false;
  bool _isGameOver = false; // Oyun bitimi takip etmek için
  Function(int)? onGameOver; // Game Over callback'i
  
  // Game Over durumunu dışarıdan okumak için getter
  bool get isGameOver => _isGameOver;
  
  // Game Over durumunu ayarla
  void setGameOver(Function(int) callback) {
    onGameOver = callback;
    print('Game Over callback set');
  }
  
  @override
  Future<void> onLoad() async {
    try {
      await super.onLoad();
      
      print('Game loading...');
      
      // Arka plan resmini yükle
      final background = SpriteComponent(
        sprite: await loadSprite('background/game_bg.png'),
        size: size,
      );
      add(background);
      
      // Oyuncuyu (yengeç) ekle
      player = Crab(
        position: Vector2(size.x / 2, size.y - 100),
        size: Vector2(120, 120),
        game: this,
      );
      add(player);
      
      // Gösterge kutuları için stiller
      const textColor = Colors.white;
      const fontSize = 20.0;
      const boxHeight = 36.0;
      final boxWidth = size.x * 0.15;  // Ekranın genişliğine göre
      const boxRadius = 12.0;
      const boxMargin = 10.0;
      
      // HUD (Heads-Up Display) için ortalanmış pozisyon ayarla
      final hudY = 30.0;
      final scorePosX = size.x * 0.25 - boxWidth / 2;
      final healthPosX = size.x * 0.5 - boxWidth / 2;
      final trapPosX = size.x * 0.75 - boxWidth / 2;
      
      // Skor için kutu ve metin ekle
      scoreBox = RectangleComponent(
        position: Vector2(scorePosX, hudY),
        size: Vector2(boxWidth, boxHeight),
        paint: Paint()..color = Colors.blue.withOpacity(0.7),
        children: [
          RectangleComponent(
            size: Vector2(boxWidth, boxHeight),
            paint: Paint()..color = Colors.transparent,
            position: Vector2.zero(),
            children: [],
          )
        ],
      );
      (scoreBox.children.first as RectangleComponent).paint.shader = RadialGradient(
        colors: [Colors.blue.shade700, Colors.blue.shade500],
        center: Alignment.center,
        radius: 1.0,
      ).createShader(Rect.fromLTWH(0, 0, boxWidth, boxHeight));
      scoreBox.paint.shader = RadialGradient(
        colors: [Colors.blue.shade700, Colors.blue.shade500],
        center: Alignment.center,
        radius: 1.0,
      ).createShader(Rect.fromLTWH(0, 0, boxWidth, boxHeight));
      scoreBox.paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      
      add(scoreBox);
      
      scoreText = TextComponent(
        text: 'Score: 0',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(scorePosX + boxWidth / 2, hudY + boxHeight / 2),
        anchor: Anchor.center,
      );
      add(scoreText);
      
      // Sağlık için kutu ve metin ekle
      healthBox = RectangleComponent(
        position: Vector2(healthPosX, hudY),
        size: Vector2(boxWidth, boxHeight),
        paint: Paint()..color = Colors.red.withOpacity(0.7),
      );
      healthBox.paint.shader = RadialGradient(
        colors: [Colors.red.shade700, Colors.red.shade500],
        center: Alignment.center,
        radius: 1.0,
      ).createShader(Rect.fromLTWH(0, 0, boxWidth, boxHeight));
      healthBox.paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      add(healthBox);
      
      healthText = TextComponent(
        text: 'Health: $health',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(healthPosX + boxWidth / 2, hudY + boxHeight / 2),
        anchor: Anchor.center,
      );
      add(healthText);
      
      // Tuzak durumu için kutu ve metin ekle
      trapBox = RectangleComponent(
        position: Vector2(trapPosX, hudY),
        size: Vector2(boxWidth, boxHeight),
        paint: Paint()..color = Colors.green.withOpacity(0.7),
      );
      trapBox.paint.shader = RadialGradient(
        colors: [Colors.green.shade700, Colors.green.shade500],
        center: Alignment.center,
        radius: 1.0,
      ).createShader(Rect.fromLTWH(0, 0, boxWidth, boxHeight));
      trapBox.paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
      add(trapBox);
      
      trapText = TextComponent(
        text: 'Traps: 0/${GameConfig.maxTraps}',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(trapPosX + boxWidth / 2, hudY + boxHeight / 2),
        anchor: Anchor.center,
      );
      add(trapText);
      
      _isGameInitialized = true;
      _isGameOver = false;
      print('Game initialized successfully!');
    } catch (e) {
      print('Error during game initialization: $e');
      rethrow;
    }
  }
  
  @override
  void update(double dt) {
    try {
      if (!_isGameInitialized) return;
      
      // Oyun bittiyse güncelleme yapmadan çık
      if (_isGameOver) return;
      
      super.update(dt);
      
      // Düşman spawn zamanlaması
      _enemySpawnTimer += dt;
      if (_enemySpawnTimer >= GameConfig.enemySpawnInterval) {
        _spawnEnemy();
        _enemySpawnTimer = 0;
      }
      
      // Tuzak bekleme süresini güncelle
      if (!canPlaceTrap) {
        _trapCooldown -= dt;
        if (_trapCooldown <= 0) {
          canPlaceTrap = true;
        }
      }
      
      // Skor ve sağlık güncelleme
      scoreText.text = 'Score: $score';
      healthText.text = 'Health: $health';
      
      // Tuzak durumunu güncelle
      trapText.text = 'Traps: $trapsPlaced/${GameConfig.maxTraps}';
      
      // Tuzak sayısını güncelle - aktif tuzakları say
      int activeTrapCount = 0;
      for (final component in children) {
        if (component is Trap && component.isActive) {
          activeTrapCount++;
        }
      }
      trapsPlaced = activeTrapCount;
      
      // Sağlık durumuna göre renklendirme
      if (health < GameConfig.initialHealth * 0.3) {
        // Sağlık düşükse kutuyu daha parlak kırmızı yap
        healthBox.paint.shader = RadialGradient(
          colors: [Colors.red.shade900, Colors.red.shade700],
          center: Alignment.center,
          radius: 1.0,
        ).createShader(Rect.fromLTWH(0, 0, healthBox.size.x, healthBox.size.y));
      }
      
      // Oyun bitimi kontrolü
      if (health <= 0 && !_isGameOver) {
        print('Health is zero, calling _gameOver()');
        _gameOver();
      }
    } catch (e) {
      print('Error in game update: $e');
    }
  }
  
  // Basitleştirilmiş ve güvenilir oyun bitimi işlemi
  void _gameOver() {
    // Eğer zaten oyun bittiyse tekrar çalışma
    if (_isGameOver) return;
    
    _isGameOver = true;
    print('Game over! Final score: $score');
    
    // Oyun motorunu duraklat
    pauseEngine();
    
    // GAME OVER yazısını ekle
    try {
      final gameOverText = TextComponent(
        text: 'GAME OVER',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.red,
            fontSize: 72,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(5.0, 5.0),
              ),
            ],
          ),
        ),
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
      );
      add(gameOverText);
      print('Added GAME OVER text to the screen');
    } catch (e) {
      print('Error adding game over text: $e');
    }
    
    // Tüm düşmanları yok et
    try {
      children.whereType<Enemy>().forEach((enemy) {
        enemy.die();
      });
      print('Removed all enemies');
    } catch (e) {
      print('Error removing enemies: $e');
    }
    
    // Ekstra görünürlük - oyun devam etmeyecek
    overlays.add('gameOver');
    
    // Game Over ekranını göstermeden önce kısa bir gecikme ekle
    Future.delayed(const Duration(milliseconds: 2000), () {
      // Game Over callback'i çağır
      if (onGameOver != null) {
        print('Calling onGameOver callback with score: $score');
        onGameOver!(score);
      } else {
        print('onGameOver callback is null!');
      }
    });
  }

  void _spawnEnemy() {
    try {
      final enemyX = _random.nextDouble() * size.x;
      final enemyY = -50.0; // Ekranın üstünden spawn
      final enemySize = Vector2(96, 96);
      
      Enemy enemy;
      // Rastgele düşman tipi seç (0-8 arası)
      int enemyType = _random.nextInt(9);
      
      switch (enemyType) {
        case 0:
          enemy = FishEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 1:
          enemy = OctopusEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 2:
          enemy = SharkEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 3:
          enemy = CrabEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 4:
          enemy = JellyfishEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 5:
          enemy = SeahorseEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 6:
          enemy = PufferfishEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 7:
          enemy = StingrayEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        case 8:
          enemy = StarfishEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
        default:
          // Varsayılan olarak balık düşmanı oluştur
          enemy = FishEnemy(
            position: Vector2(enemyX, enemyY),
            size: enemySize,
            game: this,
          );
          break;
      }
      
      add(enemy);
      print('Enemy spawned: ${enemy.runtimeType}');
    } catch (e) {
      print('Error spawning enemy: $e');
    }
  }
    
  // "Let's prove it!" metin balonu gösterme
  void showTextBubble() {
    try {
      add(
        TextBubble(
          text: "Let's prove it!",
          position: Vector2(player.position.x, player.position.y - 50),
          lifespan: 1.5, // 1.5 saniye ekranda kalacak
        )
      );
      print('Text bubble shown');
    } catch (e) {
      print('Error showing text bubble: $e');
    }
  }
  
  // Ağ/tuzak yerleştirme
  void placeTrap(Vector2 position) {
    try {
      // Eğer tuzak yerleştirilmesi mümkünse
      if (canPlaceTrap && trapsPlaced < GameConfig.maxTraps) {
        canPlaceTrap = false;
        _trapCooldown = GameConfig.trapCooldown;
        
        final trap = Trap(
          position: position,
          size: Vector2(40, 40),
          game: this,
        );
        add(trap);
        trapsPlaced++;
        print('Trap placed! Count: $trapsPlaced');
      } else {
        print('Cannot place trap! Cooldown or max traps reached.');
      }
    } catch (e) {
      print('Error placing trap: $e');
    }
  }
  
  @override
  void onTapDown(TapDownInfo info) {
    try {
      // Oyun bittiyse dokunmaları işleme
      if (_isGameOver) return;
      
      final touchPosition = Vector2(
        info.eventPosition.widget.x,
        info.eventPosition.widget.y,
      );
      placeTrap(touchPosition);
    } catch (e) {
      print('Error in tap handler: $e');
    }
  }
  
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    try {
      // Oyun bittiyse tuşları işleme
      if (_isGameOver) return KeyEventResult.ignored;
      
      if (player.onKeyEvent(event, keysPressed)) {
        return KeyEventResult.handled;
      }
      
      // Escape tuşu ile oyunu duraklat
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
        pauseEngine();
        // Burada oyunu durduran mantık olabilir
        return KeyEventResult.handled;
      }
      
      return KeyEventResult.ignored;
    } catch (e) {
      print('Error in game key handler: $e');
      return KeyEventResult.ignored;
    }
  }
}