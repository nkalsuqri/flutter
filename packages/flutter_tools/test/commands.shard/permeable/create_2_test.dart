// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  Directory tempDir;
  Directory projectDir;

  setUpAll(() async {
    Cache.disableLocking();
  });

  setUp(() {
    tempDir = globals.fs.systemTempDirectory
        .createTempSync('flutter_tools_create_test.');
    projectDir = tempDir.childDirectory('flutter_project');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testUsingContext('create an FFI plugin, then run ffigen', () async {
    Cache.flutterRoot = '../..';

    // GitHub actions do not have access to the full Flutter checkout with
    // the cache folder, run from source via bin/ instead.
    await Process.run(
      'flutter',
      <String>[
        'pub',
        'run',
        'flutter_tools',
        'create',
        '--no-pub',
        '--template=plugin_ffi',
        projectDir.path,
      ],
    );
    expect(projectDir.childFile('ffigen.yaml'), exists);
    final File generatedBindings = projectDir
        .childDirectory('lib')
        .childFile('${projectDir.basename}_bindings_generated.dart');
    expect(generatedBindings, exists);

    final String generatedBindingsFromTemplate =
        await generatedBindings.readAsString();

    await generatedBindings.delete();

    final ProcessResult pubGetResult = await Process.run(
      'flutter',
      <String>[
        'pub',
        'get',
      ],
      workingDirectory: projectDir.path,
    );
    printOnFailure('Results of running ffigen:');
    printOnFailure(pubGetResult.stdout.toString());
    printOnFailure(pubGetResult.stderr.toString());
    expect(pubGetResult.exitCode, 0);

    final ProcessResult ffigenResult = await Process.run(
      'flutter',
      <String>[
        'pub',
        'run',
        'ffigen',
        '--config',
        'ffigen.yaml',
      ],
      workingDirectory: projectDir.path,
    );
    printOnFailure('Results of running ffigen:');
    printOnFailure(ffigenResult.stdout.toString());
    printOnFailure(ffigenResult.stderr.toString());
    expect(ffigenResult.exitCode, 0);

    final String generatedBindingsFromFfigen =
        await generatedBindings.readAsString();

    expect(generatedBindingsFromFfigen, generatedBindingsFromTemplate);
  });
}
