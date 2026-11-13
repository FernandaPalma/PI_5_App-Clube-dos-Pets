import 'package:flutter/material.dart';
import 'package:five_pointed_star/five_pointed_star.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/pets_entities.dart';
import '../../../../core/di/providers.dart';
import '../controllers/pets_controller.dart';

const petPrimary = Color(0xff1f6f78);
const petDark = Color(0xff17323a);
const petBlue = Color(0xff4da8da);
const petMuted = Color(0xff62737c);
const petLight = Color(0xffeaf6f7);
const petStar = Color(0xffd8a03c);
const petHeroPhoto = 'assets/hero-pet.jpg';
const petLogoPhoto = 'assets/logo.jpeg';

/// Primeira letra do nome, para avatares.
String inicialDe(String nome) =>
    nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();

/// Imagens por categoria (adicione arquivos em assets/ para ampliar o carrossel).
List<String> imagensDaCategoria(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('parque')) return ['assets/praca1.jpg'];
  if (c.contains('vet') || c.contains('clínica')) {
    return [
      'assets/vet1.jpg',
      'assets/vet2.jpeg',
      'assets/vet3.jpg',
      'assets/vet4.jpg',
      'assets/vet5.jpg',
    ];
  }
  if (c.contains('hotel') || c.contains('hosped')) return ['assets/hotel1.jpg'];
  if (c.contains('shopping')) {
    return ['assets/shopping.jpg', 'assets/shopping2.jpg'];
  }
  return [];
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int tab = 0;
  String busca = '';
  String categoria = 'Todas';
  final _buscaController = TextEditingController();
  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _navegar(int next) => setState(() => tab = next);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider);
    // Primeira tela: login. Ao entrar, o estado atualiza e o app abre sozinho.
    if (!s.loading && s.erro == null && s.usuario == null) {
      return const ContaPage(entrada: true);
    }
    final screenWidth = MediaQuery.sizeOf(context).width;
    // A navegação completa precisa de espaço para a marca e as ações.
    final wide = screenWidth >= 1350;
    final heroWide = screenWidth >= 950;
    final categorias = ['Todas', ...s.lugares.map((e) => e.categoria).toSet()];
    if (!categorias.contains(categoria)) categoria = 'Todas';
    final filtrados = s.lugares
        .where((e) =>
            (categoria == 'Todas' || e.categoria == categoria) &&
            ('${e.nome} ${e.cidade} ${e.categoria} ${e.descricao}'
                .toLowerCase()
                .contains(busca.trim().toLowerCase())))
        .toList();
    final favoritos =
        s.lugares.where((e) => s.favoritos.contains(e.id)).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfff7f9fa),
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 76,
        titleSpacing: wide ? 36 : 16,
        title: SizedBox(
            width: wide ? 225 : (screenWidth < 380 ? 150 : 200),
            child: InkWell(
              onTap: () => _navegar(0),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(screenWidth < 440 ? 'Clube Pets' : 'Clube dos Pets',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: petDark,
                          fontSize: 20)),
                ),
              ]),
            )),
      ),
      drawer: _drawer(s),
      body: s.loading
          ? const Center(child: CircularProgressIndicator())
          : s.erro != null
              ? Center(child: Text(s.erro!))
              : IndexedStack(index: tab, children: [
                  _inicio(s, heroWide),
                  _locais(s, filtrados, categorias, wide),
                  _lista(s, favoritos, true, wide),
                ]),
      bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: _navegar,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Início'),
            NavigationDestination(
                icon: Icon(Icons.pets_outlined), label: 'Locais'),
            NavigationDestination(
                icon: Icon(Icons.favorite_border), label: 'Favoritos'),
          ]),
    );
  }

  Drawer _drawer(PetsState s) {
    final u = s.usuario;
    Widget item(IconData icon, String texto, VoidCallback onTap,
            {bool selected = false}) =>
        ListTile(
            leading: Icon(icon),
            title: Text(texto),
            selected: selected,
            selectedColor: petPrimary,
            selectedTileColor: petLight,
            onTap: () {
              Navigator.pop(context);
              onTap();
            });

    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      UserAccountsDrawerHeader(
          decoration: const BoxDecoration(color: petPrimary),
          accountName: Text(u?.nome ?? '',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          accountEmail: Text(u?.email ?? ''),
          currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(inicialDe(u?.nome ?? ''),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: petPrimary)))),
      item(Icons.account_circle_outlined, 'Meu perfil',
          () => _conta(context, s)),
      item(Icons.workspace_premium_outlined, 'Planos', () => _planos(context)),
      item(Icons.add_business_outlined, 'Sou empresa',
          () => _novoLugar(context)),
      const Divider(),
      item(Icons.logout, 'Sair', () => ref.read(appProvider.notifier).sair()),
    ]));
  }

  Widget _inicio(PetsState s, bool wide) =>
      ListView(children: [_secaoDestaque(s, wide)]);

  Widget _secaoDestaque(PetsState s, bool wide) => Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 70 : 22, vertical: 36),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('Explore lugares pet friendly',
                  style: TextStyle(
                      color: petDark,
                      fontSize: 27,
                      fontWeight: FontWeight.w900))),
          TextButton(
              onPressed: () => _navegar(1), child: const Text('Ver todos →'))
        ]),
        const SizedBox(height: 14),
        _grade(s, s.lugares.take(6).toList(), wide),
      ]));
  Widget _campoBusca({bool hero = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffd7e8e9)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x120f4248), blurRadius: 24, offset: Offset(0, 9))
          ]),
      child: Row(children: [
        const Icon(Icons.search, color: petPrimary),
        const SizedBox(width: 8),
        Expanded(
            child: TextField(
                controller: _buscaController,
                onChanged: (v) => setState(() => busca = v),
                onSubmitted: (_) => _navegar(1),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Digite uma cidade, bairro ou região'))),
        FilledButton(
            onPressed: () => _navegar(1),
            child: Text(hero ? 'Buscar' : 'Filtrar'))
      ]));

  Widget _locais(
          PetsState s, List<Lugar> locais, List<String> cats, bool wide) =>
      ListView(
          padding:
              EdgeInsets.symmetric(horizontal: wide ? 60 : 17, vertical: 24),
          children: [
            const Text('Locais',
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w900, color: petDark)),
            const SizedBox(height: 16),
            _campoBusca(),
            const SizedBox(height: 14),
            SizedBox(
                height: 47,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: cats
                        .map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                                label: Text(c),
                                selected: categoria == c,
                                onSelected: (_) =>
                                    setState(() => categoria = c))))
                        .toList())),
            const SizedBox(height: 12),
            if (locais.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('Nenhum local encontrado.')))
            else
              ...locais.map((l) => _cartaoCompacto(s, l)),
          ]);

  Widget _cartaoCompacto(PetsState s, Lugar l) {
    final img = _imagemCategoria(l.categoria);
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
            onTap: () => _detalhes(context, l),
            child: Row(children: [
              // Imagem encostada nas bordas: o card recorta com o mesmo raio.
              SizedBox(
                  width: 104,
                  height: 104,
                  child: img != null
                      ? Image.asset(img, fit: BoxFit.cover)
                      : const ColoredBox(
                          color: petLight,
                          child: Center(
                              child: Icon(Icons.pets_outlined,
                                  color: petPrimary)))),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: petDark)),
                            const SizedBox(height: 3),
                            Text('${l.categoria} • ${l.cidade}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: petMuted, fontSize: 13)),
                            const SizedBox(height: 3),
                            Row(children: [
                              const Icon(Icons.star, size: 15, color: petStar),
                              const SizedBox(width: 3),
                              Text(s.nota(l.id).toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 13))
                            ]),
                          ]))),
              Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton.filledTonal(
                      tooltip: 'Traçar rota',
                      onPressed: () => _rota(l),
                      icon: const Icon(Icons.directions_outlined,
                          color: petPrimary))),
            ])));
  }

  Widget _grade(PetsState s, List<Lugar> locais, bool wide) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 950
            ? 3
            : constraints.maxWidth > 550
                ? 2
                : 1;
        return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locais.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                mainAxisExtent: 355),
            itemBuilder: (context, index) => _cartao(s, locais[index]));
      });
  String? _imagemCategoria(String categoria) =>
      imagensDaCategoria(categoria).firstOrNull;

  Widget _cartao(PetsState s, Lugar l) => Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
          onTap: () => _detalhes(context, l),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                height: 205,
                width: double.infinity,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xffeaf6f7), Color(0xfff0fbf6)])),
                child: Stack(children: [
                  if (_imagemCategoria(l.categoria) != null)
                    Positioned.fill(
                        child: Image.asset(_imagemCategoria(l.categoria)!,
                            fit: BoxFit.cover))
                  else
                    const Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.image_not_supported_outlined,
                          size: 33, color: petPrimary),
                      SizedBox(height: 7),
                      Text('Foto pendente',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: petPrimary))
                    ])),
                  Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30)),
                          child: Text(l.categoria,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: petPrimary)))),
                  Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton.filledTonal(
                          onPressed: () => _favoritar(l.id),
                          icon: Icon(
                              s.favoritos.contains(l.id)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: s.favoritos.contains(l.id)
                                  ? Colors.red
                                  : petPrimary)))
                ])),
            Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(l.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: petDark))),
                        const Icon(Icons.star,
                            size: 17, color: Color(0xffd8a03c)),
                        Text(s.nota(l.id).toStringAsFixed(1))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          l.descricao.isEmpty
                              ? 'Local cadastrado para receber tutores e pets com mais praticidade.'
                              : l.descricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: petMuted, height: 1.4)),
                      const SizedBox(height: 13),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 17, color: petPrimary),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(l.cidade,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: petMuted)))
                      ])
                    ]))
          ])));

  Widget _lista(PetsState s, List<Lugar> locais, bool soFavoritos, bool wide) =>
      ListView(
          padding:
              EdgeInsets.symmetric(horizontal: wide ? 60 : 17, vertical: 24),
          children: [
            Text(soFavoritos ? 'Meus favoritos' : 'Locais',
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w900, color: petDark)),
            const SizedBox(height: 16),
            if (locais.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: Text('Você ainda não salvou favoritos.')))
            else
              ...locais.map((l) => _cartaoCompacto(s, l)),
          ]);

  Future<void> _rota(Lugar l) async {
    final text = Uri.encodeComponent(
        l.endereco.isNotEmpty ? l.endereco : '${l.nome}, ${l.cidade}');
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$text');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      _erro('Não foi possível abrir o mapa.');
    }
  }

  void _erro(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _favoritar(String id) async {
    try {
      await ref.read(appProvider.notifier).favorito(id);
    } catch (e) {
      _erro('$e');
    }
  }

  void _detalhes(BuildContext context, Lugar l) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => DetalhesPage(lugar: l)));
  }

  void _conta(BuildContext context, PetsState s) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ContaPage()));
  }

  void _novoLugar(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const NovoLugarPage()));
  }

  void _planos(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PlanosPage()));
  }
}

/// Carrossel de imagens do local (arraste para o lado).
class GaleriaLugar extends StatefulWidget {
  const GaleriaLugar({required this.imagens, super.key});
  final List<String> imagens;
  @override
  State<GaleriaLugar> createState() => _GaleriaLugarState();
}

class _GaleriaLugarState extends State<GaleriaLugar> {
  final _controller = PageController();
  int _atual = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _vazio = ColoredBox(
      color: petLight,
      child: Center(child: Icon(Icons.pets_outlined, size: 72, color: petPrimary)));

  @override
  Widget build(BuildContext context) {
    final imagens = widget.imagens;
    return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
            height: 280,
            child: imagens.isEmpty
                ? _vazio
                : Stack(fit: StackFit.expand, children: [
                    PageView.builder(
                        controller: _controller,
                        itemCount: imagens.length,
                        onPageChanged: (i) => setState(() => _atual = i),
                        itemBuilder: (_, i) => Image.asset(imagens[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _vazio)),
                    if (imagens.length > 1)
                      Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < imagens.length; i++)
                                  AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: i == _atual ? 18 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                          color: i == _atual
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: .55),
                                          borderRadius:
                                              BorderRadius.circular(8))),
                              ])),
                  ])));
  }
}

class DetalhesPage extends ConsumerStatefulWidget {
  const DetalhesPage({required this.lugar, super.key});
  final Lugar lugar;
  @override
  ConsumerState<DetalhesPage> createState() => _DetalhesPageState();
}

class _DetalhesPageState extends ConsumerState<DetalhesPage> {
  final comentario = TextEditingController();
  int nota = 5;

  Future<void> _publicar(String lugarId) async {
    try {
      await ref
          .read(appProvider.notifier)
          .avaliar(lugarId, nota, comentario.text);
      comentario.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// Comentário no estilo Instagram: avatar, nome em negrito + texto na mesma linha.
  Widget _comentario(Avaliacao a) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
            radius: 18,
            backgroundColor: petLight,
            child: Text(inicialDe(a.autor),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: petPrimary))),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(children: [
            TextSpan(
                text: a.autor,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: petDark)),
            TextSpan(
                text: a.comentario.isEmpty
                    ? '  avaliou este local'
                    : '  ${a.comentario}'),
          ])),
          const SizedBox(height: 4),
          IgnorePointer(
              child: FivePointedStar(
                  key: ValueKey('c-${a.id}-${a.nota}'),
                  count: 5,
                  size: const Size(13, 13),
                  gap: 2,
                  selectedColor: petStar,
                  defaultSelectedCount: a.nota)),
        ])),
      ]));

  @override
  void dispose() {
    comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appProvider),
        l = widget.lugar,
        avs = s.avaliacoes.where((a) => a.lugarId == l.id).toList();
    return Scaffold(
        appBar: AppBar(title: Text(l.nome)),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          GaleriaLugar(imagens: imagensDaCategoria(l.categoria)),
          const SizedBox(height: 20),
          Text(l.nome, style: Theme.of(context).textTheme.headlineMedium),
          Text('${l.categoria} • ${l.cidade}'),
          const SizedBox(height: 10),
          Text(l.descricao.isEmpty ? 'Sem descrição cadastrada.' : l.descricao),
          if (l.endereco.isNotEmpty)
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(l.endereco)),
          if (l.telefone.isNotEmpty)
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone),
                title: Text(l.telefone)),
          FilledButton.icon(
              onPressed: () async {
                try {
                  await ref.read(appProvider.notifier).favorito(l.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              icon: Icon(s.favoritos.contains(l.id)
                  ? Icons.favorite
                  : Icons.favorite_border),
              label: Text(s.favoritos.contains(l.id)
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos')),
          const SizedBox(height: 18),
          Row(children: [
            Text(s.nota(l.id).toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: petDark)),
            const SizedBox(width: 10),
            IgnorePointer(
                child: FivePointedStar(
                    key: ValueKey('media-${s.nota(l.id).round()}'),
                    count: 5,
                    size: const Size(22, 22),
                    gap: 3,
                    selectedColor: petStar,
                    defaultSelectedCount: s.nota(l.id).round())),
            const SizedBox(width: 10),
            Text('${avs.length} comentário(s)',
                style: const TextStyle(color: petMuted)),
          ]),
          const Divider(height: 32),
          if (avs.isEmpty)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Ainda não há comentários. Seja o primeiro!',
                    style: TextStyle(color: petMuted)))
          else
            ...avs.map(_comentario),
          const Divider(height: 32),
          if (s.usuario != null) ...[
            const Text('Sua nota',
                style: TextStyle(fontWeight: FontWeight.w800, color: petDark)),
            const SizedBox(height: 8),
            FivePointedStar(
                count: 5,
                size: const Size(34, 34),
                gap: 8,
                selectedColor: petStar,
                defaultSelectedCount: nota,
                onChange: (v) => setState(() => nota = v < 1 ? 1 : v)),
            const SizedBox(height: 12),
            Row(children: [
              CircleAvatar(
                  radius: 18,
                  backgroundColor: petLight,
                  child: Text(inicialDe(s.usuario!.nome),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: petPrimary))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: comentario,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Adicione um comentário...',
                          border: InputBorder.none,
                          isDense: true))),
              TextButton(
                  onPressed: () => _publicar(l.id),
                  child: const Text('Publicar')),
            ]),
          ] else
            const Text('Entre na sua conta para comentar.'),
        ]));
  }
}

class ContaPage extends ConsumerStatefulWidget {
  const ContaPage({this.entrada = false, super.key});
  final bool entrada;
  @override
  ConsumerState<ContaPage> createState() => _ContaPageState();
}

class _ContaPageState extends ConsumerState<ContaPage> {
  final nome = TextEditingController(),
      email = TextEditingController(),
      senha = TextEditingController();
  bool cadastro = false, processando = false;
  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => processando = true);
    try {
      if (cadastro) {
        await ref
            .read(appProvider.notifier)
            .cadastrar(nome.text, email.text, senha.text);
      } else {
        await ref.read(appProvider.notifier).login(email.text, senha.text);
      }
      if (mounted && !widget.entrada) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(appProvider).usuario;
    return Scaffold(
        appBar: widget.entrada
            ? null
            : AppBar(title: Text(u == null ? 'Minha conta' : 'Perfil')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ListView(
                    padding: EdgeInsets.fromLTRB(24, widget.entrada ? 72 : 24, 24, 24),
                    children: u != null
                        ? [
                            const Icon(Icons.account_circle, size: 70),
                            const SizedBox(height: 16),
                            Text(u.nome,
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            Text(u.email, textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            FilledButton.tonal(
                                onPressed: () async {
                                  await ref.read(appProvider.notifier).sair();
                                  if (context.mounted) Navigator.pop(context);
                                },
                                child: const Text('Sair'))
                          ]
                        : [
                            const Icon(Icons.pets,
                                size: 65, color: Color(0xff087c70)),
                            const SizedBox(height: 10),
                            Text(
                                cadastro
                                    ? 'Crie sua conta'
                                    : 'Bem-vindo de volta!',
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 20),
                            if (cadastro) ...[
                              TextField(
                                  controller: nome,
                                  decoration: const InputDecoration(
                                      labelText: 'Nome completo')),
                              const SizedBox(height: 12)
                            ],
                            TextField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                decoration:
                                    const InputDecoration(labelText: 'E-mail')),
                            const SizedBox(height: 12),
                            TextField(
                                controller: senha,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText:
                                        'Senha (mínimo de 6 caracteres)')),
                            const SizedBox(height: 18),
                            FilledButton(
                                onPressed: processando ? null : _enviar,
                                child: Text(processando
                                    ? 'Aguarde...'
                                    : cadastro
                                        ? 'Criar conta'
                                        : 'Entrar')),
                            TextButton(
                                onPressed: () =>
                                    setState(() => cadastro = !cadastro),
                                child: Text(cadastro
                                    ? 'Já tenho uma conta'
                                    : 'Ainda não tenho conta'))
                          ]))));
  }
}

class NovoLugarPage extends ConsumerStatefulWidget {
  const NovoLugarPage({super.key});
  @override
  ConsumerState<NovoLugarPage> createState() => _NovoLugarPageState();
}

class _NovoLugarPageState extends ConsumerState<NovoLugarPage> {
  final nome = TextEditingController(),
      cidade = TextEditingController(),
      descricao = TextEditingController(),
      endereco = TextEditingController(),
      telefone = TextEditingController();
  String categoria = 'Parques';
  bool processando = false;
  @override
  void dispose() {
    for (final c in [nome, cidade, descricao, endereco, telefone]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Cadastrar estabelecimento')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: ListView(padding: const EdgeInsets.all(18), children: [
                const Text(
                    'O estabelecimento será salvo neste dispositivo/navegador.'),
                const SizedBox(height: 15),
                TextField(
                    controller: nome,
                    decoration: const InputDecoration(labelText: 'Nome *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: const [
                      'Parques',
                      'Veterinários',
                      'Hotéis pet',
                      'Restaurantes',
                      'Pet shops',
                      'Outros'
                    ]
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => categoria = v ?? categoria)),
                const SizedBox(height: 12),
                TextField(
                    controller: cidade,
                    decoration: const InputDecoration(labelText: 'Cidade *')),
                const SizedBox(height: 12),
                TextField(
                    controller: endereco,
                    decoration: const InputDecoration(labelText: 'Endereço')),
                const SizedBox(height: 12),
                TextField(
                    controller: telefone,
                    decoration: const InputDecoration(labelText: 'Telefone')),
                const SizedBox(height: 12),
                TextField(
                    controller: descricao,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descrição')),
                const SizedBox(height: 20),
                FilledButton.icon(
                    onPressed: processando
                        ? null
                        : () async {
                            setState(() => processando = true);
                            try {
                              await ref
                                  .read(appProvider.notifier)
                                  .cadastrarLugar(
                                      nome: nome.text,
                                      categoria: categoria,
                                      cidade: cidade.text,
                                      descricao: descricao.text,
                                      endereco: endereco.text,
                                      telefone: telefone.text);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$e')));
                              }
                            } finally {
                              if (mounted) setState(() => processando = false);
                            }
                          },
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar estabelecimento'))
              ]))));
}

/// Apresentação dos planos do projeto React. Valores e contratação serão
/// habilitados somente quando a integração com Supabase e pagamentos existir.
class PlanosPage extends StatelessWidget {
  const PlanosPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Planos')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Text(
              'Planos para empresas que querem ser encontradas por tutores.',
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w900, color: petDark)),
          const SizedBox(height: 8),
          const Text(
              'Comece com um perfil gratuito e evolua para opções de destaque, reputação e visibilidade regional. Contratações em breve.',
              style: TextStyle(color: petMuted)),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final items = [
              _plano('Free', 'R\$ 0', Icons.verified_outlined, [
                'Perfil público do estabelecimento',
                'Foto, endereço e categoria',
                'Recebimento de avaliações',
                'Resposta às avaliações'
              ]),
              _plano('Premium', 'R\$ 39,90', Icons.star_outline, [
                'Mais destaque nas buscas',
                'Perfil enriquecido',
                'Galeria de fotos ampliada',
                'Selo de empresa verificada'
              ]),
              _plano(
                  'Destaque Local', 'R\$ 79,90', Icons.rocket_launch_outlined, [
                'Prioridade por região',
                'Campanhas sazonais',
                'Relatórios de interesse',
                'Publicidade nativa para tutores'
              ]),
            ];
            return compact
                ? Column(
                    children: items
                        .map((x) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: x))
                        .toList())
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map((x) => Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 7),
                                child: x)))
                        .toList());
          }),
        ]),
      );
  static Widget _plano(String nome, String descricao, IconData icon,
          List<String> beneficios) =>
      Card(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: petPrimary, size: 35),
              const SizedBox(height: 18),
              Text(nome,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: petDark)),
              const SizedBox(height: 6),
              Text(descricao, style: const TextStyle(color: petMuted)),
              const SizedBox(height: 15),
              ...beneficios.map((x) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: petPrimary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(x))
                  ]))),
              const SizedBox(height: 15),
              const FilledButton(onPressed: null, child: Text('Em breve')),
            ])),
      );
}