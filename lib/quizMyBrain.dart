import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'widget_scores.dart';

class Questao {
  final int id;
  final int peso;
  final String tipo;
  final String enunciado;
  final dynamic alternativas;
  final dynamic resposta;

  Questao({
    required this.id,
    required this.peso,
    required this.tipo,
    required this.enunciado,
    required this.alternativas,
    required this.resposta,
  });

  factory Questao.fromJson(Map<String, dynamic> json) {
    return Questao(
      id: json['id'],
      peso: json['peso'],
      tipo: json['tipo'],
      enunciado: json['enunciado'],
      alternativas: json['alternativas'],
      resposta: json['resposta'],
    );
  }
}

class QuizMyBrain extends StatefulWidget {
  const QuizMyBrain({super.key});

  @override
  State<QuizMyBrain> createState() => _QuizMyBrainState();
}

class _QuizMyBrainState extends State<QuizMyBrain> {
  static const primaryColor = Color(0XFF3C00A7);

  int indicePerguntaAtual = 0;
  int? indiceSelecionado;
  int pontuacaoTotal = 0;
  late Future<List<Questao>> futureQuestoes;
  StreamSubscription<AccelerometerEvent>? _subscription;
  Map<int, int> associacoesREL = {};
  List<dynamic> conceitosRestantes = [];
  final Set<int> questoesCorrigidas = {};

  @override
  void initState() {
    super.initState();
    futureQuestoes = carregarQuestoes();
    _iniciarSensor();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _iniciarSensor() {
    _subscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!mounted) return;

      if (event.x > 3.5 && indiceSelecionado != 0) {
        setState(() {
          indiceSelecionado = 0;
        });
      } else if (event.x < -3.5 && indiceSelecionado != 1) {
        setState(() {
          indiceSelecionado = 1;
        });
      }
    });
  }

  Future<List<Questao>> carregarQuestoes() async {
    final resposta = await rootBundle.loadString('assets/Questoes.json');
    final dadosDoJson = jsonDecode(resposta) as Map<String, dynamic>;
    final listaPerguntasRaw = dadosDoJson['perguntas'] as List<dynamic>;
    return listaPerguntasRaw
        .map((item) => Questao.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void _configurarOrientacao(String tipo) {
    if (tipo == "REL") {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _inicializarQuestaoREL(List<dynamic> conceitos) {
    if (associacoesREL.isEmpty && conceitosRestantes.isEmpty) {
      conceitosRestantes = List<dynamic>.from(conceitos);
    }
  }

  Future<void> _avancar(
    Questao questaoAtual,
    List<Questao> listaQuestoes,
  ) async {
    _corrigirQuestao(questaoAtual);

    if (indicePerguntaAtual >= listaQuestoes.length - 1) {
      await _mostrarPontuacaoEVoltar();
      return;
    }

    setState(() {
      indicePerguntaAtual++;
      indiceSelecionado = null;
      associacoesREL.clear();
      conceitosRestantes.clear();
    });
  }

  Future<void> _encerrar(Questao questaoAtual) async {
    if (_questaoFoiRespondida(questaoAtual)) {
      _corrigirQuestao(questaoAtual);
    }

    await _mostrarPontuacaoEVoltar();
  }

  bool _questaoFoiRespondida(Questao questao) {
    if (questao.tipo == "REL") {
      final alternativas = questao.alternativas as List<dynamic>;
      final conceitos = alternativas[0] as List<dynamic>;
      return associacoesREL.length == conceitos.length;
    }

    return indiceSelecionado != null;
  }

  void _corrigirQuestao(Questao questao) {
    if (questoesCorrigidas.contains(questao.id)) return;

    if (_respostaEstaCorreta(questao)) {
      pontuacaoTotal += questao.peso;
    }

    questoesCorrigidas.add(questao.id);
  }

  bool _respostaEstaCorreta(Questao questao) {
    if (questao.tipo == "REL") {
      final respostas = questao.resposta as List<dynamic>;

      for (final resposta in respostas) {
        final par = resposta as List<dynamic>;
        final conceitoIndex = par[0] as int;
        final caixaIndex = par[1] as int;

        if (associacoesREL[conceitoIndex] != caixaIndex) {
          return false;
        }
      }

      return true;
    }

    return indiceSelecionado == questao.resposta;
  }

  Future<void> _mostrarPontuacaoEVoltar() async {
    await WidgetScores.saveScore('quizMyBrain', pontuacaoTotal);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pontuação final"),
          content: Text("Sua pontuação total foi: $pontuacaoTotal"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 28,
            color: primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Quiz My Brain",
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Questao>>(
        future: futureQuestoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text("Erro ao carregar dados."));
          }

          final listaQuestoes = snapshot.data!;
          final questaoAtual = listaQuestoes[indicePerguntaAtual];

          _configurarOrientacao(questaoAtual.tipo);

          if (questaoAtual.tipo == "REL") {
            return _buildQuestaoRel(context, questaoAtual, listaQuestoes);
          }

          return _buildQuestaoPadrao(questaoAtual, listaQuestoes);
        },
      ),
    );
  }

  Widget _buildQuestaoRel(
    BuildContext context,
    Questao questaoAtual,
    List<Questao> listaQuestoes,
  ) {
    final alternativas = questaoAtual.alternativas as List<dynamic>;
    final conceitos = alternativas[0] as List<dynamic>;
    final caixasDestino = alternativas[1] as List<dynamic>;

    _inicializarQuestaoREL(conceitos);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questaoAtual.enunciado,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: conceitosRestantes.map((conceito) {
              final originalIndex = conceitos.indexOf(conceito);

              return Draggable<int>(
                data: originalIndex,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      conceito.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: Text(
                    conceito.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                child: Text(
                  conceito.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(caixasDestino.length, (indexCaixa) {
              int? conceitoAssociadoIndex;

              associacoesREL.forEach((key, value) {
                if (value == indexCaixa) {
                  conceitoAssociadoIndex = key;
                }
              });

              final textoConceito = conceitoAssociadoIndex != null
                  ? conceitos[conceitoAssociadoIndex!].toString()
                  : null;

              return DragTarget<int>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    associacoesREL[details.data] = indexCaixa;
                    conceitosRestantes.remove(conceitos[details.data]);
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.28,
                    height: 75,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: candidateData.isNotEmpty
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          caixasDestino[indexCaixa].toString(),
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (textoConceito != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            textoConceito,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          const Spacer(),
          _buildBotoesInferiores(
            questaoAtual,
            listaQuestoes,
            podeAvancar: associacoesREL.length == conceitos.length,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestaoPadrao(
    Questao questaoAtual,
    List<Questao> listaQuestoes,
  ) {
    final ehVerdadeiroOuFalso = questaoAtual.tipo == "VF";
    final alternativas = questaoAtual.alternativas as List<dynamic>;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  questaoAtual.enunciado,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 60),
                if (ehVerdadeiroOuFalso)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: alternativas.asMap().entries.map((entry) {
                      return _buildTextoOpcao(
                        entry.value.toString(),
                        entry.key,
                      );
                    }).toList(),
                  )
                else
                  ...alternativas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final textoAlternativa = entry.value.toString();
                    final prefixo = "${String.fromCharCode(97 + index)}) ";
                    final estaSelecionado = indiceSelecionado == index;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          indiceSelecionado = index;
                        });
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prefixo,
                              style: _estiloAlternativa(estaSelecionado),
                            ),
                            Expanded(
                              child: Text(
                                textoAlternativa,
                                style: _estiloAlternativa(estaSelecionado),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (ehVerdadeiroOuFalso) ...[
                  const SizedBox(height: 60),
                  const Center(
                    child: Icon(
                      Icons.screen_rotation,
                      size: 80,
                      color: Colors.black26,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 30,
            top: 10,
          ),
          child: _buildBotoesInferiores(
            questaoAtual,
            listaQuestoes,
            podeAvancar: indiceSelecionado != null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextoOpcao(String texto, int indice) {
    final estaSelecionado = indiceSelecionado == indice;

    return InkWell(
      onTap: () {
        setState(() {
          indiceSelecionado = indice;
        });
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 20,
            fontWeight: estaSelecionado ? FontWeight.bold : FontWeight.w500,
            color: estaSelecionado ? primaryColor : Colors.black87,
          ),
        ),
      ),
    );
  }

  TextStyle _estiloAlternativa(bool estaSelecionado) {
    return TextStyle(
      fontSize: 18,
      fontWeight: estaSelecionado ? FontWeight.bold : FontWeight.w500,
      color: estaSelecionado ? primaryColor : Colors.black87,
    );
  }

  Widget _buildBotoesInferiores(
    Questao questaoAtual,
    List<Questao> listaQuestoes, {
    required bool podeAvancar,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          style: _estiloBotao(),
          onPressed: () => _encerrar(questaoAtual),
          child: const Text(
            "Encerrar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: _estiloBotao(),
          onPressed: () {
            if (podeAvancar) {
              _avancar(questaoAtual, listaQuestoes);
            }
          },
          child: const Text(
            "Avançar",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _estiloBotao() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }
}
