#!/usr/bin/env fvm dart
// ignore_for_file: avoid_print

/// 使用示例
/// `./make.dart build`编译Android、iOS
/// `./make.dart run profile`以profile模式运行

import 'dart:convert';
import 'dart:io';

const appName = 'CustedNG';
const buildDataFilePath = 'lib/res/build_data.dart';
const xcarchivePath = 'build/ios/archive/CustedNG.xcarchive';

const skslFileSuffix = '.sksl.json';

final buildFuncs = {
  'ios': flutterBuildIOS,
  'android': flutterBuildAndroid,
};

Future<int> getGitCommitCount() async {
  final result = await Process.run('git', ['log', '--oneline']);
  return (result.stdout as String)
      .split('\n')
      .where((line) => line.isNotEmpty)
      .length;
}

Future<void> writeStaticConfigFile(
    Map<String, dynamic> data, String className, String path) async {
  final buffer = StringBuffer();
  buffer.writeln('// This file is generated by ./make.dart');
  buffer.writeln('');
  buffer.writeln('class $className {');
  for (var entry in data.entries) {
    final type = entry.value.runtimeType;
    final value = json.encode(entry.value);
    buffer.writeln('  static const $type ${entry.key} = $value;');
  }
  buffer.writeln('}');
  await File(path).writeAsString(buffer.toString());
}

Future<int> getGitModificationCount() async {
  final result =
      await Process.run('git', ['ls-files', '-mo', '--exclude-standard']);
  return (result.stdout as String)
      .split('\n')
      .where((line) => line.isNotEmpty)
      .length;
}

Future<Map<String, dynamic>> getBuildData() async {
  final data = {
    'name': appName,
    'build': await getGitCommitCount(),
    'engine': '2.10.5',
    'buildAt': DateTime.now().toString(),
    'modifications': await getGitModificationCount(),
  };
  return data;
}

String jsonEncodeWithIndent(Map<String, dynamic> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(json);
}

Future<void> updateBuildData() async {
  print('Updating BuildData...');
  final data = await getBuildData();
  print(jsonEncodeWithIndent(data));
  await writeStaticConfigFile(data, 'BuildData', buildDataFilePath);
}

void dartFormat() {
  final result = Process.runSync('fvm', ['dart', 'format', '.']);
  print('\n' + result.stdout);
  if (result.exitCode != 0) {
    print(result.stderr);
    exit(1);
  }
}

void flutterRun(String mode) {
  Process.start('fvm', ['flutter', 'run', mode == null ? '' : '--$mode'],
      mode: ProcessStartMode.inheritStdio, runInShell: true);
}

Future<void> flutterBuild(String source, String target, bool isAndroid) async {
  final build = await getGitCommitCount();

  final args = [
    'flutter',
    'build',
    isAndroid ? 'apk' : 'ipa',
    '--target-platform=android-arm64',
    '--build-number=$build',
    '--build-name=1.0.$build',
    '--bundle-sksl-path=${isAndroid ? 'android' : 'ios'}$skslFileSuffix',
  ];
  if (!isAndroid) args.removeAt(3);
  print('Building with args: ${args.join(' ')}');
  final buildResult = await Process.run('fvm', args, runInShell: true);
  final exitCode = buildResult.exitCode;

  if (exitCode == 0) {
    target = target.replaceFirst('build', build.toString());
    print('Copying from $source to $target');
    if (isAndroid) {
      await File(source).copy(target);
    } else {
      final result = await Process.run('cp', ['-r', source, target]);
      if (result.exitCode != 0) {
        print(result.stderr);
        exit(1);
      }
    }

    print('Done.\n');
  } else {
    print(buildResult.stderr.toString());
    print('\nBuild failed with exit code $exitCode');
    exit(exitCode);
  }
}

Future<void> flutterBuildIOS() async {
  await flutterBuild(
      xcarchivePath, './release/${appName}_build.xcarchive', false);
}

Future<void> flutterBuildAndroid() async {
  await flutterBuild('./build/app/outputs/flutter-apk/app-release.apk',
      './release/${appName}_build_Arm64.apk', true);
  await killJava();
}

Future<void> killJava() async {
  final result = await Process.run('ps', ['-A']);
  final lines = (result.stdout as String).split('\n');
  for (final line in lines) {
    if (line.contains('java')) {
      final pid = line.split(' ')[0];
      print('Killing java process: $pid');
      await Process.run('kill', [pid]);
    }
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('No action. Exit.');
    return;
  }

  final command = args[0];

  switch (command) {
    case 'run':
      return flutterRun(args.length == 2 ? args[1] : null);
    case 'build':
      final stopwatch = Stopwatch()..start();
      await updateBuildData();
      dartFormat();

      if (args.length > 1) {
        final platform = args[1];
        if (buildFuncs.containsKey(platform)) {
          await buildFuncs[platform]();
        } else {
          print('Unknown platform: $platform');
          exit(1);
        }
      } else {
        for (final func in buildFuncs.values) {
          await func();
        }
      }

      print('Build finished in ${stopwatch.elapsed}');
      return;
    case 'update-build':
      return updateBuildData();
    default:
      print('Unsupported command: $command');
      return;
  }
}
