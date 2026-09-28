// Shared by every test (and tool) that renders art: loads it from the
// assets/svg/ files on disk, the same way the app loads them at startup.
import 'dart:io';

import 'package:fudatobashi/config/vector_art_assets.dart';

void loadTestVectorArt() => loadVectorArtSync((path) => File(path).readAsStringSync());
