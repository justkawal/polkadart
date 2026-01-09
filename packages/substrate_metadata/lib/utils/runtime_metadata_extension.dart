part of utils;

/// Extension methods to provide a common interface for RuntimeMetadata variants
extension RuntimeMetadataExtensions on RuntimeMetadata {
  /// Get the list of pallets
  List<PalletMetadata> get pallets {
    return switch (this) {
      final RuntimeMetadataV14 v14 => v14.pallets,
      final RuntimeMetadataV15 v15 => v15.pallets,
      final RuntimeMetadataV16 v16 => v16.pallets,
    };
  }

  /// Get extrinsic metadata
  ExtrinsicMetadata get extrinsic {
    return switch (this) {
      final RuntimeMetadataV14 v14 => v14.extrinsic,
      final RuntimeMetadataV15 v15 => v15.extrinsic,
      final RuntimeMetadataV16 v16 => v16.extrinsic,
    };
  }

  List<PortableType> get types {
    return switch (this) {
      final RuntimeMetadataV14 v14 => v14.types,
      final RuntimeMetadataV15 v15 => v15.types,
      final RuntimeMetadataV16 v16 => v16.types,
    };
  }

  /// Get outer enum types
  ///
  /// For V15/V16, returns the direct outer enum references.
  /// For V14, returns the call type from extrinsic metadata.
  OuterEnums get outerEnums {
    return switch (this) {
      final RuntimeMetadataV14 v14 => OuterEnums(
        callType: v14.extrinsic.callType,
        eventType: -1,
        errorType: -1,
      ),
      final RuntimeMetadataV15 v15 => OuterEnums(
        callType: v15.outerEnums.callType,
        eventType: v15.outerEnums.eventType,
        errorType: v15.outerEnums.errorType,
      ),
      final RuntimeMetadataV16 v16 => OuterEnums(
        callType: v16.outerEnums.callType,
        eventType: v16.outerEnums.eventType,
        errorType: v16.outerEnums.errorType,
      ),
    };
  }
}
