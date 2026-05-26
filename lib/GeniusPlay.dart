import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GeniusColor { yellow, blue, red, orange, green }

class Geniusplay extends StatefulWidget {
  const Geniusplay({super.key});

  @override
  State<Geniusplay> createState() => _GeniusplayState();
}

class _GeniusplayState extends State<Geniusplay> {
  static const Color roxo = Color(0XFF3C00A7);

  final math.Random _random = math.Random();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();

  String idioma = 'pt';
  int nivel = 1;
  int score = 0;
  int acertosNoNivel = 0;
  int segundos = 0;
  bool jogando = false;
  bool falandoCores = false;
  bool aguardandoResposta = false;
  GeniusColor? corAcesa;
  Timer? _cronometro;
  Timer? _luzTimer;
  int _partidaAtual = 0;

  List<GeniusColor> sequencia = [];
  int posicaoResposta = 0;

  final Map<String, Map<String, String>> textos = {
    'pt': {
      'idioma': 'Português',
      'titulo': 'Genius Play',
      'nivel': 'Nível',
      'cronometro': 'Cronômetro',
      'start': 'Start',
      'stop': 'Stop',
      'score': 'Score',
      'restart': 'Restart',
      'fim': 'Fim de jogo',
      'pontuacaoFinal': 'Score final',
      'tempoFinal': 'Tempo',
      'ok': 'OK',
    },
    'en': {
      'idioma': 'English',
      'titulo': 'Genius Play',
      'nivel': 'Level',
      'cronometro': 'Timer',
      'start': 'Start',
      'stop': 'Stop',
      'score': 'Score',
      'restart': 'Restart',
      'fim': 'Game over',
      'pontuacaoFinal': 'Final score',
      'tempoFinal': 'Time',
      'ok': 'OK',
    },
    'es': {
      'idioma': 'Español',
      'titulo': 'Genius Play',
      'nivel': 'Nivel',
      'cronometro': 'Cronómetro',
      'start': 'Iniciar',
      'stop': 'Parar',
      'score': 'Puntos',
      'restart': 'Reiniciar',
      'fim': 'Fin del juego',
      'pontuacaoFinal': 'Puntos finales',
      'tempoFinal': 'Tiempo',
      'ok': 'OK',
    },
  };

  final Map<GeniusColor, String> nomesArquivos = {
    GeniusColor.yellow: 'yellow',
    GeniusColor.blue: 'blue',
    GeniusColor.red: 'red',
    GeniusColor.orange: 'orange',
    GeniusColor.green: 'green',
  };

  @override
  void initState() {
    super.initState();
    _definirIdiomaInicial();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _pararCronometro();
    _luzTimer?.cancel();
    _voicePlayer.dispose();
    _clickPlayer.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String t(String chave) {
    return textos[idioma]![chave]!;
  }

  void _definirIdiomaInicial() {
    final String idiomaSistema =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    if (textos.containsKey(idiomaSistema)) {
      idioma = idiomaSistema;
    }
  }

  String get tempoFormatado {
    final int minutos = segundos ~/ 60;
    final int restoSegundos = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:'
        '${restoSegundos.toString().padLeft(2, '0')}';
  }

  void _iniciarCronometro() {
    _pararCronometro();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        segundos++;
      });
    });
  }

  void _pararCronometro() {
    _cronometro?.cancel();
    _cronometro = null;
  }

  Future<void> _startStop() async {
    if (jogando) {
      await _encerrarJogo(mostrarMensagem: true);
      return;
    }

    await _iniciarJogo();
  }

  Future<void> _iniciarJogo() async {
    final int partida = ++_partidaAtual;
    _luzTimer?.cancel();
    setState(() {
      nivel = 1;
      score = 0;
      acertosNoNivel = 0;
      segundos = 0;
      jogando = true;
      aguardandoResposta = false;
      falandoCores = false;
      corAcesa = null;
    });
    _iniciarCronometro();
    await _novaRodada(partida);
  }

  bool _partidaValida(int partida) {
    return mounted && jogando && partida == _partidaAtual;
  }

  Future<void> _novaRodada(int partida) async {
    if (!_partidaValida(partida)) {
      return;
    }

    setState(() {
      sequencia = List.generate(nivel, (_) => _sortearCor());
      posicaoResposta = 0;
      falandoCores = true;
      aguardandoResposta = false;
      corAcesa = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));

    for (final GeniusColor cor in sequencia) {
      if (!_partidaValida(partida)) {
        return;
      }
      await _acenderCor(cor, tocarClick: false);
      if (!_partidaValida(partida)) {
        return;
      }
      await _tocarAudioCor(cor);
      if (!_partidaValida(partida)) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    if (!_partidaValida(partida)) {
      return;
    }

    setState(() {
      falandoCores = false;
      aguardandoResposta = true;
      corAcesa = null;
    });
  }

  GeniusColor _sortearCor() {
    return GeniusColor.values[_random.nextInt(GeniusColor.values.length)];
  }

  Future<void> _apertarCor(GeniusColor cor) async {
    if (!jogando || falandoCores || !aguardandoResposta) {
      return;
    }

    await _acenderCor(cor);

    if (cor != sequencia[posicaoResposta]) {
      await _encerrarJogo(mostrarMensagem: true);
      return;
    }

    posicaoResposta++;

    if (posicaoResposta < sequencia.length) {
      return;
    }

    setState(() {
      score++;
      acertosNoNivel++;
      aguardandoResposta = false;
    });

    if (acertosNoNivel == 2) {
      setState(() {
        nivel++;
        acertosNoNivel = 0;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 650));
    await _novaRodada(_partidaAtual);
  }

  Future<void> _acenderCor(GeniusColor cor, {bool tocarClick = true}) async {
    _luzTimer?.cancel();

    if (mounted) {
      setState(() {
        corAcesa = cor;
      });
    }

    if (tocarClick) {
      await _tocarClick();
    }

    _luzTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) {
        return;
      }
      setState(() {
        corAcesa = null;
      });
    });
  }

  Future<void> _tocarAudioCor(GeniusColor cor) async {
    final String nome = nomesArquivos[cor]!;
    final String caminho = 'media-files/genius/$idioma/$nome.mp3';
    await _tocarAsset(_voicePlayer, caminho);
  }

  Future<void> _tocarClick() async {
    await _tocarAsset(_clickPlayer, 'media-files/genius/click.mp3');
  }

  Future<void> _tocarAsset(AudioPlayer player, String caminho) async {
    try {
      await player.stop();
      await player.play(AssetSource(caminho));
    } catch (e) {
      // Ignora erros de áudio (ex: web sem suporte)
      debugPrint('Erro ao tocar áudio: $e');
    }
  }

  Future<void> _reiniciar() async {
    await _encerrarJogo(mostrarMensagem: false);
    await _iniciarJogo();
  }

  Future<void> _encerrarJogo({required bool mostrarMensagem}) async {
    _partidaAtual++;
    final int scoreFinal = score;
    final String tempoFinal = tempoFormatado;

    _pararCronometro();
    _luzTimer?.cancel();
    await _voicePlayer.stop();
    await _clickPlayer.stop();

    if (mounted) {
      setState(() {
        nivel = 1;
        score = 0;
        acertosNoNivel = 0;
        segundos = 0;
        jogando = false;
        falandoCores = false;
        aguardandoResposta = false;
        corAcesa = null;
        sequencia = [];
        posicaoResposta = 0;
      });
    }

    if (mostrarMensagem && mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(t('fim')),
            content: Text(
              '${t('pontuacaoFinal')}: ${scoreFinal.toString().padLeft(4, '0')}\n'
              '${t('tempoFinal')}: $tempoFinal',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('ok')),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _voltar() async {
    await _encerrarJogo(mostrarMensagem: false);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _voltar,
          icon: const Icon(Icons.arrow_back_ios_new, color: roxo, size: 32),
        ),
        titleSpacing: 0,
        title: Text(
          t('titulo'),
          style: const TextStyle(
            color: roxo,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: idioma,
              icon: const Icon(Icons.keyboard_arrow_down, color: roxo),
              style: const TextStyle(
                color: roxo,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              items: const [
                DropdownMenuItem(value: 'pt', child: Text('Português')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
              ],
              onChanged: falandoCores
                  ? null
                  : (novoIdioma) {
                      setState(() {
                        idioma = novoIdioma!;
                      });
                    },
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 4, 26, 22),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${t('nivel')}: $nivel',
                    style: const TextStyle(
                      color: roxo,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${t('cronometro')}: $tempoFormatado',
                    style: const TextStyle(
                      color: roxo,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,  
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) {
                                final GeniusColor? cor =
                                    GeniusPainter.corNoPonto(
                                      details.localPosition,
                                      constraints.biggest,
                                    );
                                if (cor != null) {
                                  _apertarCor(cor);
                                }
                              },
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: GeniusPainter(corAcesa: corAcesa),
                              ),
                            );
                          },
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: roxo,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.black45,
                            minimumSize: const Size(92, 46),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: _startStop,
                          child: Text(
                            jogando ? t('stop') : t('start'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '${t('score')}:',
                        style: const TextStyle(
                          color: roxo,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Text(
                        score.toString().padLeft(4, '0'),
                        style: const TextStyle(
                          color: roxo,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roxo,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black45,
                      minimumSize: const Size(106, 48),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: _reiniciar,
                    child: Text(
                      t('restart'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GeniusPainter extends CustomPainter {
  const GeniusPainter({this.corAcesa});

  static const Color roxo = Color(0XFF3C00A7);
  final GeniusColor? corAcesa;

  static final Map<GeniusColor, Color> cores = {
    GeniusColor.yellow: const Color(0XFFFFFF25),
    GeniusColor.blue: const Color(0XFF1710E8),
    GeniusColor.red: const Color(0XFFFF1023),
    GeniusColor.orange: const Color(0XFFFF9A24),
    GeniusColor.green: const Color(0XFF00FF35),
  };

  static const List<GeniusColor> ordem = [
    GeniusColor.yellow,
    GeniusColor.blue,
    GeniusColor.red,
    GeniusColor.orange,
    GeniusColor.green,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final List<Path> fatias = _criarFatias(size);

    final Paint sombra = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final Paint preenchimento = Paint()..style = PaintingStyle.fill;
    final Paint borda = Paint()
      ..color = roxo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    final Paint separador = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < ordem.length; i++) {
      final GeniusColor cor = ordem[i];
      canvas.drawPath(fatias[i].shift(const Offset(5, 7)), sombra);
      preenchimento.color = _corVisual(cor);
      canvas.drawPath(fatias[i], preenchimento);
    }

    final PathsGenius paths = _criarPaths(size);
    canvas.drawPath(paths.contornoExterno, borda);
    canvas.drawPath(paths.miolo, separador);

    final Paint branco = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(paths.miolo, branco);
  }

  Color _corVisual(GeniusColor cor) {
    final Color base = cores[cor]!;
    if (corAcesa == cor) {
      return Color.lerp(base, Colors.white, 0.42)!;
    }
    return base;
  }

  static GeniusColor? corNoPonto(Offset ponto, Size size) {
    final List<Path> fatias = _criarFatias(size);
    for (int i = 0; i < fatias.length; i++) {
      if (fatias[i].contains(ponto)) {
        return ordem[i];
      }
    }
    return null;
  }

  static List<Path> _criarFatias(Size size) {
    final PathsGenius paths = _criarPaths(size);
    final List<Path> fatias = [];

    for (int i = 0; i < ordem.length; i++) {
      final int proximo = (i + 1) % ordem.length;
      fatias.add(
        Path()
          ..moveTo(paths.externo[i].dx, paths.externo[i].dy)
          ..lineTo(paths.externo[proximo].dx, paths.externo[proximo].dy)
          ..lineTo(paths.interno[proximo].dx, paths.interno[proximo].dy)
          ..lineTo(paths.interno[i].dx, paths.interno[i].dy)
          ..close(),
      );
    }

    return fatias;
  }

  static PathsGenius _criarPaths(Size size) {
    final double lado = math.min(size.width, size.height);
    final Offset centro = Offset(size.width / 2, size.height / 2);
    final double raioExterno = lado * 0.42;
    final double raioInterno = lado * 0.23;

    final List<Offset> externo = _pontosPentagono(centro, raioExterno);
    final List<Offset> interno = _pontosPentagono(centro, raioInterno);

    final Path contornoExterno = Path()
      ..moveTo(externo.first.dx, externo.first.dy);
    for (final Offset ponto in externo.skip(1)) {
      contornoExterno.lineTo(ponto.dx, ponto.dy);
    }
    contornoExterno.close();

    final Path miolo = Path()..moveTo(interno.first.dx, interno.first.dy);
    for (final Offset ponto in interno.skip(1)) {
      miolo.lineTo(ponto.dx, ponto.dy);
    }
    miolo.close();

    return PathsGenius(
      externo: externo,
      interno: interno,
      contornoExterno: contornoExterno,
      miolo: miolo,
    );
  }

  static List<Offset> _pontosPentagono(Offset centro, double raio) {
    return List.generate(5, (index) {
      final double angulo = -math.pi / 2 + index * 2 * math.pi / 5;
      return Offset(
        centro.dx + raio * math.cos(angulo),
        centro.dy + raio * math.sin(angulo),
      );
    });
  }

  @override
  bool shouldRepaint(covariant GeniusPainter oldDelegate) {
    return oldDelegate.corAcesa != corAcesa;
  }
}

class PathsGenius {
  const PathsGenius({
    required this.externo,
    required this.interno,
    required this.contornoExterno,
    required this.miolo,
  });

  final List<Offset> externo;
  final List<Offset> interno;
  final Path contornoExterno;
  final Path miolo;
}
