import 'package:profanity_filter/profanity_filter.dart';

class GoodBehaviorService {
  final ProfanityFilter _filter;

  GoodBehaviorService() : _filter = ProfanityFilter.filterAdditionally(_getMultilingualBadWords());

  /// Verifica se o texto contém ofensas (Modo Robusto)
  bool isOffensive(String text) {
    // 1. Verificação Padrão (Apanha palavras isoladas)
    if (_filter.hasProfanity(text)) return true;

    // 2. Normalização para apanhar "escondidos" (ex: joaofoda-se -> joaofodase)
    String normalized = _normalizeText(text);
    
    // Lista de palavras críticas que queremos apanhar mesmo que estejam coladas a outras
    final criticalWords = _getMultilingualBadWords();

    for (final badWord in criticalWords) {
      // Normaliza também a palavra proibida para comparar (ex: "foda-se" -> "fodase")
      String cleanBadWord = _normalizeText(badWord);
      
      // Se o texto normalizado contiver a asneira
      if (normalized.contains(cleanBadWord)) {
        return true;
      }
    }

    return false;
  }

  /// Remove acentos, símbolos e põe em minúsculas
  String _normalizeText(String text) {
    String clean = text.toLowerCase();
    
    // Remove acentos manuais básicos (pode-se usar package diacritic se quiseres algo mais avançado)
    clean = clean.replaceAll(RegExp(r'[àáâãäå]'), 'a');
    clean = clean.replaceAll(RegExp(r'[èéêë]'), 'e');
    clean = clean.replaceAll(RegExp(r'[ìíîï]'), 'i');
    clean = clean.replaceAll(RegExp(r'[òóôõö]'), 'o');
    clean = clean.replaceAll(RegExp(r'[ùúûü]'), 'u');
    clean = clean.replaceAll(RegExp(r'[ç]'), 'c');
    clean = clean.replaceAll(RegExp(r'[ñ]'), 'n');

    // Remove tudo o que não for letra ou número (hífens, pontos, espaços, etc.)
    // Assim "foda-se" vira "fodase" e "joao.merda" vira "joaomerda"
    clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    return clean;
  }

  String censorText(String text) {
    return _filter.censor(text); 
  }

  bool validateInput(String text) {
    if (text.trim().isEmpty) return false;
    return !isOffensive(text);
  }

  // --- LISTA MULTILÍNGUE (Adicionei versões sem hífen também para garantir) ---
  static List<String> _getMultilingualBadWords() {
    return [
      // --- PORTUGUÊS (PT/BR) ---
      "caralho", "merda", "puta", "cabrao", "cabrão", "foda-se", "fodase", "foder", 
      "paneleiro", "cona", "pila", "fudido", "idiota", "estupido", "burro", 
      "pissolho", "caralhos", "putas", "fodasse", "piroca", "chupa", "corno", "fds",
      "picha", "pixa", "buceta", "bosta", "otario", "otário", "viado", "viada",

      // --- ESPANHOL (ES) ---
      "mierda", "puta", "cabron", "cabrón", "joder", "gilipollas", "coño", 
      "pendejo", "pinche", "verga", "chinga", "maricon", "maricón", "culero",
      "hijo de puta", "follar", "hostia",

      // --- FRANCÊS (FR) ---
      "merde", "putain", "connard", "connasse", "salope", "enculé", "fils de pute",
      "batard", "bâtard", "con", "foutre", "bite", "couille", "bordel",

      // --- ALEMÃO (DE) ---
      "scheisse", "scheiße", "arschloch", "schlampe", "hure", "ficken", 
      "verdammt", "mist", "wichser", "bastard", "fotze", "depp", "idiot",

      // --- ITALIANO (IT) ---
      "merda", "cazzo", "vaffanculo", "stronzo", "troia", "puttana", "figa", 
      "culo", "bastardo", "coglione", "porca", "porco", "frocio", "porcodio", 
      "porcamadonna", "mannaggia a cristo", "diocane", "madonna puttana" 

      // --- VARIAÇÕES COMUNS ---
      "f0da", "m3rda", "p*ta", "sh1t", "fvck", "b1tch", "p0rco", "c4zzo", "p0rc0"
    ];
  }
}