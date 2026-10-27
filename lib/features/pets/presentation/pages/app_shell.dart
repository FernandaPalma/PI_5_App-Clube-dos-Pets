import 'package:flutter/material.dart';
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
const petHeroPhoto = 'assets/hero-pet.jpg';
const petLogoPhoto = 'assets/logo.jpeg';

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
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(petLogoPhoto,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.pets,
                            color: petPrimary, size: 36))),
                const SizedBox(width: 9),
                Text(screenWidth < 440 ? 'Clube Pets' : 'Clube dos Pets',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: petDark,
                        fontSize: 20)),
              ]),
            )),
        actions: [
          if (wide) ...[
            _navButton('Início', 0),
            _navButton('Explorar', 1),
            _navButton('Mapa', 2),
            _navButton('Favoritos', 3),
            TextButton(
                onPressed: () => _planos(context), child: const Text('Planos')),
            TextButton(
                onPressed: () => _novoLugar(context),
                child: const Text('Sou empresa')),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _conta(context, s),
              icon: Icon(
                  s.usuario == null
                      ? Icons.login
                      : Icons.account_circle_outlined,
                  size: 19),
              label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 115),
                  child: Text(s.usuario?.nome ?? 'Entrar',
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
            ),
            if (s.usuario == null) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                  onPressed: () => _conta(context, s),
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: const Text('Criar conta')),
            ],
            const SizedBox(width: 24),
          ] else ...[
            PopupMenuButton<String>(
              tooltip: 'Abrir menu',
              icon: const Icon(Icons.menu_rounded),
              onSelected: (value) {
                if (value == 'empresa') _novoLugar(context);
                if (value == 'planos') _planos(context);
                if (value == 'conta') _conta(context, s);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'planos', child: Text('Planos')),
                const PopupMenuItem(
                    value: 'empresa', child: Text('Sou empresa')),
                PopupMenuItem(
                    value: 'conta',
                    child: Text(s.usuario == null
                        ? 'Entrar / criar conta'
                        : 'Minha conta')),
              ],
            ),
            const SizedBox(width: 5),
          ],
        ],
      ),
      body: s.loading
          ? const Center(child: CircularProgressIndicator())
          : s.erro != null
              ? Center(child: Text(s.erro!))
              : IndexedStack(index: tab, children: [
                  _inicio(s, heroWide),
                  _explorar(s, filtrados, categorias, wide),
                  _mapa(s, wide),
                  _lista(s, favoritos, true, wide),
                ]),
      floatingActionButton: (tab == 1 && s.usuario != null)
          ? FloatingActionButton.extended(
              onPressed: () => _novoLugar(context),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Cadastrar local'))
          : null,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: _navegar,
              destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Início'),
                  NavigationDestination(
                      icon: Icon(Icons.search), label: 'Explorar'),
                  NavigationDestination(
                      icon: Icon(Icons.map_outlined), label: 'Mapa'),
                  NavigationDestination(
                      icon: Icon(Icons.favorite_border), label: 'Favoritos'),
                ]),
    );
  }

  Widget _navButton(String label, int target) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextButton(
          onPressed: () => _navegar(target),
          style: TextButton.styleFrom(
              backgroundColor: tab == target ? const Color(0xffeaf6f7) : null,
              foregroundColor: tab == target ? petPrimary : petMuted),
          child: Text(label)));

  Widget _inicio(PetsState s, bool wide) => ListView(children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: wide ? 70 : 22, vertical: wide ? 74 : 48),
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
            Color(0xfff0fbf6),
            Color(0xffe7f6f7),
            Color(0xffe8f3f9)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Flex(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      children: [
                        ExpandedOrBox(
                            wide: wide,
                            flex: 11,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _pill('✦  Pet friendly, simples e seguro'),
                                  const SizedBox(height: 23),
                                  Text(
                                      'Encontre lugares que recebem seu pet de verdade.',
                                      style: TextStyle(
                                          color: petDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: wide ? 72 : 39,
                                          height: .99,
                                          letterSpacing: -2.8)),
                                  const SizedBox(height: 20),
                                  const Text(
                                      'Busque hotéis, clínicas, parques, shoppings e restaurantes com informações centralizadas, avaliações reais e localização para decidir com mais confiança.',
                                      style: TextStyle(
                                          color: petMuted,
                                          fontSize: 17,
                                          height: 1.7)),
                                  const SizedBox(height: 26),
                                  _campoBusca(hero: true),
                                  const SizedBox(height: 17),
                                  Wrap(spacing: 10, runSpacing: 10, children: [
                                    FilledButton(
                                        onPressed: () => _navegar(1),
                                        child:
                                            const Text('Ver estabelecimentos')),
                                    OutlinedButton(
                                        onPressed: () => _planos(context),
                                        child: const Text('Conhecer planos')),
                                    OutlinedButton.icon(
                                        onPressed: () => _navegar(2),
                                        icon: const Icon(
                                            Icons.location_on_outlined),
                                        label: const Text(
                                            'Usar localização atual')),
                                  ])
                                ])),
                        SizedBox(width: wide ? 50 : 0, height: wide ? 0 : 30),
                        ExpandedOrBox(
                            wide: wide,
                            flex: 9,
                            child: Container(
                                height: wide ? 500 : 330,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(38),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x2417323a),
                                          blurRadius: 42,
                                          offset: Offset(0, 22))
                                    ]),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(fit: StackFit.expand, children: [
                                  Image.asset(petHeroPhoto,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                              color: petLight,
                                              child: Center(
                                                  child: Icon(Icons.pets,
                                                      size: 140,
                                                      color: petPrimary)))),
                                  Positioned(
                                      left: 18,
                                      right: wide ? 95 : 18,
                                      bottom: 24,
                                      child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: .96),
                                              borderRadius:
                                                  BorderRadius.circular(22)),
                                          child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star,
                                                    color: Color(0xffdba43c)),
                                                SizedBox(width: 9),
                                                Expanded(
                                                    child: Text(
                                                        'Avaliações reais e locais filtrados por categoria',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: petPrimary)))
                                              ])))
                                ]))),
                      ]))),
        ),
        Padding(
            padding:
                EdgeInsets.symmetric(horizontal: wide ? 70 : 22, vertical: 35),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _pill('Como funciona'),
              const SizedBox(height: 8),
              Text('Uma experiência melhor para tutores e empresas.',
                  style: TextStyle(
                      fontSize: wide ? 31 : 25,
                      fontWeight: FontWeight.w900,
                      color: petDark)),
              const SizedBox(height: 20),
              Wrap(spacing: 14, runSpacing: 14, children: [
                _vantagem(Icons.search, 'Busca inteligente',
                    'Encontre locais por cidade e categoria.'),
                _vantagem(Icons.verified_user_outlined, 'Mais confiança',
                    'Consulte avaliações de outros tutores.'),
                _vantagem(Icons.business_outlined, 'Empresas em destaque',
                    'Cadastre seu estabelecimento e apareça para quem procura serviços pet friendly.')
              ])
            ])),
        _secaoDestaque(s, wide),
        const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
                child: Text(
                    '🐾 Clube dos Pets · lugares pet friendly com mais confiança.',
                    style: TextStyle(color: petMuted))))
      ]);

  Widget _pill(String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
          color: petPrimary, borderRadius: BorderRadius.circular(30)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800)));
  Widget _vantagem(IconData icon, String heading, String body) => SizedBox(
      width: 280,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 33, color: petPrimary),
                    const SizedBox(height: 14),
                    Text(heading,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(body, style: const TextStyle(color: petMuted))
                  ]))));

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

  Widget _explorar(
          PetsState s, List<Lugar> locais, List<String> cats, bool wide) =>
      ListView(
          padding:
              EdgeInsets.symmetric(horizontal: wide ? 60 : 17, vertical: 32),
          children: [
            _pill('⌕  Explorar'),
            const SizedBox(height: 13),
            const Text('Estabelecimentos PET friendly',
                style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900, color: petDark)),
            const SizedBox(height: 9),
            const Text(
                'Explore e encontre os melhores serviços para seu PET perto de você.',
                style: TextStyle(color: petMuted, fontSize: 16)),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            if (locais.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child:
                      Center(child: Text('Nenhum estabelecimento encontrado.')))
            else
              _grade(s, locais, wide)
          ]);

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
  String? _imagemCategoria(String categoria) {
    final c = categoria.toLowerCase();
    if (c.contains('parque')) return 'assets/praca1.jpg';
    if (c.contains('vet') || c.contains('clínica')) return 'assets/vet1.jpg';
    if (c.contains('hotel') || c.contains('hosped')) return 'assets/hotel1.jpg';
    if (c.contains('shopping')) return 'assets/shopping.jpg';
    return null;
  }

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
              EdgeInsets.symmetric(horizontal: wide ? 65 : 18, vertical: 35),
          children: [
            Text(soFavoritos ? 'Meus favoritos' : 'Estabelecimentos',
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900, color: petDark)),
            const SizedBox(height: 12),
            if (locais.isEmpty)
              Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(s.usuario == null
                      ? 'Entre para salvar seus lugares favoritos.'
                      : 'Você ainda não salvou favoritos.'))
            else
              _grade(s, locais, wide)
          ]);
  IconData _icone(String c) {
    final a = c.toLowerCase();
    if (a.contains('parque')) return Icons.park;
    if (a.contains('hotel')) return Icons.hotel;
    if (a.contains('vet')) return Icons.medical_services;
    if (a.contains('restaurante')) return Icons.restaurant;
    return Icons.pets;
  }

  Widget _mapa(PetsState s, bool wide) => ListView(
          padding:
              EdgeInsets.symmetric(horizontal: wide ? 70 : 20, vertical: 36),
          children: [
            const Text('Mapa de estabelecimentos',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900, color: petDark)),
            const SizedBox(height: 12),
            const Text(
                'Explore os endereços. Para abrir rotas no mapa externo, é necessária conexão com a internet.',
                style: TextStyle(color: petMuted)),
            const SizedBox(height: 20),
            ...s.lugares.map((l) => Card(
                child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    leading: CircleAvatar(
                        backgroundColor: const Color(0xffeaf6f7),
                        child: Icon(_icone(l.categoria), color: petPrimary)),
                    title: Text(l.nome,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                        '${l.endereco.isEmpty ? l.cidade : l.endereco} • ${l.categoria}'),
                    trailing: const Icon(Icons.directions, color: petPrimary),
                    onTap: () => _rota(l))))
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

class ExpandedOrBox extends StatelessWidget {
  const ExpandedOrBox(
      {required this.wide, required this.flex, required this.child, super.key});
  final bool wide;
  final int flex;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      wide ? Expanded(flex: flex, child: child) : child;
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
          Container(
              height: 140,
              decoration: BoxDecoration(
                  color: const Color(0xffdcefe9),
                  borderRadius: BorderRadius.circular(20)),
              child:
                  const Icon(Icons.pets, size: 72, color: Color(0xff087c70))),
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
          Text('Avaliações (${avs.length})',
              style: Theme.of(context).textTheme.titleLarge),
          ...avs.map((a) => Card(
              child: ListTile(
                  title: Text('${a.autor} • ${'★' * a.nota}'),
                  subtitle: Text(a.comentario.isEmpty
                      ? 'Sem comentário'
                      : a.comentario)))),
          if (s.usuario != null) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
                initialValue: nota,
                decoration: const InputDecoration(labelText: 'Sua nota'),
                items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                        value: i + 1, child: Text('${i + 1} estrela(s)'))),
                onChanged: (v) => setState(() => nota = v ?? 5)),
            const SizedBox(height: 10),
            TextField(
                controller: comentario,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Seu comentário')),
            const SizedBox(height: 10),
            FilledButton(
                onPressed: () async {
                  await ref
                      .read(appProvider.notifier)
                      .avaliar(l.id, nota, comentario.text);
                  comentario.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Avaliação salva localmente.')));
                  }
                },
                child: const Text('Salvar avaliação'))
          ] else
            const Text('Entre na sua conta para avaliar este local.')
        ]));
  }
}

class ContaPage extends ConsumerStatefulWidget {
  const ContaPage({super.key});
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
      if (mounted) Navigator.pop(context);
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
        appBar: AppBar(title: Text(u == null ? 'Minha conta' : 'Perfil')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ListView(
                    padding: const EdgeInsets.all(24),
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
