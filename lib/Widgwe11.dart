import 'package:flutter/material.dart';
import 'route_observer.dart';
import 'widget_scores.dart';

class Widgwe11 extends StatefulWidget {
  const Widgwe11({super.key});

  @override
  State<Widgwe11> createState() => _Widgwe11State();
}

class _Widgwe11State extends State<Widgwe11>
    with RouteAware, WidgetsBindingObserver {
  static const Color roxo = Color(0XFF3C00A7);
  late Future<Map<String, int>> scores;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scores = _carregarScores();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _atualizarScores();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _atualizarScores();
    }
  }

  Future<Map<String, int>> _carregarScores() async {
    return WidgetScores.getScores();
  }

  void _atualizarScores() {
    if (!mounted) return;

    setState(() {
      scores = _carregarScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: roxo),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Widget Externo',
          style: TextStyle(color: roxo, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: roxo),
            onPressed: _atualizarScores,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: FutureBuilder<Map<String, int>>(
            future: scores,
            builder: (context, snapshot) {
              final dados =
                  snapshot.data ??
                  const {'quizMyBrain': 0, 'geniusPlay': 0, 'memoCheck': 0};

              return Container(
                width: 340,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: roxo, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Estou com saudades, volte aqui vamos jogar e aprender!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: roxo,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Últimas pontuações:',
                      style: TextStyle(
                        color: roxo,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ScoreCard(
                          score: dados['quizMyBrain'] ?? 0,
                          label: 'QuizzMyBrain',
                        ),
                        _ScoreCard(
                          score: dados['geniusPlay'] ?? 0,
                          label: 'GeniusPlay',
                        ),
                        _ScoreCard(
                          score: dados['memoCheck'] ?? 0,
                          label: 'MemoCheck',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _Widgwe11State.roxo, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                color: _Widgwe11State.roxo,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
