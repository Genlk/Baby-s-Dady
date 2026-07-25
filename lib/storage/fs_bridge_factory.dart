import 'fs_bridge.dart';
import 'fs_bridge_memory.dart'
    if (dart.library.io) 'fs_bridge_io.dart' as impl;

FsBridge createFsBridge({String? rootOverride}) =>
    impl.createFsBridge(rootOverride: rootOverride);
