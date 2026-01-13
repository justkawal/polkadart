import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'types.dart';

/// Platform-specific library loading and path resolution
class SmoldotPlatform {
  /// Library name without extension
  static const String _libraryName = 'smoldot';

  /// Get the dynamic library for the current platform
  static DynamicLibrary loadLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      return _loadLinux();
    } else if (Platform.isIOS || Platform.isMacOS) {
      return _loadDarwin();
    } else if (Platform.isWindows) {
      return _loadWindows();
    } else {
      throw SmoldotFfiException(
        'Unsupported platform: ${Platform.operatingSystem}',
        details: 'Only Android, iOS, macOS, Linux, and Windows are supported',
      );
    }
  }

  /// Load library on Linux/Android
  static DynamicLibrary _loadLinux() {
    try {
      // Try loading from system library path
      return DynamicLibrary.open('lib$_libraryName.so');
    } catch (e) {
      // Try loading from package directory
      final libraryPath = _getPackageLibraryPath('lib$_libraryName.so');
      if (libraryPath != null) {
        return DynamicLibrary.open(libraryPath);
      }
      throw SmoldotFfiException(
        'Failed to load $_libraryName library on ${Platform.operatingSystem}',
        details: e.toString(),
      );
    }
  }

  /// Load library on macOS/iOS
  static DynamicLibrary _loadDarwin() {
    // First try package-relative path
    final libraryPath = _getPackageLibraryPath('lib$_libraryName.dylib');
    if (libraryPath != null && File(libraryPath).existsSync()) {
      try {
        return DynamicLibrary.open(libraryPath);
      } catch (e) {
        // Continue to other methods
        print('Failed to load from package path: $e');
      }
    }

    try {
      // Try loading from system library path
      return DynamicLibrary.open('lib$_libraryName.dylib');
    } catch (e) {
      try {
        // Try loading as a framework (iOS)
        return DynamicLibrary.process();
      } catch (e2) {
        throw SmoldotFfiException(
          'Failed to load $_libraryName library on ${Platform.operatingSystem}',
          details: 'Library path: $libraryPath\nError 1: $e\nError 2: $e2',
        );
      }
    }
  }

  /// Load library on Windows
  static DynamicLibrary _loadWindows() {
    try {
      // Try loading from system library path
      return DynamicLibrary.open('$_libraryName.dll');
    } catch (e) {
      // Try loading from package directory
      final libraryPath = _getPackageLibraryPath('$_libraryName.dll');
      if (libraryPath != null) {
        return DynamicLibrary.open(libraryPath);
      }
      throw SmoldotFfiException(
        'Failed to load $_libraryName library on ${Platform.operatingSystem}',
        details: e.toString(),
      );
    }
  }

  /// Get the package library path for the given library name
  static String? _getPackageLibraryPath(String libraryName) {
    // Common locations to search for native libraries
    final searchPaths = <String>[
      // Current directory
      Directory.current.path,
      // Parent directory (for package development)
      path.join(Directory.current.path, '..'),
      // Native directory
      path.join(Directory.current.path, 'native'),
      // Lib directory
      path.join(Directory.current.path, 'lib'),
      // Build directory
      path.join(Directory.current.path, 'build'),
    ];

    for (final searchPath in searchPaths) {
      final libraryPath = path.join(searchPath, libraryName);
      if (File(libraryPath).existsSync()) {
        return libraryPath;
      }

      // Also check in subdirectories for platform-specific builds
      final platformPath = path.join(
        searchPath,
        _getPlatformSubdir(),
        libraryName,
      );
      if (File(platformPath).existsSync()) {
        return platformPath;
      }
    }

    return null;
  }

  /// Get platform-specific subdirectory name
  static String _getPlatformSubdir() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isWindows) {
      return 'windows';
    }
    return '';
  }

  /// Get the current platform name
  static String get platformName => Platform.operatingSystem;

  /// Check if the platform is supported
  static bool get isSupported {
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isWindows;
  }

  /// Get platform-specific library extension
  static String get libraryExtension {
    if (Platform.isAndroid || Platform.isLinux) {
      return '.so';
    } else if (Platform.isIOS || Platform.isMacOS) {
      return '.dylib';
    } else if (Platform.isWindows) {
      return '.dll';
    }
    return '';
  }

  /// Get the full library name with extension
  static String get fullLibraryName {
    final prefix = Platform.isWindows ? '' : 'lib';
    return '$prefix$_libraryName$libraryExtension';
  }
}
