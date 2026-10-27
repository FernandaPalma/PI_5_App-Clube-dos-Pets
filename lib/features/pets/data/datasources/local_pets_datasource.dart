import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/pets_entities.dart';
import '../models/pets_models.dart';


class LocalPetsDataSource {
  static const _lugaresKey='pets_lugares_v2',_usuariosKey='pets_usuarios_v2',_favoritosKey='pets_favoritos_v2',_avaliacoesKey='pets_avaliacoes_v2',_sessaoKey='pets_sessao_v2';
  Future<SharedPreferences> get _prefs=>SharedPreferences.getInstance();
  Future<List<Map<String,dynamic>>> _get(String key) async {final s=(await _prefs).getString(key);if(s==null)return [];return (jsonDecode(s) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();}
  Future<void> _put(String key,List<Map<String,dynamic>> value) async {await (await _prefs).setString(key,jsonEncode(value));}
  Future<void> seed()async {final p=await _prefs;if(p.containsKey(_lugaresKey))return;await _put(_lugaresKey,[
    LugarModel.toJson(const Lugar(id:'demo1',nome:'Parque dos Amigos',categoria:'Parques',cidade:'São Paulo',descricao:'Área verde e espaço para passear com seu pet.',endereco:'São Paulo - SP')),
    LugarModel.toJson(const Lugar(id:'demo2',nome:'Clínica Patinhas',categoria:'Veterinários',cidade:'Campinas',descricao:'Consultas e cuidados veterinários.',endereco:'Campinas - SP')),
    LugarModel.toJson(const Lugar(id:'demo3',nome:'Hotel AuMiau',categoria:'Hotéis pet',cidade:'Rio Claro',descricao:'Hospedagem e recreação para cães e gatos.',endereco:'Rio Claro - SP')),
    LugarModel.toJson(const Lugar(id:'demo4',nome:'Café Pet Friendly',categoria:'Restaurantes',cidade:'São Paulo',descricao:'Café com espaço para tutores e seus animais.',endereco:'São Paulo - SP')),
  ]);}
  Future<List<Lugar>> lugares()async=>(await _get(_lugaresKey)).map(LugarModel.fromJson).toList();
  Future<List<Avaliacao>> avaliacoes()async=>(await _get(_avaliacoesKey)).map(AvaliacaoModel.fromJson).toList();
  Future<List<String>> favoritos(String userId)async=>(await _get(_favoritosKey)).where((j)=>j['usuarioId']==userId).map((j)=>'${j['lugarId']}').toList();
  Future<String?> sessao()async=>(await _prefs).getString(_sessaoKey);
  Future<Usuario?> usuarioAtual() async {final id=await sessao();if(id==null)return null;final users=(await _get(_usuariosKey)).map(UsuarioModel.fromJson);for(final u in users){if(u.id==id)return u;}return null;}
  String _hash(String password,String salt)=>sha256.convert(utf8.encode('$salt:$password')).toString();
  String _salt()=>List.generate(24,(_)=>Random.secure().nextInt(256).toRadixString(16).padLeft(2,'0')).join();
  String _id()=>DateTime.now().microsecondsSinceEpoch.toString();
  Future<Usuario> cadastrar(String nome,String email,String senha)async {nome=nome.trim();email=email.trim().toLowerCase();if(nome.length<2||!email.contains('@')||senha.length<6)throw Exception('Informe nome, e-mail válido e senha de pelo menos 6 caracteres.');final list=await _get(_usuariosKey);if(list.any((j)=>j['email']==email))throw Exception('E-mail já cadastrado.');final salt=_salt();final u=Usuario(id:_id(),nome:nome,email:email,senhaHash:_hash(senha,salt),salt:salt);list.add(UsuarioModel.toJson(u));await _put(_usuariosKey,list);await (await _prefs).setString(_sessaoKey,u.id);return u;}
  Future<Usuario> login(String email,String senha)async {final list=(await _get(_usuariosKey)).map(UsuarioModel.fromJson);for(final u in list){if(u.email==email.trim().toLowerCase()&&u.senhaHash==_hash(senha,u.salt)){await (await _prefs).setString(_sessaoKey,u.id);return u;}}throw Exception('E-mail ou senha inválidos.');}
  Future<void> sair() async {await (await _prefs).remove(_sessaoKey);}
  Future<void> toggleFavorito(String userId,String lugarId)async {final list=await _get(_favoritosKey);final ix=list.indexWhere((e)=>e['usuarioId']==userId&&e['lugarId']==lugarId);if(ix>=0){list.removeAt(ix);}else{list.add({'usuarioId':userId,'lugarId':lugarId});}await _put(_favoritosKey,list);}
  Future<void> addLugar(Lugar lugar)async {final list=await _get(_lugaresKey);list.add(LugarModel.toJson(lugar));await _put(_lugaresKey,list);}
  Future<void> avaliar(Avaliacao avaliacao)async {final list=await _get(_avaliacoesKey);list.removeWhere((e)=>e['usuarioId']==avaliacao.usuarioId&&e['lugarId']==avaliacao.lugarId);list.add(AvaliacaoModel.toJson(avaliacao));await _put(_avaliacoesKey,list);}
}
