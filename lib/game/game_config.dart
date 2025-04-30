class GameConfig {
  // Oyun ayarları
  static const double enemySpawnInterval = 2.0; // Her 2 saniyede bir düşman spawner
  static const int maxEnemiesOnScreen = 10;  // Ekranda aynı anda max düşman sayısı
  static const int initialHealth = 100;      // Başlangıç sağlık
  static const int maxTraps = 5;             // Aynı anda kurulabilecek max tuzak
  static const double trapCooldown = 1.5;    // Tuzak kurma bekleme süresi
  
  // Zorluk ayarları
  static const double difficultyIncreaseRate = 0.05; // Her seviyede zorluk artışı
  static const int scorePerLevel = 100;             // Her seviye için gerekli skor
  
  // Ses ayarları
  static const double backgroundMusicVolume = 0.5;
  static const double soundEffectsVolume = 0.8;
}