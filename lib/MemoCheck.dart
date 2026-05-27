import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'widget_scores.dart';

class Memocheck extends StatefulWidget {
  const Memocheck({super.key});

  @override
  State<Memocheck> createState() => _MemocheckState();
}

class MemoCheckScreen extends StatelessWidget {
  const MemoCheckScreen({super.key});

  @override
  Widget build(BuildContext context) => const Memocheck();
}

class _MemocheckState extends State<Memocheck> {
  final Map<String, List<String>> temasImagens = const {
    'Animais da Amazônia': [
      'assets/tema1/arara.jpg',
      'assets/tema1/macacoprego.jpg',
      'assets/tema1/onca.jpg',
      'assets/tema1/tamandua.jpg',
    ],
    'Carros': [
      'assets/tema2/car1.jpg',
      'assets/tema2/car2.jpg',
      'assets/tema2/car3.jpg',
      'assets/tema2/car4.jpg',
    ],
    'Personalizado': [],
  };

  String selectedTema = 'Animais da Amazônia';
  int acertos = 0;
  int erros = 0;
  int segundosDecorridos = 0;
  Timer? gameTimer;

  String gameState = 'START';
  int countdownValue = 3;
  Timer? countdownTimer;

  List<String> currentImages = [];
  List<File> customImages = [];
  List<bool> cartasViradas = List.generate(8, (_) => true);
  List<bool> cartasAcertadas = List.generate(8, (_) => false);

  int? primeiroIndiceClicado;
  bool processandoClique = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _carregarImagensDoTema();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    countdownTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _carregarImagensDoTema() {
    final List<String> baseImages;

    if (selectedTema == 'Personalizado' && customImages.length == 4) {
      baseImages = customImages.map((file) => file.path).toList();
    } else {
      baseImages = List.from(temasImagens[selectedTema]!);
    }

    currentImages = [...baseImages, ...baseImages]..shuffle();
    cartasViradas = List.generate(8, (_) => true);
    cartasAcertadas = List.generate(8, (_) => false);
    primeiroIndiceClicado = null;
    processandoClique = false;
  }

  String _formatarTempo(int segundos) {
    final minutos = segundos ~/ 60;
    final restanteSegundos = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${restanteSegundos.toString().padLeft(2, '0')}';
  }

  String _formatarContador(int valor) {
    return valor.toString().padLeft(2, '0');
  }

  String get _acertosFormatados => _formatarContador(acertos);
  String get _errosFormatados => _formatarContador(erros);

  void _pressionouBotaoPrincipal() {
    if (gameState == 'START') {
      _iniciarContagemRegressiva();
    } else if (gameState == 'STOP') {
      _finalizarPartida(mensagem: 'Partida interrompida!');
    }
  }

  void _iniciarContagemRegressiva() {
    setState(() {
      gameState = 'COUNTDOWN';
      countdownValue = 3;
      cartasViradas = List.generate(8, (_) => true);
    });

    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (countdownValue > 1) {
          countdownValue--;
        } else {
          timer.cancel();
          gameState = 'STOP';
          cartasViradas = List.generate(8, (_) => false);
          _iniciarCronometro();
        }
      });
    });
  }

  void _iniciarCronometro() {
    gameTimer?.cancel();
    segundosDecorridos = 0;
    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        segundosDecorridos++;
      });
    });
  }

  Future<void> _finalizarPartida({required String mensagem}) async {
    gameTimer?.cancel();
    countdownTimer?.cancel();

    final tempoFinal = segundosDecorridos;
    final acertosFinais = acertos;
    final errosFinais = erros;

    await WidgetScores.saveScore('memoCheck', acertosFinais);

    setState(() {
      gameState = 'START';
      acertos = 0;
      erros = 0;
      segundosDecorridos = 0;
      _carregarImagensDoTema();
    });

    _mostrarDialogoFimDeJogo(
      titulo: mensagem,
      acertosFinais: acertosFinais,
      errosFinais: errosFinais,
      tempoFinal: tempoFinal,
    );
  }

  void _mostrarDialogoFimDeJogo({
    required String titulo,
    required int acertosFinais,
    required int errosFinais,
    required int tempoFinal,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(
          'Pontuação Final:\n'
          'Acertos: ${_formatarContador(acertosFinais)}\n'
          'Erros: ${_formatarContador(errosFinais)}\n'
          'Tempo: ${_formatarTempo(tempoFinal)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cartaClicada(int indice) {
    if (gameState != 'STOP' ||
        processandoClique ||
        cartasViradas[indice] ||
        cartasAcertadas[indice] ||
        indice == primeiroIndiceClicado) {
      return;
    }

    setState(() {
      cartasViradas[indice] = true;
    });

    if (primeiroIndiceClicado == null) {
      primeiroIndiceClicado = indice;
      return;
    }

    processandoClique = true;
    final primeiro = primeiroIndiceClicado!;

    if (currentImages[primeiro] == currentImages[indice]) {
      setState(() {
        acertos++;
        cartasAcertadas[primeiro] = true;
        cartasAcertadas[indice] = true;
        primeiroIndiceClicado = null;
        processandoClique = false;
      });

      if (cartasAcertadas.every((element) => element)) {
        _finalizarPartida(mensagem: 'Parabéns! Você venceu!');
      }
    } else {
      setState(() {
        erros++;
      });

      HapticFeedback.mediumImpact();

      Timer(const Duration(seconds: 1), () {
        if (!mounted) return;

        setState(() {
          cartasViradas[primeiro] = false;
          cartasViradas[indice] = false;
          primeiroIndiceClicado = null;
          processandoClique = false;
        });
      });
    }
  }

  Future<void> _abrirConfiguracoesGaleria() async {
    final picker = ImagePicker();
    final imagensSelecionadas = <File>[];

    for (var i = 0; i < 4; i++) {
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (!mounted) return;

      if (image == null) {
        break;
      }

      imagensSelecionadas.add(File(image.path));
    }

    if (imagensSelecionadas.length == 4) {
      setState(() {
        customImages = imagensSelecionadas;
        selectedTema = 'Personalizado';
        _carregarImagensDoTema();
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione exatamente 4 fotos da galeria.'),
        ),
      );
    }
  }

  Widget _renderizarImagemCard(String path) {
    final image = selectedTema == 'Personalizado'
        ? Image.file(File(path), fit: BoxFit.cover)
        : Image.asset(path, fit: BoxFit.cover);

    return SizedBox.expand(child: image);
  }

  Widget _buildCard(int index) {
    if (currentImages.isEmpty) return const SizedBox.shrink();

    final virada = cartasViradas[index] || cartasAcertadas[index];

    return GestureDetector(
      onTap: () => _cartaClicada(index),
      child: SizedBox(
        width: 100,
        height: 100,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: virada ? _cardFrente(index) : _cardVerso(index),
        ),
      ),
    );
  }

  Widget _cardFrente(int index) {
    return Container(
      key: ValueKey('front-$index'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _renderizarImagemCard(currentImages[index]),
      ),
    );
  }

  Widget _cardVerso(int index) {
    return Container(
      key: ValueKey('back-$index'),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.help_outline, size: 24, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusText(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.indigo, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final temaDropdownValue = selectedTema == 'Personalizado'
        ? 'Animais da Amazônia'
        : selectedTema;
    final jogoRodando = gameState == 'STOP' || gameState == 'COUNTDOWN';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.indigo,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'MemoCheck',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusText(
                    'Tempo:',
                    _formatarTempo(segundosDecorridos),
                  ),
                  _buildStatusText('Acertos:', _acertosFormatados),
                  _buildStatusText('Erros:', _errosFormatados),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCard(0),
                            _buildCard(1),
                            const SizedBox(width: 80),
                            _buildCard(2),
                            _buildCard(3),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCard(4),
                            _buildCard(5),
                            const SizedBox(width: 80),
                            _buildCard(6),
                            _buildCard(7),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                          backgroundColor: gameState == 'STOP'
                              ? Colors.red
                              : Colors.indigo,
                        ),
                        onPressed: _pressionouBotaoPrincipal,
                        child: Text(
                          gameState == 'START'
                              ? 'Start'
                              : gameState == 'STOP'
                              ? 'Stop'
                              : '$countdownValue',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Tema: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: temaDropdownValue,
                        items: const [
                          DropdownMenuItem(
                            value: 'Animais da Amazônia',
                            child: Text('Animais da Amazônia'),
                          ),
                          DropdownMenuItem(
                            value: 'Carros',
                            child: Text('Carros'),
                          ),
                        ],
                        onChanged: jogoRodando
                            ? null
                            : (value) {
                                if (value == null) return;

                                setState(() {
                                  selectedTema = value;
                                  _carregarImagensDoTema();
                                });
                              },
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.indigo,
                      size: 28,
                    ),
                    onPressed: jogoRodando ? null : _abrirConfiguracoesGaleria,
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
