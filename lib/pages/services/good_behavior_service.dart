import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:profanity_filter/profanity_filter.dart';

class GoodBehaviorService {
  //This opens the dictionary only once when the app starts and reuses it instead of loading it every time we open a different page.
  static final GoodBehaviorService list = GoodBehaviorService._internal();
  
  //Will return the same instance every time it's called, no matter where. In this case, the opened dictionary.
  factory GoodBehaviorService() => list;
  GoodBehaviorService._internal();
  ProfanityFilter? filter;
  List<String> listOfCriticalWords = [];

  ///When the app starts, load all bad words from assets (call it on main.dart)
  Future<void> loadBadWords() async {
    List<String> allBadWords = [];

    try {
      //Reads all the assets of the app
      final map = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(map);

      //Gets all file paths in assets/bad_words/
      final badWordFiles = manifestMap.keys
          .where((String key) => key.startsWith('assets/bad_words/'))
          .toList();

      //Reads the content of each file and adds to the list
      for (final path in badWordFiles) {
        try {
          final String content = await rootBundle.loadString(path);
          final List<String> words = content
              .split('\n')
              .map((w) => w.trim())
              .where((w) => w.isNotEmpty)
              .toList();  
          allBadWords.addAll(words);
        }
        catch (e) {
          print('Error');
        }
      }
    } catch (e) {
      print('Error loading');
    } 

    //Adds our manual critical words, this is because the PT version is the PT-BR version and misses some common words from PT-PT
    allBadWords.addAll(_getManualCriticalWords());

    //Filters the library (removes duplicates)
    filter = ProfanityFilter.filterAdditionally(allBadWords);
    
    //Preprocess the list for robust checking and normalization
    listOfCriticalWords = allBadWords.map((w) => _normalizeText(w)).toList();
  }

  ///veryfies if the user text contains offensive words
  bool isOffensive(String text) {
    if (filter == null) {
      return false; 
    }

    //filter exact word matches
    if (filter!.hasProfanity(text)) return true;

    //filter hidden words (badwords with symbols or joined words)
    if (text.length < 500) {
      String hiddenWords = _normalizeText(text);
      
      for (final badWord in listOfCriticalWords) {
        //Ignores very small words to reduce false positives (example: "cu" is part of "cuidado", sorry, do not know an english example)
        if (badWord.length < 3) continue; 

        if (hiddenWords.contains(badWord)) {
          return true;
        }
      }
    }

    return false;
  }

  ///Normalizes text by removing accents, special characters and converting to lowercase
  String _normalizeText(String text) {
    String clean = text.toLowerCase();
    
    //Cleans accents
    clean = clean.replaceAll(RegExp(r'[àáâãäå]'), 'a');
    clean = clean.replaceAll(RegExp(r'[èéêë]'), 'e');
    clean = clean.replaceAll(RegExp(r'[ìíîï]'), 'i');
    clean = clean.replaceAll(RegExp(r'[òóôõö]'), 'o');
    clean = clean.replaceAll(RegExp(r'[ùúûü]'), 'u');
    clean = clean.replaceAll(RegExp(r'[ç]'), 'c');
    clean = clean.replaceAll(RegExp(r'[ñ]'), 'n');
    //Cleans special characters
    clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    
    return clean;
  }

  List<String> _getManualCriticalWords() {
    return [
      "caralho", "merda", "puta", "cabrao", "foda-se", "fodase", 
      "paneleiro", "cona", "pila", "fudido", "idiota", "estupido", 
      "pissolho", "fodasse", "piroca", "chupa", "corno", "fds",
      "picha", "pixa", "buceta", "bosta", "otario", "viado"
    ];
  }
}