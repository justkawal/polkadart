part of metadata;

typedef Lookup = List<LookupEntry>;

class TypeRef {
  final String tag;
  final dynamic value;

  const TypeRef({required this.tag, this.value});

  bool get isPerId => tag == 'perId';

  void encodeTo(TypeRef ref, ByteOutput output) {
    switch (ref.tag) {
      case 'bool':
        U8Codec.codec.encodeTo(0, output);
        break;
      case 'char':
        U8Codec.codec.encodeTo(1, output);
        break;
      case 'str':
        U8Codec.codec.encodeTo(2, output);
        break;
      case 'u8':
        U8Codec.codec.encodeTo(3, output);
        break;
      case 'u16':
        U8Codec.codec.encodeTo(4, output);
        break;
      case 'u32':
        U8Codec.codec.encodeTo(5, output);
        break;
      case 'u64':
        U8Codec.codec.encodeTo(6, output);
        break;
      case 'u128':
        U8Codec.codec.encodeTo(7, output);
        break;
      case 'u256':
        U8Codec.codec.encodeTo(8, output);
        break;
      case 'i8':
        U8Codec.codec.encodeTo(9, output);
        break;
      case 'i16':
        U8Codec.codec.encodeTo(10, output);
        break;
      case 'i32':
        U8Codec.codec.encodeTo(11, output);
        break;
      case 'i64':
        U8Codec.codec.encodeTo(12, output);
        break;
      case 'i128':
        U8Codec.codec.encodeTo(13, output);
        break;
      case 'i256':
        U8Codec.codec.encodeTo(14, output);
        break;
      case 'compactU8':
        U8Codec.codec.encodeTo(15, output);
        break;
      case 'compactU16':
        U8Codec.codec.encodeTo(16, output);
        break;
      case 'compactU32':
        U8Codec.codec.encodeTo(17, output);
        break;
      case 'compactU64':
        U8Codec.codec.encodeTo(18, output);
        break;
      case 'compactU128':
        U8Codec.codec.encodeTo(19, output);
        break;
      case 'compactU256':
        U8Codec.codec.encodeTo(20, output);
        break;
      case 'void':
        U8Codec.codec.encodeTo(21, output);
        break;
      case 'perId':
        U8Codec.codec.encodeTo(22, output);
        CompactCodec.codec.encodeTo(value, output);
        break;
      default:
        throw Exception('Unknown type: $tag');
    }
  }
}

class LookupValueParams {
  final String name;
  final int? type;

  const LookupValueParams({required this.name, this.type});
}

class LookupTypeDef {
  final String tag;
  final dynamic value;

  const LookupTypeDef({required this.tag, this.value});

  static LookupTypeDef fromTypeDef(TypeDef typeDef) {
    return switch (typeDef) {
      final TypeDefComposite def => LookupTypeDef(
        tag: 'composite',
        value: def.fields
            .map((field) => (name: field.name, typeName: field.typeName, type: field.type))
            .toList(),
      ),
      final TypeDefVariant def => LookupTypeDef(
        tag: 'variant',
        value: def.variants
            .map(
              (v) => (
                name: v.name,
                index: v.index,
                fields: v.fields
                    .map((field) => (name: field.name, typeName: field.typeName, type: field.type))
                    .toList(),
              ),
            )
            .toList(),
      ),
      final TypeDefSequence def => LookupTypeDef(tag: 'sequence', value: def.type),
      final TypeDefArray def => LookupTypeDef(
        tag: 'array',
        value: (len: def.length, type: def.type),
      ),
      final TypeDefTuple def => LookupTypeDef(tag: 'tuple', value: def.fields),
      final TypeDefBitSequence def => LookupTypeDef(tag: 'bitSequence', value: def),
      final TypeDefPrimitive def => LookupTypeDef(
        tag: 'primitive',
        value: (tag: def.primitive.name.toLowerCase(), value: null),
      ),
      final TypeDefCompact def => LookupTypeDef(tag: 'compact', value: def.type),
      // _ => throw Exception('Unknown type definition runtime type ${typeDef.runtimeType}'),
    };
  }

  void encodeTo(LookupTypeDef value, ByteOutput output) {
    switch (value.tag) {
      case 'composite':
        U8Codec.codec.encodeTo(0, output);
        value.value.encodeTo(value.value, output);
        break;
      case 'enumeration':
        U8Codec.codec.encodeTo(1, output);
        value.value.encodeTo(value.value, output);
        break;
      case 'sequence':
        U8Codec.codec.encodeTo(2, output);
        value.value.encodeTo(value.value, output);
        break;
      case 'array':
        U8Codec.codec.encodeTo(3, output);
        value.value.encodeTo(value.value, output);
        break;
      case 'tuple':
        U8Codec.codec.encodeTo(4, output);
        LookupTypeDefTuple(fields: value.value).encodeTo(value.value, output);
        break;
      case 'bitSequence':
        U8Codec.codec.encodeTo(5, output);
        value.value.encodeTo(value.value, output);
        break;
      case 'primitive':
      case 'compact':
        throw Exception('Compact or primitive type not supported');
    }
  }
}

class LookupValue {
  final int id;
  final List<String> path;
  final List<LookupValueParams> params;
  final LookupTypeDef def;

  const LookupValue({
    required this.id,
    required this.path,
    required this.params,
    required this.def,
  });
}

class LookupEntry {
  final List<String> path;
  final LookupTypeDef typeDef;
  final int typeId;

  const LookupEntry({required this.typeDef, required this.typeId, required this.path});

  Uint8List encode(LookupEntry value) {
    final ByteOutput output = ByteOutput();
    SequenceCodec(StrCodec.codec).encodeTo(value.path, output);
    value.typeDef.encodeTo(value.typeDef, output);
    CompactCodec.codec.encodeTo(value.typeId, output);
    return output.toBytes(copy: true);
  }
}

class LookupField {
  final String? name;
  final TypeRef ty;
  final String? typeName;
  final List<String> docs;

  const LookupField({required this.name, required this.ty, this.typeName, this.docs = const []});

  void encodeTo(LookupField value, ByteOutput output) {
    OptionCodec(StrCodec.codec).encodeTo(name, output);
    value.ty.encodeTo(value.ty, output);
    OptionCodec(StrCodec.codec).encodeTo(value.typeName, output);
  }
}

class LookupTypeDefComposite {
  final List<LookupField> fields;

  const LookupTypeDefComposite({required this.fields});

  void encodeTo(LookupTypeDefComposite value, ByteOutput output) {
    CompactCodec.codec.encodeTo(fields.length, output);
    for (final f in value.fields) {
      f.encodeTo(f, output);
    }
  }
}

class LookupTypeDefPrimitive {
  final TypeRef typeRef;

  const LookupTypeDefPrimitive({required this.typeRef});

  void encodeTo(LookupTypeDefPrimitive value, ByteOutput output) {
    value.typeRef.encodeTo(value.typeRef, output);
  }
}

class LookupTypeDefCompact {
  final TypeRef typeRef;

  const LookupTypeDefCompact({required this.typeRef});

  void encodeTo(LookupTypeDefCompact value, ByteOutput output) {
    // U8Codec.codec.encodeTo(6, output);
    // CompactCodec.codec.encodeTo(, output);
  }
}

class LookupTypeDefVariant {
  final List<LookupTypeDefEnumeration> value;

  const LookupTypeDefVariant({required this.value});

  void encodeTo(LookupTypeDefVariant value, ByteOutput output) {
    for (final v in value.value) {
      v.encodeTo(v, output);
    }
  }
}

class LookupTypeDefEnumeration {
  final String name;
  final List<LookupField> fields;
  final int index;
  final List<String> docs;

  const LookupTypeDefEnumeration({
    required this.name,
    required this.fields,
    required this.index,
    this.docs = const [],
  });

  void encodeTo(LookupTypeDefEnumeration value, ByteOutput output) {
    StrCodec.codec.encodeTo(value.name, output);
    CompactCodec.codec.encodeTo(value.fields.length, output);
    for (final f in value.fields) {
      f.encodeTo(f, output);
    }
    CompactCodec.codec.encodeTo(value.index, output);
  }
}

class LookupTypeDefSequence {
  final TypeRef typeId;

  const LookupTypeDefSequence({required this.typeId});

  void encodeTo(LookupTypeDefSequence value, ByteOutput output) {
    value.typeId.encodeTo(value.typeId, output);
  }
}

class LookupTypeDefArray {
  final int len;
  final TypeRef typeParam;

  const LookupTypeDefArray({required this.len, required this.typeParam});

  void encodeTo(LookupTypeDefArray value, ByteOutput output) {
    U32Codec.codec.encodeTo(len, output);
    value.typeParam.encodeTo(value.typeParam, output);
  }
}

class LookupTypeDefTuple {
  final List<TypeRef> fields;

  const LookupTypeDefTuple({required this.fields});

  void encodeTo(List<TypeRef> value, ByteOutput output) {
    CompactCodec.codec.encodeTo(value.length, output);
    for (final f in value) {
      f.encodeTo(f, output);
    }
  }
}

class LookupTypeDefBitSequence {
  final int numBytes;
  final bool leastSignificantBitFirst;

  const LookupTypeDefBitSequence({required this.numBytes, required this.leastSignificantBitFirst});

  void encodeTo(LookupTypeDefBitSequence value, ByteOutput output) {
    U8Codec.codec.encodeTo(numBytes, output);
    BoolCodec.codec.encodeTo(leastSignificantBitFirst, output);
  }
}

class MetadataDigest {
  final v0 = null;
  final dynamic v1;

  const MetadataDigest({required this.v1});

  Uint8List encode() {
    final output = ByteOutput();

    final typeInformationTreeRoot = v1.typeInformationTreeRoot;
    final extrinsicMetadataHash = v1.extrinsicMetadataHash;
    final specVersion = v1.specVersion;
    final specName = v1.specName;
    final base58Prefix = v1.base58Prefix;
    final decimals = v1.decimals;
    final tokenSymbol = v1.tokenSymbol;

    output.pushByte(1); // For v1
    output.write(typeInformationTreeRoot);
    output.write(extrinsicMetadataHash);
    U32Codec.codec.encodeTo(specVersion, output);
    StrCodec.codec.encodeTo(specName, output);
    U16Codec.codec.encodeTo(base58Prefix, output);
    U8Codec.codec.encodeTo(decimals, output);
    StrCodec.codec.encodeTo(tokenSymbol, output);

    return output.toBytes();
  }
}

class ExtrinsicInfo {
  final int version;
  final TypeRef addressTy;
  final TypeRef callTy;
  final TypeRef signatureTy;
  final List signedExtensions;

  const ExtrinsicInfo({
    required this.version,
    required this.addressTy,
    required this.callTy,
    required this.signatureTy,
    required this.signedExtensions,
  });

  Uint8List encode() {
    final output = ByteOutput();

    U8Codec.codec.encodeTo(version, output);
    addressTy.encodeTo(addressTy, output);
    callTy.encodeTo(callTy, output);
    signatureTy.encodeTo(signatureTy, output);

    CompactBigIntCodec.codec.encodeTo(BigInt.from(signedExtensions.length), output);
    for (final extension in signedExtensions) {
      final identifier = extension.identifier;
      CompactBigIntCodec.codec.encodeTo(BigInt.from(identifier.length), output);
      for (var i = 0; i < identifier.length; i++) {
        U8Codec.codec.encodeTo(identifier.codeUnitAt(i), output);
      }

      extension.includedInExtrinsic.encodeTo(extension.includedInExtrinsic, output);
      extension.includedInSignedData.encodeTo(extension.includedInSignedData, output);
    }

    return output.toBytes();
  }
}

class ExtraInfo {
  final int specVersion;
  final String specName;
  final int base58Prefix;
  final int decimals;
  final String tokenSymbol;

  const ExtraInfo({
    required this.specVersion,
    required this.specName,
    required this.base58Prefix,
    required this.decimals,
    required this.tokenSymbol,
  });

  Uint8List encode() {
    final output = ByteOutput();

    U32Codec.codec.encodeTo(specVersion, output);
    StrCodec.codec.encodeTo(specName, output);
    U16Codec.codec.encodeTo(base58Prefix, output);
    U8Codec.codec.encodeTo(decimals, output);
    StrCodec.codec.encodeTo(tokenSymbol, output);

    return output.toBytes();
  }
}

class MetadataMerkleizer {
  final RuntimeMetadata metadata;
  final int decimals;
  final String tokenSymbol;
  final int? specVersion;
  final String? specName;
  final int? base58Prefix;

  late final Lookup lookup;
  late final List<Uint8List> lookupEncoded;
  late final ExtrinsicInfo extrinsicMeta;
  late final ExtraInfo extraInfo;

  Uint8List? digested;

  MetadataMerkleizer._({
    required this.metadata,
    required this.decimals,
    required this.tokenSymbol,
    this.specVersion,
    this.specName,
    this.base58Prefix,
  }) {
    final PalletMetadata system = metadata.pallets.firstWhere(
      (p) => p.name == 'System',
      orElse: () => throw Exception('System pallet not found'),
    );
    final PalletConstantMetadata ss58prefix = system.constants.firstWhere(
      (c) => c.name == 'SS58Prefix',
      orElse: () => throw Exception('System.ss58Prefix constant not found'),
    );
    final PalletConstantMetadata version = system.constants.firstWhere(
      (c) => c.name == 'Version',
      orElse: () => throw Exception('System.Version constant not found'),
    );

    final ss58 = decodeTypeDef(
      metadata.typeById(ss58prefix.type).type.typeDef,
      ss58prefix.value.toInput(),
    );

    assertion(ss58 != null, 'SS58 prefix not found');
    assertion(base58Prefix == null || ss58 == base58Prefix, 'SS58 prefix mismatch');

    final runtime = decodeTypeDef(
      metadata.typeById(version.type).type.typeDef,
      version.value.toInput(),
    );

    assertion(runtime['spec_name'] != null, 'Spec name not found');
    assertion(
      specVersion == null || runtime['spec_version'] == specVersion,
      'Spec version mismatch',
    );
    assertion(runtime['spec_version'] != null, 'Spec version not found');
    assertion(specName == null || runtime['spec_name'] == specName, 'Spec name mismatch');

    extraInfo = ExtraInfo(
      decimals: decimals,
      tokenSymbol: tokenSymbol,
      specVersion: runtime['spec_version'],
      specName: runtime['spec_name'],
      base58Prefix: ss58,
    );

    final definitions = Map<int, LookupValue>.fromEntries(
      metadata.types.map(
        (type) => MapEntry(
          type.id,
          LookupValue(
            id: type.id,
            path: type.type.path,
            params: type.type.params
                .map((param) => LookupValueParams(name: param.name, type: param.type))
                .toList(),
            def: LookupTypeDef.fromTypeDef(type.type.typeDef),
          ),
        ),
      ),
    );

    final Map<int, int> accessibleTypes = getAccessibleTypes(definitions);
    final lookup = getLookup(definitions, accessibleTypes);
    final List<Uint8List> lookupEncoded = lookup.map<Uint8List>((l) => l.encode(l)).toList();

    this.lookup = lookup;
    this.lookupEncoded = lookupEncoded;
    extrinsicMeta = ExtrinsicInfo(
      version: metadata.extrinsic.version,
      addressTy: getTypeRef(definitions, accessibleTypes, metadata.extrinsic.addressType),
      callTy: getTypeRef(definitions, accessibleTypes, metadata.extrinsic.callType),
      signatureTy: getTypeRef(definitions, accessibleTypes, metadata.extrinsic.signatureType),
      signedExtensions: _getExtensionsInfo(metadata.extrinsic, definitions, accessibleTypes),
    );
  }

  /// Get extensions info handling V14/V15 signedExtensions vs V16 transactionExtensions
  List<({String identifier, TypeRef includedInExtrinsic, TypeRef includedInSignedData})>
  _getExtensionsInfo(
    ExtrinsicMetadata ext,
    Map<int, LookupValue> definitions,
    Map<int, int> accessibleTypes,
  ) {
    if (ext is ExtrinsicMetadataV16) {
      return ext.transactionExtensions
          .map(
            (te) => (
              identifier: te.identifier,
              includedInExtrinsic: getTypeRef(definitions, accessibleTypes, te.type),
              includedInSignedData: getTypeRef(definitions, accessibleTypes, te.implicit),
            ),
          )
          .toList();
    }
    return ext.signedExtensions
        .map(
          (se) => (
            identifier: se.identifier,
            includedInExtrinsic: getTypeRef(definitions, accessibleTypes, se.type),
            includedInSignedData: getTypeRef(definitions, accessibleTypes, se.additionalSigned),
          ),
        )
        .toList();
  }

  int getBitSequenceBytes(String primitive) {
    switch (primitive) {
      case 'u8':
        return 1;
      case 'u16':
        return 2;
      case 'u32':
        return 4;
      case 'u64':
        return 8;
      default:
        throw Exception('Invalid primitive for BitSequence');
    }
  }

  String compactTypeRefs(dynamic primitive) {
    return switch (primitive) {
      null => 'void',
      'u8' => 'compactU8',
      'u16' => 'compactU16',
      'u32' => 'compactU32',
      'u64' => 'compactU64',
      'u128' => 'compactU128',
      'u256' => 'compactU256',
      _ => throw Exception('Invalid primitive for compact type'),
    };
  }

  dynamic getPrimitive(Map<int, LookupValue> definitions, int frameId) {
    final def = definitions[frameId]!.def;

    if (def.tag == 'primitive') {
      return def.value.tag;
    }

    if ((def.tag != 'composite' && def.tag != 'tuple') || def.value.length > 1) {
      throw Exception('TypeDef provided does not map to a primitive type');
    }

    return def.value.length == 0
        ? null
        : getPrimitive(definitions, def.tag == 'tuple' ? def.value[0] : def.value[0].type);
  }

  TypeRef getTypeRef(
    Map<int, LookupValue> definitions,
    Map<int, int> accessibleTypes,
    int frameId,
  ) {
    final def = definitions[frameId]!.def;

    if (def.tag == 'primitive') {
      return TypeRef(tag: def.value.tag, value: null);
    }

    if (def.tag == 'compact') {
      final primitive = getPrimitive(definitions, def.value);
      final tag = compactTypeRefs(primitive);
      return TypeRef(tag: tag, value: null);
    }

    return accessibleTypes.containsKey(frameId)
        ? TypeRef(tag: 'perId', value: accessibleTypes[frameId]!)
        : TypeRef(tag: 'void', value: null);
  }

  List<LookupTypeDef> constructLookupTypeDef(
    Map<int, LookupValue> definitions,
    Map<int, int> accessibleTypes,
    int frameId,
  ) {
    final def = definitions[frameId]!.def;

    switch (def.tag) {
      case 'composite':
        return [
          LookupTypeDef(
            tag: def.tag,
            value: LookupTypeDefComposite(
              fields: def.value
                  .map<LookupField>(
                    (f) => LookupField(
                      name: f.name,
                      typeName: f.typeName,
                      ty: getTypeRef(definitions, accessibleTypes, f.type),
                    ),
                  )
                  .toList(),
            ),
          ),
        ];
      case 'variant':
        return def.value
            .map<LookupTypeDef>(
              (v) => LookupTypeDef(
                tag: 'enumeration',
                value: LookupTypeDefEnumeration(
                  name: v.name,
                  index: v.index,
                  fields: v.fields
                      .map<LookupField>(
                        (field) => LookupField(
                          name: field.name,
                          typeName: field.typeName,
                          ty: getTypeRef(definitions, accessibleTypes, field.type),
                        ),
                      )
                      .toList(),
                ),
              ),
            )
            .toList();
      case 'sequence':
        return [
          LookupTypeDef(tag: def.tag, value: getTypeRef(definitions, accessibleTypes, def.value)),
        ];
      case 'array':
        return [
          LookupTypeDef(
            tag: def.tag,
            value: LookupTypeDefArray(
              len: def.value.len,
              typeParam: getTypeRef(definitions, accessibleTypes, def.value.type),
            ),
          ),
        ];
      case 'tuple':
        return [
          LookupTypeDef(
            tag: def.tag,
            value: def.value
                .map<TypeRef>((t) => getTypeRef(definitions, accessibleTypes, t))
                .toList(),
          ),
        ];
      case 'bitSequence':
        final primitive = getPrimitive(definitions, def.value.bitStoreType);
        final numBytes = getBitSequenceBytes(primitive);

        final storeOrderPath = definitions[def.value.bitOrderType]!.path;
        final leastSignificantBitFirst = storeOrderPath.contains('Lsb0');
        if (!leastSignificantBitFirst && !storeOrderPath.contains('Msb0')) {
          throw Exception('Invalid bit order type');
        }

        return [
          LookupTypeDef(
            tag: 'bitSequence',
            value: LookupTypeDefBitSequence(
              numBytes: numBytes,
              leastSignificantBitFirst: leastSignificantBitFirst,
            ),
          ),
        ];
    }

    throw Exception('FrameId($frameId) should have been filtered out');
  }

  Lookup getLookup(Map<int, LookupValue> definitions, Map<int, int> accessibleTypes) {
    final Lookup typeTree = [];

    for (final entry in accessibleTypes.entries) {
      final frameId = entry.key;
      final typeId = entry.value;
      final path = definitions[frameId]!.path;

      for (final def in constructLookupTypeDef(definitions, accessibleTypes, frameId)) {
        typeTree.add(LookupEntry(path: path, typeId: typeId, typeDef: def));
      }
    }

    typeTree.sort((a, b) {
      if (a.typeId != b.typeId) return a.typeId.compareTo(b.typeId);
      if (a.typeDef.tag != 'enumeration' || b.typeDef.tag != 'enumeration') {
        throw Exception('Found two types with same id');
      }

      return a.typeDef.value.index.compareTo(b.typeDef.value.index);
    });

    return typeTree;
  }

  Map<int, int> getAccessibleTypes(Map<int, LookupValue> definitions) {
    final Set<int> types = {};

    void collectTypesFromId(int id) {
      if (types.contains(id)) return;

      final def = definitions[id]!.def;

      switch (def.tag) {
        case 'composite':
          if (def.value.isEmpty) break;
          types.add(id);
          for (var v in def.value) {
            collectTypesFromId(v.type);
          }
          break;
        case 'variant':
          if (def.value.isEmpty) break;
          types.add(id);
          for (var v in def.value) {
            for (var f in v.fields) {
              collectTypesFromId(f.type);
            }
          }
          break;
        case 'tuple':
          if (def.value.isEmpty) break;
          types.add(id);
          for (var type in def.value) {
            collectTypesFromId(type);
          }
          break;
        case 'sequence':
          types.add(id);
          collectTypesFromId(def.value);
          break;
        case 'array':
          types.add(id);
          collectTypesFromId(def.value.type);
          break;
        case 'bitSequence':
          types.add(id);
          break;
      }
    }

    final extr = metadata.extrinsic;
    collectTypesFromId(extr.callType);
    collectTypesFromId(extr.addressType);
    collectTypesFromId(extr.signatureType);

    // Handle V16 (uses transactionExtensions instead of signedExtensions)
    if (extr is ExtrinsicMetadataV16) {
      for (var te in extr.transactionExtensions) {
        collectTypesFromId(te.type);
        collectTypesFromId(te.implicit);
      }
    } else {
      // V14/V15 use signedExtensions
      for (var se in extr.signedExtensions) {
        collectTypesFromId(se.type);
        collectTypesFromId(se.additionalSigned);
      }
    }

    final List<int> sorted = types.toList()..sort();
    return sorted.asMap().map((key, value) => MapEntry(value, key));
  }

  dynamic decodePrimitive(Primitive primitive, Input input) {
    switch (primitive) {
      case Primitive.Bool:
        return BoolCodec.codec.decode(input);
      case Primitive.Char:
        return U8Codec.codec.decode(input);
      case Primitive.Str:
        return StrCodec.codec.decode(input);
      case Primitive.U8:
        return U8Codec.codec.decode(input);
      case Primitive.U16:
        return U16Codec.codec.decode(input);
      case Primitive.U32:
        return U32Codec.codec.decode(input);
      case Primitive.U64:
        return U64Codec.codec.decode(input);
      case Primitive.U128:
        return U128Codec.codec.decode(input);
      case Primitive.U256:
        return U256Codec.codec.decode(input);
      case Primitive.I8:
        return I8Codec.codec.decode(input);
      case Primitive.I16:
        return I16Codec.codec.decode(input);
      case Primitive.I32:
        return I32Codec.codec.decode(input);
      case Primitive.I64:
        return I64Codec.codec.decode(input);
      case Primitive.I128:
        return I128Codec.codec.decode(input);
      case Primitive.I256:
        return I256Codec.codec.decode(input);
    }
  }

  dynamic decodeComposite(TypeDefComposite def, Input input) {
    if (def.fields.length == 1 && def.fields.first.name == null) {
      return decodeTypeDef(metadata.typeById(def.fields.first.type).type.typeDef, input);
    }
    return {
      for (final f in def.fields)
        f.name: decodeTypeDef(metadata.typeById(f.type).type.typeDef, input),
    };
  }

  List<dynamic> decodeSequence(TypeDefSequence def, Input input) {
    final typeDef = metadata.typeById(def.type).type.typeDef;
    final length = CompactCodec.codec.decode(input);

    return List.generate(length, (i) => decodeTypeDef(typeDef, input));
  }

  List<dynamic>? decodeTuple(TypeDefTuple def, Input input) {
    if (def.fields.isEmpty) return null;

    return List.generate(
      def.fields.length,
      (i) => decodeTypeDef(metadata.typeById(def.fields[i]).type.typeDef, input),
    );
  }

  List<dynamic> decodeArray(TypeDefArray def, Input input) {
    final typeDef = metadata.typeById(def.type).type.typeDef;

    return List.generate(def.length, (i) => decodeTypeDef(typeDef, input));
  }

  dynamic decodeTypeDef(TypeDef def, Input input) {
    return switch (def) {
      final TypeDefComposite def => decodeComposite(def, input),
      final TypeDefSequence def => decodeSequence(def, input),
      final TypeDefTuple def => decodeTuple(def, input),
      final TypeDefArray def => decodeArray(def, input),
      final TypeDefPrimitive def => decodePrimitive(def.primitive, input),
      _ => throw Exception('TypeDef not supported: ${def.runtimeType}'),
    };
  }

  static MetadataMerkleizer fromMetadata(
    RuntimeMetadata metadata, {
    required int decimals,
    required String tokenSymbol,
    int? specVersion,
    String? specName,
    int? base58Prefix,
  }) {
    return MetadataMerkleizer._(
      metadata: metadata,
      decimals: decimals,
      tokenSymbol: tokenSymbol,
      specVersion: specVersion,
      specName: specName,
      base58Prefix: base58Prefix,
    );
  }

  ({bool signed, int version}) versionDecoder(Input extrinsic) {
    final value = extrinsic.readBytes(1).first;

    return (version: value & ~(1 << 7), signed: ((value & (1 << 7)) != 0));
  }

  (int version, bool signed, Uint8List bytes) decodeExtrinsic(Uint8List extrinsic) {
    final input = Input.fromBytes(extrinsic);
    CompactCodec.codec.decode(input);
    final ver = versionDecoder(input);
    final bytes = input.readBytes(input.remainingLength!);

    return (ver.version, ver.signed, bytes);
  }

  Uint8List mergeUint8(List<Uint8List> inputs) {
    final list = Uint8List(inputs.fold<int>(0, (sum, element) => sum + element.length));
    var offset = 0;
    for (final element in inputs) {
      list.setAll(offset, element);
      offset += element.length;
    }
    return list;
  }

  void skipTypeRef(TypeRef ref, Input input) {
    switch (ref.tag) {
      case 'bool':
      case 'char':
      case 'u8':
        U8Codec.codec.decode(input);
        break;
      case 'str':
        StrCodec.codec.decode(input);
        break;
      case 'u16':
        U16Codec.codec.decode(input);
        break;
      case 'u32':
        U32Codec.codec.decode(input);
        break;
      case 'u64':
        U64Codec.codec.decode(input);
        break;
      case 'u128':
        U128Codec.codec.decode(input);
        break;
      case 'u256':
        U256Codec.codec.decode(input);
        break;
      case 'i8':
        I8Codec.codec.decode(input);
        break;
      case 'i16':
        I16Codec.codec.decode(input);
        break;
      case 'i32':
        I32Codec.codec.decode(input);
        break;
      case 'i64':
        I64Codec.codec.decode(input);
        break;
      case 'i128':
        I128Codec.codec.decode(input);
        break;
      case 'i256':
        I256Codec.codec.decode(input);
        break;
      case 'void':
        NullCodec.codec.decode(input);
        break;
      case 'compactU8':
      case 'compactU16':
      case 'compactU32':
      case 'compactU64':
      case 'compactU128':
      case 'compactU256':
        CompactBigIntCodec.codec.decode(input);
        break;
      default:
        throw Exception('Unsupported primitive type: ${ref.tag}');
    }
  }

  void innerDecodeAndCollect(
    Input input,
    TypeRef typeRef,
    Map<int, List<int>> idToLookups,
    Set<int> collected,
  ) {
    if (typeRef.tag != 'perId') {
      skipTypeRef(typeRef, input);
      return;
    }

    void handleTypeRef(TypeRef typeRef) {
      innerDecodeAndCollect(input, typeRef, idToLookups, collected);
    }

    final lookupIdxs = idToLookups[typeRef.value]!;
    final currentIdx = lookupIdxs[0];
    final current = lookup[currentIdx];

    if (lookupIdxs.length == 1) {
      collected.add(currentIdx);
    }

    switch (current.typeDef.tag) {
      case 'enumeration':
        final selectedIdx = U8Codec.codec.decode(input);
        final result = lookupIdxs
            .map((lookupIdx) => [lookup[lookupIdx].typeDef, lookupIdx])
            .firstWhere((x) {
              final variant = x[0] as LookupTypeDef;
              return variant.value.index == selectedIdx;
            });

        final collectedIdx = result[1] as int;
        collected.add(collectedIdx);

        final selected = result[0] as LookupTypeDef;
        selected.value.fields.forEach((field) {
          handleTypeRef(field.ty);
        });
        break;
      case 'sequence':
        final len = CompactBigIntCodec.codec.decode(input).toInt();
        for (var i = 0; i < len; i++) {
          handleTypeRef(current.typeDef.value);
        }
        break;
      case 'array':
        for (var i = 0; i < current.typeDef.value.len; i++) {
          handleTypeRef(current.typeDef.value.typeParam);
        }
        break;
      case 'composite':
        current.typeDef.value.fields.forEach((e) => handleTypeRef(e.ty));
        break;
      case 'tuple':
        current.typeDef.value.forEach((e) => handleTypeRef(e));
        break;
      case 'bitSequence':
        throw Exception('bitSequence is not supported');
    }
  }

  List<int> decodeAndCollectKnownLeafs(Uint8List input, List<TypeRef> typeRefs) {
    final idToLookups = <int, List<int>>{};
    for (var i = 0; i < lookup.length; i++) {
      final look = lookup[i];
      final arr = idToLookups[look.typeId];
      if (arr != null) {
        arr.add(i);
      } else {
        idToLookups[look.typeId] = [i];
      }
    }

    final result = <int>{};
    final bytesInput = Input.fromBytes(input);

    for (var i = 0; i < typeRefs.length; i++) {
      final typeRef = typeRefs[i];
      innerDecodeAndCollect(bytesInput, typeRef, idToLookups, result);
    }

    return result.toList()..sort();
  }

  double log2(int x) {
    return log(x) / log(2);
  }

  int getLevelFromIdx(int idx) {
    return log2(idx + 1).floor();
  }

  int jsShift(int value, int shift) {
    int sc = shift % 32;
    if (sc < 0) {
      sc += 32;
    }
    return value >> sc;
  }

  int getAncestorIdx(int from, int nLevels) {
    return jsShift(from + 1, nLevels) - 1;
  }

  ({List<int> leafIndexes, List<Uint8List> leaves, List<int> proofIndexes}) getProofData(
    List<int> knownLeavesIdxs,
  ) {
    final knownLeaves = knownLeavesIdxs.map((idx) => lookupEncoded[idx]).toList();

    final startingIdx = lookupEncoded.length - 1;
    final leafIdxs = knownLeavesIdxs.map((idx) => startingIdx + idx).toList();

    final proofIdxs = <int>[];
    if (leafIdxs.isNotEmpty) {
      final nLevels = getLevelFromIdx(leafIdxs.last);
      final splitPosition = pow(2, nLevels) - 1;
      final splitIdx = leafIdxs.indexWhere((x) => x >= splitPosition);

      if (splitIdx > 0) {
        final spliced = leafIdxs.sublist(splitIdx);
        leafIdxs.removeRange(splitIdx, leafIdxs.length);
        leafIdxs.insertAll(0, spliced);

        final splicedLeaves = knownLeaves.sublist(splitIdx);
        knownLeaves.removeRange(splitIdx, knownLeaves.length);
        knownLeaves.insertAll(0, splicedLeaves);
      }
    }

    var targetIdx = 0;
    void traverse(int nodeIdx) {
      if (targetIdx == leafIdxs.length) {
        proofIdxs.add(nodeIdx);
        return;
      }

      final target = leafIdxs[targetIdx];
      if (target == nodeIdx) {
        ++targetIdx;
        return;
      }

      final currentLevel = getLevelFromIdx(nodeIdx);
      final targetLevel = getLevelFromIdx(target);

      if (nodeIdx != getAncestorIdx(target, targetLevel - currentLevel)) {
        proofIdxs.add(nodeIdx);
        return;
      }

      final leftSon = 2 * nodeIdx + 1;
      traverse(leftSon);
      traverse(leftSon + 1);
    }

    traverse(0);

    return (leaves: knownLeaves, leafIndexes: leafIdxs, proofIndexes: proofIdxs);
  }

  Uint8List blake3Hash(Uint8List input) {
    final hasher = Blake3Hasher(32);
    return hasher.hash(input);
  }

  Uint8List digest() {
    if (digested != null) return digested!;
    final rootLookupHash = getHashTree()[0];

    final metadataDigest = MetadataDigest(
      v1: (
        typeInformationTreeRoot: rootLookupHash,
        extrinsicMetadataHash: blake3Hash(extrinsicMeta.encode()),
        specVersion: extraInfo.specVersion,
        specName: extraInfo.specName,
        base58Prefix: extraInfo.base58Prefix,
        decimals: extraInfo.decimals,
        tokenSymbol: extraInfo.tokenSymbol,
      ),
    );

    return (digested = blake3Hash(metadataDigest.encode()));
  }

  List<Uint8List> getHashTree() {
    if (lookupEncoded.isEmpty) {
      return [Uint8List(32)..fillRange(0, 32, 0)];
    }

    final treeSize = lookupEncoded.length * 2 - 1;
    final hashTree = List<Uint8List>.filled(treeSize, Uint8List(0));

    final leavesStartIdx = lookupEncoded.length - 1;
    for (var i = 0; i < lookupEncoded.length; i++) {
      hashTree[leavesStartIdx + i] = blake3Hash(lookupEncoded[i]);
    }

    for (var i = hashTree.length - 2; i > 0; i -= 2) {
      hashTree[(i - 1) ~/ 2] = blake3Hash(mergeUint8([hashTree[i], hashTree[i + 1]]));
    }

    return hashTree;
  }

  Uint8List generateProof(List<int> knownIndexes) {
    final proofData = getProofData(knownIndexes);

    final hashTree = getHashTree();
    final proofs = proofData.proofIndexes.map((idx) => hashTree[idx]).toList();

    return mergeUint8([
      CompactCodec.codec.encode(proofData.leaves.length),
      ...proofData.leaves,
      CompactCodec.codec.encode(proofData.leafIndexes.length),
      ...proofData.leafIndexes.map((x) => U32Codec.codec.encode(x)),
      CompactCodec.codec.encode(proofs.length),
      ...proofs,
      extrinsicMeta.encode(),
      extraInfo.encode(),
    ]);
  }

  Uint8List getProofForExtrinsicPayload(Uint8List payload) {
    final List<TypeRef> typeRefs = [
      extrinsicMeta.callTy,
      ...extrinsicMeta.signedExtensions.map((e) => e.includedInExtrinsic).toList(),
      ...extrinsicMeta.signedExtensions.map((e) => e.includedInSignedData).toList(),
    ];

    return generateProof(decodeAndCollectKnownLeafs(payload, typeRefs));
  }

  Uint8List getProofForExtrinsicParts(
    Uint8List callData,
    Uint8List includedInExtrinsic,
    Uint8List includedInSignedData,
  ) {
    final bytes = mergeUint8([callData, includedInExtrinsic, includedInSignedData]);

    return getProofForExtrinsicPayload(bytes);
  }

  Uint8List getProofForExtrinsic(Uint8List transaction, Uint8List? txAdditionalSigned) {
    final (version, signed, bytes) = decodeExtrinsic(transaction);

    assertion(version == extrinsicMeta.version, 'Incorrect extrinsic version');

    final List<TypeRef> typeRefs = signed
        ? [
            extrinsicMeta.addressTy,
            extrinsicMeta.signatureTy,
            ...extrinsicMeta.signedExtensions.map((x) => x.includedInExtrinsic),
            extrinsicMeta.callTy,
          ]
        : [extrinsicMeta.callTy];

    if (txAdditionalSigned != null) {
      typeRefs.addAll(extrinsicMeta.signedExtensions.map((e) => e.includedInSignedData));
    }

    final proofBytes = txAdditionalSigned != null ? mergeUint8([bytes, txAdditionalSigned]) : bytes;

    return generateProof(decodeAndCollectKnownLeafs(proofBytes, typeRefs));
  }
}
