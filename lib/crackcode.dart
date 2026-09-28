import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class NumberMatchGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'crackcode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Comic Sans MS',
      ),
      home: NumberGamePage(),
    );
  }
}

class NumberGamePage extends StatefulWidget {
  @override
  _NumberGamePageState createState() => _NumberGamePageState();
}

class _NumberGamePageState extends State<NumberGamePage> {
  String _secretNumber = '';
  final List<TextEditingController> _digitControllers =
  List.generate(4, (_) => TextEditingController());
  List<String> _history = [];
  String _feedback = '';
  bool _gameStarted = false;

  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  int? _bestTime;
  String _timeDisplay = "00:00";

  @override
  void initState() {
    super.initState();
    _loadBestTime();
  }

  Future<void> _loadBestTime() async {
    final crackCodeHighScore = await SharedPreferences.getInstance();
    setState(() {
      _bestTime = crackCodeHighScore.getInt('best_time');
    });
  }

  Future<void> _saveBestTime(int time) async {
    final crackCodeHighScore = await SharedPreferences.getInstance();
    await crackCodeHighScore.setInt('best_time', time);
  }

  Future<void> _resetBestTime() async {
    final crackCodeHighScore = await SharedPreferences.getInstance();
    await crackCodeHighScore.remove('best_time');
    setState(() {
      _bestTime = null;
    });
  }

  void _startGame() {
    _generateSecretNumber();
    setState(() {
      _gameStarted = true;
      for (var controller in _digitControllers) {
        controller.clear();
      }
      _history.clear();
      _feedback = '';
      _stopwatch.reset();
      _stopwatch.start();
    });

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _timeDisplay = _formatDuration(_stopwatch.elapsed);
      });
    });
  }

  void _generateSecretNumber() {
    Random random = Random();
    Set<int> digits = {};
    while (digits.length < 4) {
      digits.add(random.nextInt(10));
    }
    _secretNumber = digits.join();
    print("Secret Number: $_secretNumber"); // Debug only
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  void _checkGuess() {
    String guess = _digitControllers.map((c) => c.text).join();

    if (guess.length != 4 || guess.contains(RegExp(r'\D'))) {
      setState(() {
        _feedback = "❌ Enter a valid 4-digit number!";
      });
      return;
    }

    int correctDigits = 0;
    for (int i = 0; i < 4; i++) {
      if (_secretNumber[i] == guess[i]) {
        correctDigits++;
      }
    }

    setState(() {
      _feedback = "$correctDigits digit(s) are correct and in the correct position.";
      _history.add("You guessed $guess → $correctDigits correct");
    });

    if (guess == _secretNumber) {
      _stopwatch.stop();
      _timer?.cancel();

      final totalTime = _stopwatch.elapsedMilliseconds;
      final isNewRecord = _bestTime == null || totalTime < _bestTime!;
      if (isNewRecord) {
        _bestTime = totalTime;
        _saveBestTime(totalTime);
      }

      _showWinDialog(isNewRecord, _formatDuration(Duration(milliseconds: totalTime)));
    }

    for (var controller in _digitControllers) {
      controller.clear();
    }
  }

  void _showWinDialog(bool isNewRecord, String time) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Center(
          child: Column(
            children: [
              Text("🎉 Congratulations!"),
              if (isNewRecord)
                Text("🏆 New Record!", style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("You guessed the number $_secretNumber!"),
            Text("Time: $time"),
            if (_bestTime != null)
              Text("Best: ${_formatDuration(Duration(milliseconds: _bestTime!))}"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
              icon: Icon(Icons.refresh),
              label: Text("Restart Game"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFC107),
                foregroundColor: Color(0xFF512DA8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // for menu bar high score reset
  void _showHighScoreDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("🏅 High Score"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bestTime != null)
              Text("Best Time: ${_formatDuration(Duration(milliseconds: _bestTime!))}"),
            if (_bestTime == null) Text("No high score yet."),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _resetBestTime();
                    Navigator.of(context).pop();
                  },
                  child: Text("Reset"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('🎲 4-Digit Crackcode',style: TextStyle(fontWeight:FontWeight.bold),)),
        backgroundColor: Color(0xFFFFC107),
        foregroundColor: Color(0xFF512DA8),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color:Color(0xFF512DA8)), // colored icon
            tooltip: 'Options',
            color:  Color(0xFFFFC107), // dark theme popup
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == 'new') {
                _startGame();
              } else if (value == 'score') {
                _showHighScoreDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.green),
                    SizedBox(width: 10),
                    Text('New Game', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              PopupMenuDivider(color: Color(0xFF512DA8) ,),
              PopupMenuItem(
                value: 'score',
                child: Row(
                  children: [
                    Icon(Icons.emoji_events,),
                    SizedBox(width: 10),
                    Text('High Score', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _gameStarted ? _buildGameUI() : _buildStartButton(),
      ),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFFC107),
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        ),
        child: Text(
          "Start Game",
          style: TextStyle(fontSize: 20, color: Color(0xFF512DA8)),
        ),
      ),
    );
  }

  Widget _buildGameUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_gameStarted)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "⏱️ $_timeDisplay",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        Center(
          child: Text(
            "🤖 I have picked a 4-digit number.\nTry to guess it!",
            style: TextStyle(fontSize: 18, color: Color(0xFF512DA8)),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 60,
              child: TextField(
                controller: _digitControllers[index],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) {
                  if (val.length == 1 && index < 3) {
                    FocusScope.of(context).nextFocus();
                  }
                },
              ),
            );
          }),
        ),
        SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            onPressed: _checkGuess,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFC107),
              foregroundColor: Color(0xFF512DA8),
            ),
            child: Text("Submit Guess",style: TextStyle(fontSize: 20, color: Color(0xFF512DA8)),),
          ),
        ),
        SizedBox(height: 20),
        Text(
          _feedback,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFC107)),
        ),
        SizedBox(height: 20),
        Center(child: Text("📜 Guess History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF512DA8)))),
        Expanded(
          child: ListView.builder(
            itemCount: _history.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(_history[index]),
              leading: Icon(Icons.history, color: Color(0xFFFFC107)),
            ),
          ),
        ),
      ],
    );
  }
}
