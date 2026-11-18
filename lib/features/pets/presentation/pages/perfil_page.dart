import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/pets_entities.dart';
import 'app_shell.dart' show inicialDe, petLight, petMuted, petPrimary;

/// Avatar do usuário: mostra a foto de perfil ou, sem foto, a inicial do nome.
/// Sem [raio], preenche o espaço disponível (ex.: cabeçalho do Drawer).
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({required this.usuario, this.raio, super.key});

  final Usuario? usuario;
  final double? raio;

  @override
  Widget build(BuildContext context) {
    final url = usuario?.fotoUrl;
    return CircleAvatar(
      radius: raio,
      backgroundColor: petLight,
      foregroundImage: url == null ? null : NetworkImage(url),
      // Se a imagem não carregar, a inicial continua visível.
      onForegroundImageError: url == null ? null : (_, __) {},
      child: Text(
        inicialDe(usuario?.nome ?? ''),
        style: TextStyle(
          fontSize: raio == null ? 28 : raio! * 0.85,
          fontWeight: FontWeight.w900,
          color: petPrimary,
        ),
      ),
    );
  }
}

String _mimePorNome(String nome) {
  final n = nome.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

class PerfilPage extends ConsumerStatefulWidget {
  const PerfilPage({super.key});

  @override
  ConsumerState<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends ConsumerState<PerfilPage> {
  final _nome = TextEditingController();
  final _senhaAtual = TextEditingController();
  final _novaSenha = TextEditingController();
  final _confirmaSenha = TextEditingController();
  final _picker = ImagePicker();

  bool _salvandoNome = false;
  bool _enviandoFoto = false;
  bool _trocandoSenha = false;
  bool _verSenhas = false;

  @override
  void initState() {
    super.initState();
    _nome.text = ref.read(appProvider).usuario?.nome ?? '';
  }

  @override
  void dispose() {
    _nome.dispose();
    _senhaAtual.dispose();
    _novaSenha.dispose();
    _confirmaSenha.dispose();
    super.dispose();
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  /// Executa [acao] e mostra o resultado. Devolve true em caso de sucesso.
  Future<bool> _executar(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      _aviso(sucesso);
      return true;
    } catch (e) {
      _aviso('$e');
      return false;
    }
  }

  Future<void> _salvarNome() async {
    setState(() => _salvandoNome = true);
    await _executar(
      () => ref.read(appProvider.notifier).atualizarNome(_nome.text),
      'Nome atualizado.',
    );
    if (mounted) setState(() => _salvandoNome = false);
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    XFile? arquivo;
    try {
      arquivo = await _picker.pickImage(
        source: origem,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
    } catch (_) {
      _aviso('Não foi possível abrir a galeria ou a câmera.');
      return;
    }
    if (arquivo == null) return;

    final bytes = await arquivo.readAsBytes();
    final mime = arquivo.mimeType ?? _mimePorNome(arquivo.name);

    if (!mounted) return;
    setState(() => _enviandoFoto = true);
    await _executar(
      () => ref.read(appProvider.notifier).atualizarFoto(bytes, mime),
      'Foto atualizada.',
    );
    if (mounted) setState(() => _enviandoFoto = false);
  }

  Future<void> _removerFoto() async {
    setState(() => _enviandoFoto = true);
    await _executar(
      () => ref.read(appProvider.notifier).removerFoto(),
      'Foto removida.',
    );
    if (mounted) setState(() => _enviandoFoto = false);
  }

  void _opcoesFoto(Usuario u) {
    final temCamera = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () {
              Navigator.pop(ctx);
              _escolherFoto(ImageSource.gallery);
            },
          ),
          if (temCamera)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _escolherFoto(ImageSource.camera);
              },
            ),
          if (u.fotoUrl != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remover foto'),
              onTap: () {
                Navigator.pop(ctx);
                _removerFoto();
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _trocarSenha() async {
    if (_novaSenha.text != _confirmaSenha.text) {
      _aviso('A confirmação não confere com a nova senha.');
      return;
    }
    setState(() => _trocandoSenha = true);
    final ok = await _executar(
      () => ref
          .read(appProvider.notifier)
          .alterarSenha(_senhaAtual.text, _novaSenha.text),
      'Senha alterada com sucesso.',
    );
    if (!mounted) return;
    setState(() {
      _trocandoSenha = false;
      if (ok) {
        _senhaAtual.clear();
        _novaSenha.clear();
        _confirmaSenha.clear();
      }
    });
  }

  Future<void> _sair() async {
    try {
      await ref.read(appProvider.notifier).sair();
    } catch (e) {
      _aviso('$e');
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _avatar(Usuario u) => SizedBox(
        width: 112,
        height: 112,
        child: Stack(children: [
          AvatarUsuario(usuario: u, raio: 56),
          if (_enviandoFoto)
            const Positioned.fill(
              child: DecoratedBox(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: petPrimary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _enviandoFoto ? null : () => _opcoesFoto(u),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child:
                      Icon(Icons.photo_camera, size: 20, color: Colors.white),
                ),
              ),
            ),
          ),
        ]),
      );

  Widget _estatistica(IconData icone, String valor, String rotulo) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Icon(icone, color: petPrimary),
            const SizedBox(height: 4),
            Text(valor,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(rotulo, style: const TextStyle(color: petMuted)),
          ]),
        ),
      );

  Widget _campoSenha(TextEditingController c, String rotulo) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          obscureText: !_verSenhas,
          decoration: InputDecoration(
            labelText: rotulo,
            suffixIcon: IconButton(
              tooltip: _verSenhas ? 'Ocultar senhas' : 'Mostrar senhas',
              icon: Icon(
                  _verSenhas ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _verSenhas = !_verSenhas),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    final u = s.usuario;
    // Durante a saída da conta o usuário some antes de a tela ser fechada.
    if (u == null) return const Scaffold();

    final minhasAvaliacoes =
        s.avaliacoes.where((a) => a.usuarioId == u.id).length;
    final nomeAlterado = _nome.text.trim() != u.nome;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: _avatar(u)),
                const SizedBox(height: 14),
                Text(u.nome.isEmpty ? 'Sem nome' : u.nome,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(u.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: petMuted)),
                const SizedBox(height: 10),
                Center(
                    child: Chip(
                        avatar: Icon(
                            u.tipo == TipoConta.empresa
                                ? Icons.storefront_outlined
                                : Icons.pets,
                            size: 18,
                            color: petPrimary),
                        label: Text(u.tipo == TipoConta.empresa
                            ? 'Conta de empresa/parceiro'
                            : 'Conta de tutor'))),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: _estatistica(Icons.favorite_border,
                          '${s.favoritos.length}', 'Favoritos')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _estatistica(Icons.star_border,
                          '$minhasAvaliacoes', 'Avaliações')),
                ]),
                const SizedBox(height: 28),
                Text('Dados da conta',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: u.email,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: nomeAlterado && !_salvandoNome ? _salvarNome : null,
                  child: Text(_salvandoNome ? 'Salvando...' : 'Salvar nome'),
                ),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Alterar senha'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    children: [
                      _campoSenha(_senhaAtual, 'Senha atual'),
                      _campoSenha(_novaSenha, 'Nova senha (mínimo de 6)'),
                      _campoSenha(_confirmaSenha, 'Confirmar nova senha'),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _trocandoSenha ? null : _trocarSenha,
                          child: Text(
                              _trocandoSenha ? 'Aguarde...' : 'Alterar senha'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: _sair,
                  child: const Text('Sair'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
