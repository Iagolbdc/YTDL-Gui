import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajuda"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Colors.blue.withOpacity(0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Como posso te ajudar?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Aqui você encontra tudo o que precisa para usar o app sem dificuldades.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Como Usar
            _buildSection(
              context,
              icon: Icons.play_circle_outline,
              title: "Como Usar",
              children: [
                _buildStep("1. Cole a URL de um vídeo ou playlist do YouTube."),
                _buildStep("2. Clique em 'Carregar Vídeos' para ver a lista."),
                _buildStep("3. Escolha onde salvar com 'Escolher Pasta'."),
                _buildStep("4. Marque os vídeos que deseja baixar."),
                _buildStep(
                  "5. Clique em 'MP3' para áudio ou 'MP4' para vídeo completo.",
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dicas
            _buildSection(
              context,
              icon: Icons.lightbulb_outline,
              title: "Dicas Úteis",
              children: [
                _buildTip(
                  "Você pode baixar apenas o áudio (MP3) para economizar espaço.",
                ),
                _buildTip("O app lembra a última pasta que você usou."),
                _buildTip(
                  "Vídeos baixados aparecem no histórico para fácil acesso.",
                ),
                _buildTip(
                  "Playlists grandes podem demorar um pouco para carregar.",
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Problemas Comuns
            _buildSection(
              context,
              icon: Icons.warning_amber,
              title: "Problemas Comuns",
              children: [
                _buildProblem(
                  "O app não inicia",
                  "Feche e abra novamente. Se continuar, reinicie o computador.",
                ),
                _buildProblem(
                  "URL não carrega",
                  "Verifique se a URL é do YouTube e está completa (começa com https://).",
                ),
                _buildProblem(
                  "Download falhou",
                  "Pode ser temporário. Tente novamente mais tarde.",
                ),
                _buildProblem(
                  "Arquivo não aparece na pasta",
                  "Verifique se a pasta escolhida está acessível e tem permissão de escrita.",
                ),
                _buildProblem(
                  "O app diz que está atualizando",
                  "É normal na primeira vez. Depois disso, será rápido.",
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Segurança
            _buildSection(
              context,
              icon: Icons.security,
              title: "Segurança",
              children: [
                const Text(
                  "Seu app é seguro e não envia seus dados para ninguém.",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  "• Baixamos apenas o que você pede.",
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  "• Não coletamos histórico, URLs ou arquivos.",
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  "• O yt-dlp é uma ferramenta open-source confiável.",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Suporte
            _buildSection(
              context,
              icon: Icons.support,
              title: "Precisa de Ajuda?",
              children: [
                const Text(
                  "Estamos aqui para ajudar!",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Aqui você pode abrir um link, e-mail ou formulário
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Funcionalidade de contato em breve!"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text("Fale conosco"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, size: 16, color: Colors.yellow),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildProblem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
