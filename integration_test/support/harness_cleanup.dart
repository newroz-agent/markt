import 'package:supabase_flutter/supabase_flutter.dart';

/// Removes the storage objects a live harness uploaded and fails loudly when
/// any of them survives, so a run never leaves orphaned files behind.
Future<List<String>> removeUploadedObjects(
  SupabaseClient client, {
  required String bucket,
  required List<String> paths,
}) async {
  if (paths.isEmpty) return const <String>[];
  final removed = await client.storage.from(bucket).remove(paths);
  final removedNames = removed.map((object) => object.name).toSet();
  final missing = paths.where((path) => !removedNames.contains(path)).toList();
  if (missing.isNotEmpty) {
    throw StateError(
      'Harness cleanup could not remove $bucket objects: $missing',
    );
  }
  return paths;
}

/// Lists the full paths of the files directly inside [folder].
Future<Set<String>> listObjectPaths(
  SupabaseClient client, {
  required String bucket,
  required String folder,
}) async {
  final entries = await client.storage.from(bucket).list(path: folder);
  return <String>{
    for (final entry in entries)
      if (entry.id != null) '$folder/${entry.name}',
  };
}

/// Counts every object in a bucket through the Storage service's flat,
/// cursor-paginated listing. Folder placeholders are never counted.
Future<int> countStorageObjects(
  SupabaseClient client, {
  required String bucket,
}) async {
  const pageSize = 1000;
  String? cursor;
  var count = 0;
  while (true) {
    final page = await client.storage
        .from(bucket)
        .listPaginated(
          options: PaginatedSearchOptions(
            limit: pageSize,
            cursor: cursor,
            withDelimiter: false,
          ),
        );
    count += page.objects.length;
    if (!page.hasNext) return count;
    final nextCursor = page.nextCursor;
    if (nextCursor == null || nextCursor == cursor) {
      throw StateError('Storage pagination did not advance for $bucket.');
    }
    cursor = nextCursor;
  }
}
