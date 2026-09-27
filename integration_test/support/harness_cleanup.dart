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
