import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'aprender.dart';

class Questao {
  final int id;
  final int peso;
  final String tipo;
  final String enunciado;
  final List<dynamic> alternativas;
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
  int indicePerguntaAtual = 0;
  int? indiceSelecionado;
  late Future<List<Questao>> futureQuestoes;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    futureQuestoes = carregarQuestoes();
    _iniciarSensor();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _iniciarSensor() {
    _subscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (!mounted) return;

      if (event.x > 3.5) {
        if (indiceSelecionado != 0) {
          setState(() {
            indiceSelecionado = 0;
          });
        }
      } else if (event.x < -3.5) {
        if (indiceSelecionado != 1) {
          setState(() {
            indiceSelecionado = 1;
          });
        }
      }
    });
  }

  Future<List<Questao>> carregarQuestoes() async {
    final String resposta = await rootBundle.loadString('assets/Questoes.json');
    final Map<String, dynamic> dadosDoJson = jsonDecode(resposta);
    final List<dynamic> listaPerguntasRaw = dadosDoJson['perguntas'];
    return listaPerguntasRaw.map((item) => Questao.fromJson(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0XFF3C00A7);

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
          final bool ehVerdadeiroOuFalso = questaoAtual.tipo == "VF";

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
                          children: [
                            Text(
                              "Verdadeiro",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: indiceSelecionado == 0
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: indiceSelecionado == 0
                                    ? primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              "Falso",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: indiceSelecionado == 1
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: indiceSelecionado == 1
                                    ? primaryColor
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        )
                      else
                        ...questaoAtual.alternativas.asMap().entries.map((
                          entry,
                        ) {
                          int index = entry.key;
                          String textoAlternativa = entry.value.toString();
                          String prefixo =
                              "${String.fromCharCode(97 + index)}) ";
                          bool estaSelecionado = indiceSelecionado == index;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                indiceSelecionado = index;
                              });
                            },
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prefixo,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: estaSelecionado
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: estaSelecionado
                                          ? primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      textoAlternativa,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: estaSelecionado
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: estaSelecionado
                                            ? primaryColor
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                      if (ehVerdadeiroOuFalso) ...[
                        const SizedBox(height: 70),
                        const Center(
                          child: Icon(
                            Icons.screen_rotation,
                            size: 200,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Aprender(),
                          ),
                        );
                      },
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (indiceSelecionado != null &&
                            indicePerguntaAtual < listaQuestoes.length - 1) {
                          setState(() {
                            indicePerguntaAtual++;
                            indiceSelecionado = null;
                          });
                        }
                      },
                      child: const Text(
                        "Próximo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
