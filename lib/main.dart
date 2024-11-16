import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Achievement {
  final String id;
  final String name;
  final String description;
  final double requirement;
  final double reward;
  bool isCompleted;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.requirement,
    required this.reward,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'isCompleted': isCompleted,
  };

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      name: template.name,
      description: template.description,
      requirement: template.requirement,
      reward: template.reward,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: GameScreen(),
  ));
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Idle Game'),
        backgroundColor: Colors.blue,
      ),
      body: GameWidget.controlled(
        gameFactory: () => IdleGame(),
        overlayBuilderMap: {
          'gameOverlay': (context, game) => IdleGameWidget(game: game as IdleGame),
        },
        initialActiveOverlays: const ['gameOverlay'],
      ),
    );
  }
}

class IdleGame extends FlameGame {
  double currency = 0;
  double autoIncome = 1;
  int clickMultiplier = 1;
  
  // Base upgrades
  double autoIncomeUpgradeCost = 10;
  double clickMultiplierUpgradeCost = 15;
  
  // New upgrade types
  double autoIncomeMultiplier = 1;
  double clickPowerMultiplier = 1;
  int prestigeLevel = 0;
  
  // New upgrade costs
  double autoMultiplierCost = 100;
  double clickMultiplierCost = 150;
  double prestigeCost = 1000;

  // Achievement tracking
  int totalClicks = 0;
  double totalCurrencyEarned = 0;
  List<Achievement> achievements = [];
  double achievementBonus = 1.0;

  IdleGame() {
    _initializeAchievements();
  }

  void _initializeAchievements() {
    achievements = [
      Achievement(
        id: 'clicks_10',
        name: 'Beginner Clicker',
        description: 'Click 10 times',
        requirement: 10,
        reward: 1.1, // 10% bonus
      ),
      Achievement(
        id: 'clicks_100',
        name: 'Dedicated Clicker',
        description: 'Click 100 times',
        requirement: 100,
        reward: 1.2, // 20% bonus
      ),
      Achievement(
        id: 'currency_1000',
        name: 'Small Fortune',
        description: 'Earn 1,000 currency total',
        requirement: 1000,
        reward: 1.3, // 30% bonus
      ),
      Achievement(
        id: 'currency_1000000',
        name: 'Millionaire',
        description: 'Earn 1,000,000 currency total',
        requirement: 1000000,
        reward: 1.5, // 50% bonus
      ),
      Achievement(
        id: 'prestige_1',
        name: 'New Beginning',
        description: 'Prestige for the first time',
        requirement: 1,
        reward: 1.25, // 25% bonus
      ),
    ];
  }

  @override
  Future<void> onLoad() async {
    final prefs = await SharedPreferences.getInstance();
    currency = prefs.getDouble('currency') ?? 0;
    autoIncome = prefs.getDouble('autoIncome') ?? 1;
    clickMultiplier = prefs.getInt('clickMultiplier') ?? 1;
    autoIncomeUpgradeCost = prefs.getDouble('autoIncomeUpgradeCost') ?? 10;
    clickMultiplierUpgradeCost = prefs.getDouble('clickMultiplierUpgradeCost') ?? 15;
    
    autoIncomeMultiplier = prefs.getDouble('autoIncomeMultiplier') ?? 1;
    clickPowerMultiplier = prefs.getDouble('clickPowerMultiplier') ?? 1;
    prestigeLevel = prefs.getInt('prestigeLevel') ?? 0;
    autoMultiplierCost = prefs.getDouble('autoMultiplierCost') ?? 100;
    clickMultiplierCost = prefs.getDouble('clickMultiplierCost') ?? 150;
    prestigeCost = prefs.getDouble('prestigeCost') ?? 1000;

    // Load achievement progress
    totalClicks = prefs.getInt('totalClicks') ?? 0;
    totalCurrencyEarned = prefs.getDouble('totalCurrencyEarned') ?? 0;
    achievementBonus = prefs.getDouble('achievementBonus') ?? 1.0;

    // Load achievement completion status
    final achievementData = prefs.getString('achievements') ?? '{}';
    final achievementMap = Map<String, dynamic>.from(
      Map.from(Uri.splitQueryString(achievementData))
        .map((key, value) => MapEntry(key, value == 'true')),
    );
    
    for (var achievement in achievements) {
      achievement.isCompleted = achievementMap[achievement.id] ?? false;
    }
  }

  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('currency', currency);
    await prefs.setDouble('autoIncome', autoIncome);
    await prefs.setInt('clickMultiplier', clickMultiplier);
    await prefs.setDouble('autoIncomeUpgradeCost', autoIncomeUpgradeCost);
    await prefs.setDouble('clickMultiplierUpgradeCost', clickMultiplierUpgradeCost);
    
    await prefs.setDouble('autoIncomeMultiplier', autoIncomeMultiplier);
    await prefs.setDouble('clickPowerMultiplier', clickPowerMultiplier);
    await prefs.setInt('prestigeLevel', prestigeLevel);
    await prefs.setDouble('autoMultiplierCost', autoMultiplierCost);
    await prefs.setDouble('clickMultiplierCost', clickMultiplierCost);
    await prefs.setDouble('prestigeCost', prestigeCost);

    // Save achievement progress
    await prefs.setInt('totalClicks', totalClicks);
    await prefs.setDouble('totalCurrencyEarned', totalCurrencyEarned);
    await prefs.setDouble('achievementBonus', achievementBonus);

    // Save achievement completion status
    final achievementMap = {
      for (var achievement in achievements)
        achievement.id: achievement.isCompleted.toString()
    };
    await prefs.setString('achievements', Uri(queryParameters: achievementMap).query);
  }

  void checkAchievements() {
    bool anyNewAchievements = false;
    achievementBonus = 1.0;

    for (var achievement in achievements) {
      if (!achievement.isCompleted) {
        bool isCompleted = false;
        switch (achievement.id) {
          case 'clicks_10':
          case 'clicks_100':
            isCompleted = totalClicks >= achievement.requirement;
            break;
          case 'currency_1000':
          case 'currency_1000000':
            isCompleted = totalCurrencyEarned >= achievement.requirement;
            break;
          case 'prestige_1':
            isCompleted = prestigeLevel >= achievement.requirement;
            break;
        }
        if (isCompleted) {
          achievement.isCompleted = true;
          anyNewAchievements = true;
        }
      }
      if (achievement.isCompleted) {
        achievementBonus *= achievement.reward;
      }
    }

    if (anyNewAchievements) {
      saveGame();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final double income = (autoIncome * autoIncomeMultiplier * (1 + prestigeLevel * 0.1) * achievementBonus) * dt;
    currency += income;
    totalCurrencyEarned += income;
    checkAchievements();
    if ((currency % 5) < dt) {
      saveGame();
    }
  }

  void onTap() {
    final double clickValue = clickMultiplier * clickPowerMultiplier * (1 + prestigeLevel * 0.1) * achievementBonus;
    currency += clickValue;
    totalCurrencyEarned += clickValue;
    totalClicks++;
    checkAchievements();
  }

  void upgradeAutoIncome() {
    if (currency >= autoIncomeUpgradeCost) {
      currency -= autoIncomeUpgradeCost;
      autoIncome += 1;
      autoIncomeUpgradeCost *= 1.5;
      saveGame();
    }
  }

  void upgradeClickMultiplier() {
    if (currency >= clickMultiplierUpgradeCost) {
      currency -= clickMultiplierUpgradeCost;
      clickMultiplier += 1;
      clickMultiplierUpgradeCost *= 1.5;
      saveGame();
    }
  }

  void upgradeAutoIncomeMultiplier() {
    if (currency >= autoMultiplierCost) {
      currency -= autoMultiplierCost;
      autoIncomeMultiplier *= 1.5;
      autoMultiplierCost *= 2;
      saveGame();
    }
  }

  void upgradeClickPowerMultiplier() {
    if (currency >= clickMultiplierCost) {
      currency -= clickMultiplierCost;
      clickPowerMultiplier *= 1.5;
      clickMultiplierCost *= 2;
      saveGame();
    }
  }

  void prestige() {
    if (currency >= prestigeCost) {
      // Reset everything except prestige level
      currency = 0;
      autoIncome = 1;
      clickMultiplier = 1;
      autoIncomeUpgradeCost = 10;
      clickMultiplierUpgradeCost = 15;
      autoIncomeMultiplier = 1;
      clickPowerMultiplier = 1;
      autoMultiplierCost = 100;
      clickMultiplierCost = 150;
      
      // Increase prestige level and cost
      prestigeLevel += 1;
      prestigeCost *= 5;
      saveGame();
    }
  }
}

class IdleGameWidget extends StatefulWidget {
  final IdleGame game;

  const IdleGameWidget({super.key, required this.game});

  @override
  State<IdleGameWidget> createState() => _IdleGameWidgetState();
}

class _IdleGameWidgetState extends State<IdleGameWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String formatNumber(double number) {
    if (number < 1000) return number.toStringAsFixed(1);
    if (number < 1000000) return '${(number/1000).toStringAsFixed(1)}K';
    if (number < 1000000000) return '${(number/1000000).toStringAsFixed(1)}M';
    if (number < 1000000000000) return '${(number/1000000000).toStringAsFixed(1)}B';
    return '${(number/1000000000000).toStringAsFixed(1)}T';
  }

  void _handleTap() {
    setState(() {
      widget.game.onTap();
    });
  }

  void _handleAutoIncomeUpgrade() {
    setState(() {
      widget.game.upgradeAutoIncome();
    });
  }

  void _handleClickMultiplierUpgrade() {
    setState(() {
      widget.game.upgradeClickMultiplier();
    });
  }

  void _handleAutoIncomeMultiplierUpgrade() {
    setState(() {
      widget.game.upgradeAutoIncomeMultiplier();
    });
  }

  void _handleClickPowerMultiplierUpgrade() {
    setState(() {
      widget.game.upgradeClickPowerMultiplier();
    });
  }

  void _handlePrestige() {
    setState(() {
      widget.game.prestige();
    });
  }

  void _showAchievements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Achievements'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.game.achievements.map((achievement) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: achievement.isCompleted ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: achievement.isCompleted ? Colors.green : Colors.grey,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          achievement.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: achievement.isCompleted ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          achievement.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: achievement.isCompleted ? Colors.green.shade900 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(achievement.description),
                    Text(
                      'Reward: +${((achievement.reward - 1) * 100).toStringAsFixed(0)}% to all income',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Currency: ${formatNumber(widget.game.currency)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Auto Income: ${formatNumber(widget.game.autoIncome * widget.game.autoIncomeMultiplier * (1 + widget.game.prestigeLevel * 0.1) * widget.game.achievementBonus)}/sec',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click Power: ${formatNumber(widget.game.clickMultiplier * widget.game.clickPowerMultiplier * (1 + widget.game.prestigeLevel * 0.1) * widget.game.achievementBonus)}',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        if (widget.game.prestigeLevel > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Prestige Level: ${widget.game.prestigeLevel} (+${widget.game.prestigeLevel * 10}%)',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.purple.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (widget.game.achievementBonus > 1) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Achievement Bonus: +${((widget.game.achievementBonus - 1) * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Clicks: ${widget.game.totalClicks}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAchievements,
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('Achievements'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _handleAutoIncomeUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Upgrade Auto Income\nCost: ${formatNumber(widget.game.autoIncomeUpgradeCost)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleClickMultiplierUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Upgrade Click Power\nCost: ${formatNumber(widget.game.clickMultiplierUpgradeCost)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _handleAutoIncomeMultiplierUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Auto Income ×1.5\nCost: ${formatNumber(widget.game.autoMultiplierCost)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleClickPowerMultiplierUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Click Power ×1.5\nCost: ${formatNumber(widget.game.clickMultiplierCost)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (widget.game.currency >= widget.game.prestigeCost / 2) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _handlePrestige,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Prestige (Reset + ${(widget.game.prestigeLevel + 1) * 10}% Bonus)\nCost: ${formatNumber(widget.game.prestigeCost)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(20),
                    minimumSize: const Size(200, 60),
                  ),
                  child: const Text(
                    'Click to Earn!',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
