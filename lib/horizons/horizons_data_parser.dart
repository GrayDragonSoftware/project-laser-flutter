import 'package:project_lazer/horizons/horizons_block_parser.dart';
import 'package:project_lazer/horizons/model/blocks/table/table_parser.dart';
import 'package:project_lazer/horizons/model/horizons_data.dart';
import 'package:project_lazer/horizons/model/blocks/requester_info/requester_info_parser.dart';
import 'package:project_lazer/horizons/model/blocks/target_selection/target_selection_parser.dart';
import 'package:project_lazer/horizons/model/blocks/time_span/time_span_parser.dart';

class HorizonsDataParser {
  static const blockStartIdentifier = '********************';

  final List<HorizonsBlockParser> _blockParsers;

  HorizonsDataParser(this._blockParsers);

  HorizonsDataParser.withDefaultParsers()
      : this._blockParsers = [
          new RequesterInfoParser(),
          new TargetSelectionParser(),
          new TimeSpanParser(),
          new TableParser(),
        ];

  void registerBlockParser(HorizonsBlockParser horizonsBlockParser) {
    if (horizonsBlockParser != null) {
      _blockParsers.add(horizonsBlockParser);
      print('Registering block parser for ${horizonsBlockParser.runtimeType}');
    } else {
      print('Cannot register null');
    }
  }

  HorizonsData parse(String horizonsDataString) {
    final HorizonsData horizonsData = new HorizonsData();

    bool startingNewBlock = false;
    bool skipCurrentBlock = false;
    HorizonsBlockParser currentBlockParser;
    StringBuffer stringBuffer;
    for (final String rawLine in horizonsDataString.split('\n')) {
      final String line = rawLine.trim();

      // Check for new block
      if (line.startsWith(blockStartIdentifier)) {
        if (currentBlockParser != null && stringBuffer != null) {
          horizonsData.addDataBlock(currentBlockParser.parse(stringBuffer.toString()));
        }

        currentBlockParser = null;
        stringBuffer = null;
        startingNewBlock = true;
        skipCurrentBlock = false;
        continue;
      }

      // Choose a block parser
      if (startingNewBlock) {
        currentBlockParser = null;
        for (HorizonsBlockParser blockParser in _blockParsers) {
          if (blockParser.parserApplies(rawLine)) {
            print('${blockParser.runtimeType} applies');
            currentBlockParser = blockParser;
            break;
          }
        }

        if (currentBlockParser == null) {
          print('Block could not be parsed! No registered block parser applied. Skipping!');
          skipCurrentBlock = true;
        }

        startingNewBlock = false;
      }

      if (skipCurrentBlock) {
        continue;
      } else if (currentBlockParser == null) {
        print('Current block parser is not set. Skipping line');
        continue;
      }

      if (stringBuffer == null) stringBuffer = new StringBuffer();

      stringBuffer.writeln(rawLine);
    }

    return horizonsData;
  }
}
