// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatRepositoryHash() => r'56b7e9c8e90b3dd75d09ef062f62d97ba4d5638b';

/// See also [chatRepository].
@ProviderFor(chatRepository)
final chatRepositoryProvider = Provider<ChatRepository>.internal(
  chatRepository,
  name: r'chatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatRepositoryRef = ProviderRef<ChatRepository>;
String _$chatInboxHash() => r'be42ea46a93150b9f18764ffa878d9a7058f9a39';

/// See also [chatInbox].
@ProviderFor(chatInbox)
final chatInboxProvider =
    AutoDisposeStreamProvider<List<ChatConversation>>.internal(
      chatInbox,
      name: r'chatInboxProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chatInboxHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatInboxRef = AutoDisposeStreamProviderRef<List<ChatConversation>>;
String _$unreadChatCountHash() => r'7fe630ec7eb92f9f18859b0e3922fc949dcb5e87';

/// See also [unreadChatCount].
@ProviderFor(unreadChatCount)
final unreadChatCountProvider = AutoDisposeFutureProvider<int>.internal(
  unreadChatCount,
  name: r'unreadChatCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadChatCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadChatCountRef = AutoDisposeFutureProviderRef<int>;
String _$chatDetailsHash() => r'7e1fd4433d8580233f2f07ba5065b3f168d9605f';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [chatDetails].
@ProviderFor(chatDetails)
const chatDetailsProvider = ChatDetailsFamily();

/// See also [chatDetails].
class ChatDetailsFamily extends Family<AsyncValue<ChatConversation?>> {
  /// See also [chatDetails].
  const ChatDetailsFamily();

  /// See also [chatDetails].
  ChatDetailsProvider call({required String chatId}) {
    return ChatDetailsProvider(chatId: chatId);
  }

  @override
  ChatDetailsProvider getProviderOverride(
    covariant ChatDetailsProvider provider,
  ) {
    return call(chatId: provider.chatId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatDetailsProvider';
}

/// See also [chatDetails].
class ChatDetailsProvider extends AutoDisposeFutureProvider<ChatConversation?> {
  /// See also [chatDetails].
  ChatDetailsProvider({required String chatId})
    : this._internal(
        (ref) => chatDetails(ref as ChatDetailsRef, chatId: chatId),
        from: chatDetailsProvider,
        name: r'chatDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatDetailsHash,
        dependencies: ChatDetailsFamily._dependencies,
        allTransitiveDependencies: ChatDetailsFamily._allTransitiveDependencies,
        chatId: chatId,
      );

  ChatDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatId,
  }) : super.internal();

  final String chatId;

  @override
  Override overrideWith(
    FutureOr<ChatConversation?> Function(ChatDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatDetailsProvider._internal(
        (ref) => create(ref as ChatDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatId: chatId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ChatConversation?> createElement() {
    return _ChatDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatDetailsProvider && other.chatId == chatId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatDetailsRef on AutoDisposeFutureProviderRef<ChatConversation?> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ChatDetailsProviderElement
    extends AutoDisposeFutureProviderElement<ChatConversation?>
    with ChatDetailsRef {
  _ChatDetailsProviderElement(super.provider);

  @override
  String get chatId => (origin as ChatDetailsProvider).chatId;
}

String _$conversationHash() => r'4e968b55557a0dec60fa5a3d9aee0e1a7804beca';

abstract class _$Conversation
    extends BuildlessAutoDisposeStreamNotifier<List<ChatMessage>> {
  late final String chatId;

  Stream<List<ChatMessage>> build({required String chatId});
}

/// See also [Conversation].
@ProviderFor(Conversation)
const conversationProvider = ConversationFamily();

/// See also [Conversation].
class ConversationFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [Conversation].
  const ConversationFamily();

  /// See also [Conversation].
  ConversationProvider call({required String chatId}) {
    return ConversationProvider(chatId: chatId);
  }

  @override
  ConversationProvider getProviderOverride(
    covariant ConversationProvider provider,
  ) {
    return call(chatId: provider.chatId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationProvider';
}

/// See also [Conversation].
class ConversationProvider
    extends
        AutoDisposeStreamNotifierProviderImpl<Conversation, List<ChatMessage>> {
  /// See also [Conversation].
  ConversationProvider({required String chatId})
    : this._internal(
        () => Conversation()..chatId = chatId,
        from: conversationProvider,
        name: r'conversationProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationHash,
        dependencies: ConversationFamily._dependencies,
        allTransitiveDependencies:
            ConversationFamily._allTransitiveDependencies,
        chatId: chatId,
      );

  ConversationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.chatId,
  }) : super.internal();

  final String chatId;

  @override
  Stream<List<ChatMessage>> runNotifierBuild(covariant Conversation notifier) {
    return notifier.build(chatId: chatId);
  }

  @override
  Override overrideWith(Conversation Function() create) {
    return ProviderOverride(
      origin: this,
      override: ConversationProvider._internal(
        () => create()..chatId = chatId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        chatId: chatId,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<Conversation, List<ChatMessage>>
  createElement() {
    return _ConversationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationProvider && other.chatId == chatId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, chatId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationRef
    on AutoDisposeStreamNotifierProviderRef<List<ChatMessage>> {
  /// The parameter `chatId` of this provider.
  String get chatId;
}

class _ConversationProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<
          Conversation,
          List<ChatMessage>
        >
    with ConversationRef {
  _ConversationProviderElement(super.provider);

  @override
  String get chatId => (origin as ConversationProvider).chatId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
