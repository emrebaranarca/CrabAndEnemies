import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import '../game/prove_of_survive_game.dart';
import 'main_menu.dart';
import 'game_over.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late ProveOfSurviveGame _game;
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _keysPressed = <LogicalKeyboardKey>{};
  bool _gameOverHandled = false;

  @override
  void initState() {
    super.initState();
    // Yaşam döngüsü gözlemcisini ekle
    WidgetsBinding.instance.addObserver(this);
    
    _game = ProveOfSurviveGame();
    
    // Game Over callback'i ayarla
    _game.setGameOver((finalScore) {
      print('GameScreen: Game Over callback received with score: $finalScore');
      
      // Eğer daha önce işlenmediyse
      if (!_gameOverHandled) {
        _gameOverHandled = true;
        
        // Hemen navigasyonu dene
        _navigateToGameOver(finalScore);
      }
    });
    
    // Widget oluşturulduktan sonra focus'u isteyecek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  // GameOver ekranına geçiş için ayrı bir metod
  void _navigateToGameOver(int finalScore) {
    print('Attempting to navigate to GameOver with score: $finalScore');
    if (!mounted) {
      print('Widget not mounted, cannot navigate');
      return;
    }
    
    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameOver(finalScore: finalScore),
        ),
      );
      print('Navigation successful');
    } catch (e) {
      print('Navigation error: $e');
      
      // Eğer hemen geçiş yapamazsak, sonraki frame'de tekrar deneyelim
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => GameOver(finalScore: finalScore),
              ),
            );
            print('Delayed navigation successful');
          } catch (e) {
            print('Delayed navigation error: $e');
          }
        }
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama durumu değiştiğinde (ör. arka plana gittiğinde) kontrol et
    print('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar öne geldiğinde ve oyun bitmişse
      if (_game.isGameOver && !_gameOverHandled) {
        _gameOverHandled = true;
        // Game Over ekranına geç
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToGameOver(_game.score);
        });
      }
    }
  }

  @override
  void dispose() {
    // Yaşam döngüsü gözlemcisini kaldır
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          try {
            // Basılı tuşları izle
            if (event is KeyDownEvent) {
              _keysPressed.add(event.logicalKey);
            } else if (event is KeyUpEvent) {
              _keysPressed.remove(event.logicalKey);
            }
            
            // Oyuna klavye olayını ilet
            _game.onKeyEvent(event, Set.from(_keysPressed));
            return KeyEventResult.handled;
          } catch (e) {
            print('Error processing key event: $e');
            return KeyEventResult.ignored;
          }
        },
        child: WillPopScope(
          onWillPop: () async {
            _showPauseDialog();
            return false;
          },
          child: Stack(
            children: [
              // Oyun
GameWidget(
  game: _game,
  // Oyun için overlayler
  overlayBuilderMap: {
    'error': (BuildContext context, ProveOfSurviveGame game) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.red.withOpacity(0.8),
          child: const Text(
            'Oyunda bir hata oluştu! Lütfen oyunu yeniden başlatın.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    },
    'gameOver': (BuildContext context, ProveOfSurviveGame game) {
      // Hemen GameOver ekranına geçmek için bir buton ekleyin
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 200), // GAME OVER metninin altında
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                if (game.isGameOver && !_gameOverHandled) {
                  _gameOverHandled = true;
                  _navigateToGameOver(game.score);
                }
              },
              child: const Text('Game Over! Back to Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  },
),
              
              // Pause butonu
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.pause,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: _showPauseDialog,
                ),
              ),
              
              // Ekranın alt kısmında kontrol talimatları göster
              Positioned(
                top: 70,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Ortala
                  children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '←: Left    →: Right    Space: Attack    Tap: Trap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPauseDialog() {
    try {
      // Oyunu duraklat
      _game.pauseEngine();
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Stopped Game'),
            content: const Text('What do you want?'),
            actions: [
              TextButton(
                onPressed: () {
                  // Devam et
                  Navigator.of(context).pop();
                  _game.resumeEngine();
                  // Dialog kapandıktan sonra tekrar focus iste
                  _focusNode.requestFocus();
                },
                child: const Text('Keep Playing'),
              ),
              TextButton(
                onPressed: () {
                  // Ana menüye dön
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MainMenu(),
                    ),
                  );
                },
                child: const Text('Back to Menu'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing pause dialog: $e');
    }
  }
}