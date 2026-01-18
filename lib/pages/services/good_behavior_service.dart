import 'dart:async';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;
import 'package:profanity_filter/profanity_filter.dart';

class GoodBehaviorService {
  static final GoodBehaviorService list = GoodBehaviorService._internal();
  
  factory GoodBehaviorService() => list;
  GoodBehaviorService._internal();
  ProfanityFilter? filter;
  List<String> listOfCriticalWords = [];

  Future<void> loadBadWords() async {
    List<String> allBadWords = [];

    //load asset manifest
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();


    //filter bad word files from folder
    final badWordFiles = allAssets
        .where((key) => key.contains('bad_words/') || key.contains('word-library/'))
        .toList();

    //read each bad word file and add words to list
    for (final path in badWordFiles) {
      final String content = await rootBundle.loadString(path);
      final List<String> words = content
          .split('\n')
          .map((w) => w.trim())
          .where((w) => w.isNotEmpty)
          .toList();  
          
      allBadWords.addAll(words);
    }


    //Manually add critical words
    //this is to ensure some words are always included (for example, PT file only have pt-br words)
    allBadWords.addAll(_getManualCriticalWords());

    //manage filter of manual loaded words
    filter = ProfanityFilter.filterAdditionally(allBadWords);
    
    //normalize all words for robust checking (like removing accents, special chars, etc)
    listOfCriticalWords = allBadWords.map((w) => _normalizeText(w)).toList();
  }

  bool isOffensive(String text) {
    //Verification of bad words in text input
    if (text.length < 500) {
      String hiddenWords = _normalizeText(text);
      for (final badWord in listOfCriticalWords) {
        if (badWord.length < 3) continue; 
        if (hiddenWords.contains(badWord)) return true;
      }
    }
    return false;
  }

  //normalize text by removing accents and special characters
  String _normalizeText(String text) {
    String clean = text.toLowerCase();
    clean = clean.replaceAll(RegExp(r'[àáâãäå]'), 'a');
    clean = clean.replaceAll(RegExp(r'[èéêë]'), 'e');
    clean = clean.replaceAll(RegExp(r'[ìíîï]'), 'i');
    clean = clean.replaceAll(RegExp(r'[òóôõö]'), 'o');
    clean = clean.replaceAll(RegExp(r'[ùúûü]'), 'u');
    clean = clean.replaceAll(RegExp(r'[ç]'), 'c');
    clean = clean.replaceAll(RegExp(r'[ñ]'), 'n');
    clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return clean;
  }

  //Manually defined critical words to ensure they are always included
  List<String> _getManualCriticalWords() {
    return [
      // PT
      "caralho", "merda", "puta", "cabrao", "foda-se", "fodase", 
      "paneleiro", "cona", "pila", "fudido", "idiota", "estupido", 
      "pissolho", "fodasse", "piroca", "chupa", "corno", "fds",
      "picha", "pixa", "buceta", "bosta", "otario", "viado",
      // EN (Adicionadas agora para garantir que funcionam já)
      "bitch", "nudity", "nude", "sex", "fuck", "shit", "asshole", "dick"
    ];
  }
}