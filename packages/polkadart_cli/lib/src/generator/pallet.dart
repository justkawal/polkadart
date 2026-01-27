import 'dart:typed_data' show Uint8List;

import 'package:code_builder/code_builder.dart'
    show
        Block,
        Class,
        Code,
        CodeExpression,
        Constructor,
        Expression,
        Field,
        FieldModifier,
        Method,
        MethodModifier,
        Parameter,
        Reference,
        TypeReference,
        declareFinal,
        literalString,
        refer;
import 'package:path/path.dart' as p;
import 'package:polkadart_scale_codec/io/io.dart';
import 'package:recase/recase.dart' show ReCase;
import 'package:substrate_metadata/substrate_metadata.dart' as metadata;

import '../typegen/references.dart' as refs;
import '../typegen/typegen.dart'
    as typegen
    show
        TypeDescriptor,
        BasePath,
        TupleBuilder,
        GeneratedOutput,
        Field,
        VariantBuilder,
        Variant,
        TypeDefBuilder,
        EmptyDescriptor,
        SequenceDescriptor,
        ArrayDescriptor,
        PrimitiveDescriptor;
import '../utils/utils.dart' show sanitize, sanitizeDocs;

enum StorageHasherType {
  /// Identity hashing (no hashing).
  identity,
  blake2b128,
  blake2b128Concat,
  blake2b256,
  twoxx64,
  twoxx64Concat,
  twoxx128,
  twoxx128Concat,
  twoxx256;

  const StorageHasherType();

  TypeReference type(typegen.BasePath from) {
    return refs.storageHasher.type as TypeReference;
  }

  Expression instance(Expression codecInstance, typegen.BasePath from) {
    return type(from).property(name).call([codecInstance]);
  }
}

class StorageHasher<G extends typegen.TypeDescriptor> {
  final StorageHasherType hasher;
  final G codec;

  const StorageHasher({required this.hasher, required this.codec});
  const StorageHasher.identity({required this.codec}) : hasher = StorageHasherType.identity;
  const StorageHasher.blake128({required this.codec}) : hasher = StorageHasherType.blake2b128;
  const StorageHasher.blake128Concat({required this.codec})
    : hasher = StorageHasherType.blake2b128Concat;
  const StorageHasher.blake256({required this.codec}) : hasher = StorageHasherType.blake2b256;
  const StorageHasher.twoxx64({required this.codec}) : hasher = StorageHasherType.twoxx64;
  const StorageHasher.twoxx64Concat({required this.codec})
    : hasher = StorageHasherType.twoxx64Concat;
  const StorageHasher.twoxx128({required this.codec}) : hasher = StorageHasherType.twoxx128;
  const StorageHasher.twoxx128Concat({required this.codec})
    : hasher = StorageHasherType.twoxx128Concat;
  const StorageHasher.twoxx256({required this.codec}) : hasher = StorageHasherType.twoxx256;

  Expression instance(typegen.BasePath from) {
    return hasher.instance(codec.codecInstance(from), from);
  }

  factory StorageHasher.fromMetadata({
    required metadata.StorageHasherEnum hasher,
    required G codec,
  }) {
    return switch (hasher) {
      metadata.StorageHasherEnum.blake2_128 => StorageHasher.blake128(codec: codec),
      metadata.StorageHasherEnum.blake2_128Concat => StorageHasher.blake128Concat(codec: codec),
      metadata.StorageHasherEnum.blake2_256 => StorageHasher.blake256(codec: codec),
      metadata.StorageHasherEnum.twox64Concat => StorageHasher.twoxx64Concat(codec: codec),
      metadata.StorageHasherEnum.twox128 => StorageHasher.twoxx128(codec: codec),
      metadata.StorageHasherEnum.twox256 => StorageHasher.twoxx256(codec: codec),
      metadata.StorageHasherEnum.identity => StorageHasher.identity(codec: codec),
    };
  }
}

class Storage {
  /// Variable name of the storage entry.
  final String name;

  /// A type of storage value.
  final List<StorageHasher> hashers;

  /// Type of the value stored
  final typegen.TypeDescriptor valueCodec;

  /// Default value (SCALE encoded)
  final List<int> defaultValue;

  /// Storage entry documentation.
  final List<String> docs;

  /// The storage entry returns an `Option<T>`, with `None` if the key is not present.
  final bool isNullable;

  const Storage({
    required this.name,
    required this.hashers,
    required this.valueCodec,
    required this.defaultValue,
    this.isNullable = false,
    this.docs = const [],
  });

  factory Storage.fromMetadata(
    metadata.StorageEntryMetadata storageMetadata,
    Map<int, typegen.TypeDescriptor> registry,
  ) {
    final type = storageMetadata.type;
    final List<StorageHasher> hashers;
    final typegen.TypeDescriptor valueCodec;

    switch (type) {
      case metadata.StorageEntryTypePlain(:final valueType):
        valueCodec = registry[valueType]!;
        hashers = [];

      case metadata.StorageEntryTypeMap(
        :final keyType,
        :final valueType,
        hashers: final metadataHashers,
      ):
        valueCodec = registry[valueType]!;
        final List<typegen.TypeDescriptor> keysCodec;

        if (metadataHashers.isEmpty) {
          throw Exception('Invalid storage, hashers cannot be empty for map storage');
        } else if (metadataHashers.length == 1) {
          keysCodec = [registry[keyType]!];
        } else {
          final tupleCodec = registry[keyType]! as typegen.TupleBuilder;
          keysCodec = tupleCodec.generators;
        }

        if (keysCodec.length != metadataHashers.length) {
          throw Exception('Invalid storage, hasher\'s amount does not match key\'s amount');
        }

        hashers = [
          for (int i = 0; i < metadataHashers.length; i++)
            StorageHasher.fromMetadata(hasher: metadataHashers[i], codec: keysCodec[i]),
        ];
    }

    return Storage(
      name: storageMetadata.name,
      hashers: hashers,
      valueCodec: valueCodec,
      defaultValue: storageMetadata.defaultValue,
      isNullable: storageMetadata.modifier == metadata.StorageEntryModifier.optional,
      docs: storageMetadata.docs,
    );
  }

  TypeReference type(String from) {
    switch (hashers.length) {
      case 0:
        return refs.storageValue(valueCodec.primitive(from));
      case 1:
        return refs.storageMap(
          key: hashers[0].codec.primitive(from),
          value: valueCodec.primitive(from),
        );
      case 2:
        return refs.storageDoubleMap(
          key1: hashers[0].codec.primitive(from),
          key2: hashers[1].codec.primitive(from),
          value: valueCodec.primitive(from),
        );
      case 3:
        return refs.storageTripleMap(
          key1: hashers[0].codec.primitive(from),
          key2: hashers[1].codec.primitive(from),
          key3: hashers[2].codec.primitive(from),
          value: valueCodec.primitive(from),
        );
      case 4:
        return refs.storageQuadrupleMap(
          key1: hashers[0].codec.primitive(from),
          key2: hashers[1].codec.primitive(from),
          key3: hashers[2].codec.primitive(from),
          key4: hashers[3].codec.primitive(from),
          value: valueCodec.primitive(from),
        );
      case 5:
        return refs.storageQuintupleMap(
          key1: hashers[0].codec.primitive(from),
          key2: hashers[1].codec.primitive(from),
          key3: hashers[2].codec.primitive(from),
          key4: hashers[3].codec.primitive(from),
          key5: hashers[4].codec.primitive(from),
          value: valueCodec.primitive(from),
        );
      case 6:
        return refs.storageSextupleMap(
          key1: hashers[0].codec.primitive(from),
          key2: hashers[1].codec.primitive(from),
          key3: hashers[2].codec.primitive(from),
          key4: hashers[3].codec.primitive(from),
          key5: hashers[4].codec.primitive(from),
          key6: hashers[5].codec.primitive(from),
          value: valueCodec.primitive(from),
        );
      default:
        throw Exception('Invalid hashers length');
    }
  }

  Expression instance(typegen.BasePath from, String palletName) {
    final Map<String, Expression> arguments = {
      'prefix': literalString(palletName),
      'storage': literalString(name),
      'valueCodec': valueCodec.codecInstance(from),
    };

    if (hashers.length == 1) {
      arguments['hasher'] = hashers[0].instance(from);
    } else {
      for (int i = 0; i < hashers.length; i++) {
        arguments['hasher${i + 1}'] = hashers[i].instance(from);
      }
    }

    return type(from).constInstance([], arguments);
  }
}

class Tx {
  final String name;
  final List<typegen.Field> fields;
  final typegen.TypeDescriptor codec;
  final int index;
  final List<String> docs;

  const Tx({
    required this.name,
    required this.fields,
    required this.index,
    required this.docs,
    required this.codec,
  });

  factory Tx.fromMetadata(
    typegen.Variant callMetadata,
    int type,
    Map<int, typegen.TypeDescriptor> registry,
  ) {
    final typeDescriptor = registry[type]!;

    return Tx(
      name: callMetadata.name,
      fields: callMetadata.fields
          .map(
            (field) => typegen.Field(
              originalName: field.originalName,
              codec: field.codec,
              docs: field.docs,
            ),
          )
          .toList(),
      index: callMetadata.index,
      codec: typeDescriptor,
      docs: callMetadata.docs,
    );
  }
}

class Constant {
  final String name;
  final List<int> value;
  final typegen.TypeDescriptor codec;
  final List<String> docs;

  const Constant({
    required this.name,
    required this.value,
    required this.codec,
    required this.docs,
  });

  factory Constant.fromMetadata(
    metadata.PalletConstantMetadata constantMetadata,
    Map<int, typegen.TypeDescriptor> registry,
  ) {
    // Build pallet
    return Constant(
      name: constantMetadata.name,
      value: constantMetadata.value,
      codec: registry[constantMetadata.type]!,
      docs: constantMetadata.docs,
    );
  }
}

class PalletGenerator {
  String filePath;
  String name;
  List<Storage> storages;
  // List<Tx> txs;
  List<Constant> constants;
  typegen.VariantBuilder? calls;
  typegen.VariantBuilder runtimeCall;

  PalletGenerator({
    required this.filePath,
    required this.name,
    required this.storages,
    // required this.txs,
    required this.constants,
    required this.calls,
    required this.runtimeCall,
  });

  factory PalletGenerator.fromMetadata({
    required String filePath,
    required metadata.PalletMetadata palletMetadata,
    required Map<int, typegen.TypeDescriptor> registry,
    required Map<String, int> outerEnums,
  }) {
    // Load storages
    final List<Storage>? storages = palletMetadata.storage?.entries
        .map((storageMetadata) => Storage.fromMetadata(storageMetadata, registry))
        .toList();

    // Load runtime call
    final runtimeCallType = registry[outerEnums['call']]!;

    // Load calls
    var callType = palletMetadata.calls != null ? registry[palletMetadata.calls!.type] : null;
    if (callType != null) {
      while (callType is typegen.TypeDefBuilder) {
        callType = callType.generator;
      }
      if (callType is typegen.EmptyDescriptor) {
        callType = null;
      } else if (callType is! typegen.VariantBuilder) {
        throw Exception('Invalid runtime call type "${callType.runtimeType}"');
      }
    }

    // Load constants
    final List<Constant> constants = palletMetadata.constants
        .map((constantMetadata) => Constant.fromMetadata(constantMetadata, registry))
        .toList();

    // Build pallet
    return PalletGenerator(
      filePath: filePath,
      name: palletMetadata.name,
      storages: storages ?? [],
      constants: constants,
      calls: callType as typegen.VariantBuilder?,
      runtimeCall: runtimeCallType as typegen.VariantBuilder,
    );
  }

  TypeReference queries(typegen.BasePath from) {
    return TypeReference(
      (b) => b
        ..symbol = 'Queries'
        ..url = p.relative(filePath, from: from),
    );
  }

  TypeReference exts(typegen.BasePath from) {
    return TypeReference(
      (b) => b
        ..symbol = 'Txs'
        ..url = p.relative(filePath, from: from),
    );
  }

  TypeReference constantsType(typegen.BasePath from) {
    return TypeReference(
      (b) => b
        ..symbol = 'Constants'
        ..url = p.relative(filePath, from: from),
    );
  }

  typegen.GeneratedOutput generated() {
    final List<Class> classes = [];
    if (storages.isNotEmpty) {
      classes.add(createPalletQueries(this));
    }
    if (calls != null) {
      classes.add(createPalletTxs(this, calls!, runtimeCall));
    }
    if (constants.isNotEmpty) {
      classes.add(createPalletConstants(this));
    }
    return typegen.GeneratedOutput(classes: classes, enums: [], typedefs: []);
  }
}

Class createPalletQueries(PalletGenerator generator) => Class((classBuilder) {
  final dirname = p.dirname(generator.filePath);
  classBuilder
    ..name = 'Queries'
    ..constructors.add(
      Constructor(
        (b) => b
          ..constant = true
          ..requiredParameters.add(
            Parameter(
              (b) => b
                ..toThis = true
                ..required = false
                ..named = false
                ..name = '__api',
            ),
          ),
      ),
    )
    ..fields.add(
      Field(
        (b) => b
          ..name = '__api'
          ..type = refs.stateApi
          ..modifier = FieldModifier.final$,
      ),
    )
    ..fields.addAll(
      generator.storages.map(
        (storage) => Field(
          (b) => b
            ..name = '_${ReCase(storage.name).camelCase}'
            ..type = storage.type(dirname)
            ..modifier = FieldModifier.final$
            ..assignment = storage.instance(dirname, generator.name).code,
        ),
      ),
    )
    ..methods.addAll(
      generator.storages.map(
        (storage) => Method((builder) {
          final storageName = ReCase(storage.name).camelCase;
          final Reference primitive;
          if (storage.isNullable) {
            primitive = storage.valueCodec.primitive(dirname).asNullable();
          } else {
            primitive = storage.valueCodec.primitive(dirname);
          }
          builder
            ..name = sanitize(storageName, recase: false)
            ..docs.addAll(sanitizeDocs(storage.docs))
            ..returns = refs.future(primitive)
            ..modifier = MethodModifier.async
            ..optionalParameters.add(
              Parameter(
                (b) => b
                  ..type = refs.blockHash.asNullable()
                  ..named = true
                  ..name = 'at',
              ),
            )
            ..requiredParameters.addAll(
              storage.hashers.map(
                (hasher) => Parameter(
                  (b) => b
                    ..type = hasher.codec.primitive(dirname)
                    ..name = 'key${storage.hashers.indexOf(hasher) + 1}',
                ),
              ),
            )
            ..body = Block(
              (b) => b
                // final hashedKey = _storageName.hashedKeyFor(key1);
                ..statements.add(
                  declareFinal('hashedKey').assignHashedKey(storageName, storage).statement,
                )
                // final bytes = await api.queryStorage([hashedKey]);
                ..statements.add(
                  declareFinal('bytes')
                      .assign(
                        refer('__api')
                            .property('getStorage')
                            .call([refer('hashedKey')], {'at': refer('at')})
                            .awaited,
                      )
                      .statement,
                )
                ..statements.add(Code('if (bytes != null) {'))
                ..statements.add(Code('  return _$storageName.decodeValue(bytes);'))
                ..statements.add(Code('}'))
                ..statements.add(
                  storage.isNullable
                      ? Code('return null; /* Nullable */')
                      : storage.valueCodec
                            .valueFrom(dirname, ByteInput(Uint8List.fromList(storage.defaultValue)))
                            .returned
                            .statement,
                )
                ..statements.add(storage.isNullable ? Code('') : Code('/* Default */')),
            );
        }),
      ),
    )
    ..methods.addAll(
      generator.storages
          // We don't support multi queries with multiple keys yet.
          .where((storage) => storage.hashers.isNotEmpty && storage.hashers.length < 2)
          .map(
            (storage) => Method((builder) {
              final storageName = ReCase(storage.name).camelCase;
              final Reference primitive;
              if (storage.isNullable) {
                primitive = storage.valueCodec.primitive(dirname).asNullable();
              } else {
                primitive = storage.valueCodec.primitive(dirname);
              }
              builder
                ..name = sanitize('multi${ReCase(storageName).pascalCase}', recase: false)
                ..docs.addAll(sanitizeDocs(storage.docs))
                ..returns = refs.future(refs.list(ref: primitive))
                ..modifier = MethodModifier.async
                ..optionalParameters.add(
                  Parameter(
                    (b) => b
                      ..type = refs.blockHash.asNullable()
                      ..named = true
                      ..name = 'at',
                  ),
                )
                ..requiredParameters.addAll(
                  storage.hashers.map(
                    (hasher) => Parameter(
                      (b) => b
                        ..type = refs.list(ref: hasher.codec.primitive(dirname))
                        ..name = 'keys',
                    ),
                  ),
                )
                ..body = Block(
                  (b) => b
                    ..statements.add(
                      declareFinal('hashedKeys')
                          .assign(
                            refer('keys').property('map').call([
                              Method(
                                (b) => b
                                  ..lambda = true
                                  ..requiredParameters.add(Parameter((p) => p..name = 'key'))
                                  ..body = refer(
                                    '_$storageName',
                                  ).property('hashedKeyFor').call([refer('key')]).code,
                              ).closure,
                            ]),
                          )
                          .property('toList()')
                          .statement,
                    )
                    ..statements.add(
                      declareFinal('bytes')
                          .assign(
                            refer('__api')
                                .property('queryStorageAt')
                                .call([refer('hashedKeys')], {'at': refer('at')})
                                .awaited,
                          )
                          .statement,
                    )
                    ..statements.add(Code('if (bytes.isNotEmpty) {'))
                    ..statements.add(
                      storage.isNullable
                          ? Code(
                              '  return bytes.first.changes.map((v) => v.value != null ? _$storageName.decodeValue(v.value!) : null).toList();',
                            )
                          : () {
                              // Check if we need to cast the default value for Sequence/Array types
                              typegen.TypeDescriptor actualCodec = storage.valueCodec;
                              while (actualCodec is typegen.TypeDefBuilder) {
                                actualCodec = actualCodec.generator;
                              }
                              final needsCast =
                                  (actualCodec is typegen.SequenceDescriptor &&
                                      actualCodec.typeDef is! typegen.PrimitiveDescriptor) ||
                                  (actualCodec is typegen.ArrayDescriptor &&
                                      actualCodec.typeDef is! typegen.PrimitiveDescriptor);

                              final baseDefaultValueExpr = storage.valueCodec.valueFrom(
                                dirname,
                                ByteInput(Uint8List.fromList(storage.defaultValue)),
                              );

                              final Expression defaultValueExpr = needsCast
                                  ? baseDefaultValueExpr.asA(storage.valueCodec.primitive(dirname))
                                  : baseDefaultValueExpr;

                              return Block.of([
                                declareFinal('defaultValue').assign(defaultValueExpr).statement,
                                Code(
                                  '  return bytes.first.changes.map((v) => v.value != null ? _$storageName.decodeValue(v.value!) : defaultValue).toList();',
                                ),
                              ]);
                            }(),
                    )
                    ..statements.add(Code('}'))
                    ..statements.add(
                      storage.isNullable
                          ? Code('return []; /* Nullable */')
                          : () {
                              // Build the base expression
                              var expr = refer('keys')
                                  .property('map')
                                  .call([
                                    Method(
                                      (b) => b
                                        ..lambda = true
                                        ..requiredParameters.add(Parameter((p) => p..name = 'key'))
                                        ..body = storage.valueCodec
                                            .valueFrom(
                                              dirname,
                                              ByteInput(Uint8List.fromList(storage.defaultValue)),
                                            )
                                            .code,
                                    ).closure,
                                  ])
                                  .property('toList()');

                              // Only add cast for Sequence and Array types (needed for empty list defaults) but not for primitive sequences (they use List<int>.filled which has explicit type). Unwrap typedefs to get the actual underlying type
                              typegen.TypeDescriptor actualCodec = storage.valueCodec;
                              while (actualCodec is typegen.TypeDefBuilder) {
                                actualCodec = actualCodec.generator;
                              }

                              final needsCast =
                                  (actualCodec is typegen.SequenceDescriptor &&
                                      actualCodec.typeDef is! typegen.PrimitiveDescriptor) ||
                                  (actualCodec is typegen.ArrayDescriptor &&
                                      actualCodec.typeDef is! typegen.PrimitiveDescriptor);

                              if (needsCast) {
                                expr = expr.asA(
                                  refs.list(ref: storage.valueCodec.primitive(dirname)),
                                );
                              }

                              return expr.returned.statement;
                            }(),
                    )
                    ..statements.add(storage.isNullable ? Code('') : Code('/* Default */')),
                );
            }),
          ),
    )
    ..methods.addAll(
      generator.storages.map(
        (storage) => Method((builder) {
          final storageName = ReCase(storage.name).camelCase;
          builder
            ..name = sanitize(storage.keyMethodName(), recase: false)
            ..docs.addAll(sanitizeDocs(['Returns the storage key for `$storageName`.']))
            ..returns = refs.uint8List
            ..requiredParameters.addAll(
              storage.hashers.map(
                (hasher) => Parameter(
                  (b) => b
                    ..type = hasher.codec.primitive(dirname)
                    ..name = 'key${storage.hashers.indexOf(hasher) + 1}',
                ),
              ),
            )
            ..body = Block(
              (b) => b
                ..statements.add(
                  declareFinal('hashedKey').assignHashedKey(storageName, storage).statement,
                )
                ..statements.add(Code('  return hashedKey;')),
            );
        }),
      ),
    )
    ..methods.addAll(
      generator.storages
          // We don't support maps with depth > 2 yet.
          .where((storage) => storage.hashers.isNotEmpty && storage.hashers.length < 3)
          .map(
            (storage) => Method((builder) {
              final storageName = ReCase(storage.name).camelCase;
              builder
                ..name = sanitize(storage.mapPrefixMethodName(), recase: false)
                ..docs.addAll(
                  sanitizeDocs(['Returns the storage map key prefix for `$storageName`.']),
                )
                ..returns = refs.uint8List
                ..requiredParameters.addAll(
                  storage.hashers
                      .getRange(0, storage.hashers.length - 1)
                      .map(
                        (hasher) => Parameter(
                          (b) => b
                            ..type = hasher.codec.primitive(dirname)
                            ..name = 'key${storage.hashers.indexOf(hasher) + 1}',
                        ),
                      ),
                )
                ..body = Block(
                  (b) => b
                    ..statements.add(
                      declareFinal('hashedKey').assignMapPrefix(storageName, storage).statement,
                    )
                    ..statements.add(Code('  return hashedKey;')),
                );
            }),
          ),
    );
});

Class createPalletTxs(
  PalletGenerator generator,
  typegen.VariantBuilder variants,
  typegen.VariantBuilder runtimeVariant,
) => Class((classBuilder) {
  final dirname = p.dirname(generator.filePath);

  final runtimeGenerator = runtimeVariant.variants.first.generator;
  final runtimePrimitive = runtimeGenerator.primitive(dirname);
  // Find the matching variant by original name (case-insensitive match)
  final matchingVariant = runtimeVariant.variants.firstWhere(
    (v) => v.originalName.toLowerCase() == generator.name.toLowerCase(),
    orElse: () =>
        throw Exception('Could not find runtime call variant for pallet "${generator.name}"'),
  );
  final runtimeCall = refer(matchingVariant.name, runtimePrimitive.url);

  final isEnumClass = variants.variants.every((variant) => variant.fields.isEmpty);
  classBuilder
    ..name = 'Txs'
    ..constructors.add(Constructor((b) => b..constant = true))
    ..methods.addAll(
      variants.variants.map(
        (variant) => Method((builder) {
          final Reference primitive = variant.primitive(dirname);
          final Reference callPrimitive = variants.primitive(dirname);

          builder
            ..name = typegen.Field.toFieldName(variant.name)
            ..docs.addAll(sanitizeDocs(variant.docs))
            // ..returns = isEnumClass ? runtimePrimitive : primitive
            ..returns = runtimeCall
            ..optionalParameters.addAll(
              variant.fields.map(
                (field) => Parameter(
                  (b) => b
                    ..required = field.codec.primitive(dirname).isNullable != true
                    ..named = true
                    ..name = field.sanitizedName
                    ..type = field.codec.primitive(dirname),
                ),
              ),
            )
            ..body = Block((b) {
              Expression expression;

              if (isEnumClass == false) {
                // not an simple enum class, contains parametrized fields.
                expression = runtimeCall.call([
                  primitive.call([], {
                    for (final field in variant.fields)
                      field.sanitizedName: CodeExpression(Code(field.sanitizedName)),
                  }),
                ]);
              } else {
                // simple enum class no need to call () constructor
                // instead leaving it as a property.
                expression = runtimeCall.call([
                  callPrimitive.property(typegen.Field.toFieldName(variant.name)),
                ]);
              }

              b.statements.add(expression.returned.statement);
            });
        }),
      ),
    );
});

Class createPalletConstants(PalletGenerator generator) => Class((classBuilder) {
  final dirname = p.dirname(generator.filePath);
  classBuilder
    ..name = 'Constants'
    ..constructors.add(Constructor((b) => b..constant = false))
    ..fields.addAll(
      generator.constants.map(
        (constant) => Field(
          (b) => b
            ..name = sanitize(constant.name)
            ..type = constant.codec.primitive(dirname)
            ..modifier = FieldModifier.final$
            ..docs.addAll(sanitizeDocs(constant.docs))
            ..assignment = constant.codec
                .valueFrom(dirname, ByteInput(Uint8List.fromList(constant.value)), constant: true)
                .code,
        ),
      ),
    );
});

extension MethodNameExtension on Storage {
  /// Name of the generated method returning the key of a storage.
  String keyMethodName() {
    return '${name}Key';
  }

  /// Name of the generated method returning the key prefix of a storage.
  String mapPrefixMethodName() {
    return '${name}MapPrefix';
  }
}

extension AssignHashedKeyExtension on Expression {
  Expression assignHashedKey(String storageName, Storage storage) {
    return assign(
      refer('_$storageName')
          .property(storage.hashers.isEmpty ? 'hashedKey' : 'hashedKeyFor')
          .call(
            storage.hashers.map((hasher) => refer('key${storage.hashers.indexOf(hasher) + 1}')),
          ),
    );
  }

  Expression assignMapPrefix(String storageName, Storage storage) {
    if (storage.hashers.isEmpty) {
      throw Exception('Bad code generation path; can\'t create keyPrefix method without hashers.');
    }

    if (storage.hashers.length > 2) {
      throw Exception(
        'Bad code generation path; keyPrefix method for maps with depth > 2 are not supported yet.',
      );
    }

    return assign(
      refer('_$storageName')
          .property('mapPrefix')
          .call(
            storage.hashers
                // Checked above that hasher is not empty.
                .getRange(0, storage.hashers.length - 1)
                .map((hasher) => refer('key${storage.hashers.indexOf(hasher) + 1}')),
          ),
    );
  }
}
