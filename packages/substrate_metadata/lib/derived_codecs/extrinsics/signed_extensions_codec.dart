part of derived_codecs;

class SignedExtensionsCodec with Codec<Map<String, dynamic>> {
  final MetadataTypeRegistry registry;
  late final List<ExtensionInfo> extensions;
  late final List<Codec> codecs;

  SignedExtensionsCodec(this.registry) {
    // Handle both V14/V15 SignedExtensions and V16 TransactionExtensions
    final extrinsic = registry.extrinsic;

    if (extrinsic is ExtrinsicMetadataV16) {
      // V16: Use transaction extensions for the primary extrinsic version
      final txExtensions = extrinsic.extensionsForVersion(extrinsic.version);
      extensions = txExtensions
          .map((final te) => ExtensionInfo(identifier: te.identifier, type: te.type))
          .toList(growable: false);
    } else {
      // V14/V15: Use legacy signed extensions
      extensions = extrinsic.signedExtensions
          .map((final se) => ExtensionInfo(identifier: se.identifier, type: se.type))
          .toList(growable: false);
    }

    codecs = extensions.map((final extension) => registry.codecFor(extension.type)).toList();
  }

  @override
  Map<String, dynamic> decode(final Input input) {
    final extra = <String, dynamic>{};
    for (int i = 0; i < extensions.length; i++) {
      extra[extensions[i].identifier] = codecs[i].decode(input);
    }
    return extra;
  }

  @override
  void encodeTo(final Map<String, dynamic> value, final Output output) {
    for (int i = 0; i < extensions.length; i++) {
      final key = extensions[i].identifier;
      final val = value[key];

      if (val == null) {
        if (codecs[i] is! NullCodec && codecs[i].isSizeZero() == false) {
          throw MetadataException('Missing extension value for $key.');
        }
        // We can continue to next because this codec doesn't encode anything.
        // And even calling encode would not have any impact on the size
        continue;
      }
      try {
        codecs[i].encodeTo(val, output);
      } catch (_) {
        throw Exception('exception here at key:$key, value:$value, codec=${codecs[i]}');
      }
    }
  }

  @override
  int sizeHint(final Map<String, dynamic> value) {
    int size = 0;

    for (int i = 0; i < extensions.length; i++) {
      final key = extensions[i].identifier;
      final val = value[key];

      if (val == null) {
        throw MetadataException('Missing extension value for $key');
      }

      size += codecs[i].sizeHint(val);
    }

    return size;
  }

  @override
  bool isSizeZero() => codecs.every((final codec) => codec.isSizeZero());
}

/// Internal helper class to unify SignedExtensionMetadata and TransactionExtensionMetadata
class ExtensionInfo {
  final String identifier;
  final int type;
  const ExtensionInfo({required this.identifier, required this.type});
}
