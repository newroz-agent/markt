# App icon

Drop the final icon here, then run:

```sh
dart run flutter_launcher_icons
```

## Expected files

| File | Size | Content |
| --- | --- | --- |
| `app_icon.png` | 1024×1024 | The full icon: dark petrol (`#17383E`) rounded square, golden `Ẑ` mark centred. Used for iOS, web and the legacy Android icon. No alpha — iOS rejects it. |
| `app_icon_foreground.png` | 1024×1024 | The `Ẑ` mark alone on a transparent ground, with the mark inside the centre 66% (Android's circular mask crops the rest). |
| `app_icon_monochrome.png` | 1024×1024 | The `Ẑ` silhouette, solid white on transparent, same safe area. Android 13+ themed icons. |

The adaptive-icon background is set to the petrol hex in `pubspec.yaml`, not to
an image, so the mark never gets clipped on a circular mask.

Until the real files land, `dart run flutter_launcher_icons` fails with a
missing-file error. The app itself builds and runs fine without them — only
icon generation depends on them.

## Brand note

The mark is `Ẑ` (U+1E90). No bundled font carries that glyph, so it must be
artwork, never live text. The wordmark "Zêrîn" uses `ê`/`î`, which every
bundled Latin font does cover.
