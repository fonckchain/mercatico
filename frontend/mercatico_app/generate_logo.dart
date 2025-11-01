import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🎨 Generando logos de MercaTico...');

  // Generar logo completo (con fondo verde)
  await generateLogo(
    'assets/images/logo.png',
    size: 1024,
    withBackground: true,
  );
  print('✅ Logo principal generado: assets/images/logo.png');

  // Generar logo foreground (solo ícono, sin fondo)
  await generateLogo(
    'assets/images/logo_foreground.png',
    size: 1024,
    withBackground: false,
  );
  print('✅ Logo foreground generado: assets/images/logo_foreground.png');

  print('');
  print('🚀 Logos generados exitosamente!');
  print('📝 Ahora ejecuta: flutter pub run flutter_launcher_icons');

  exit(0);
}

Future<void> generateLogo(String outputPath, {required int size, required bool withBackground}) async {
  // Crear un widget con el ícono
  final widget = Container(
    width: size.toDouble(),
    height: size.toDouble(),
    decoration: withBackground ? BoxDecoration(
      color: const Color(0xFF4CAF50), // Verde MercaTico
      borderRadius: BorderRadius.circular(size * 0.2), // Bordes redondeados
    ) : null,
    child: Center(
      child: Icon(
        Icons.store,
        size: withBackground ? size * 0.6 : size * 0.7, // Más grande sin fondo
        color: Colors.white,
      ),
    ),
  );

  // Convertir widget a imagen
  final repaintBoundary = RenderRepaintBoundary();
  final view = ui.PlatformDispatcher.instance.views.first;
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(
      alignment: Alignment.center,
      child: repaintBoundary,
    ),
    configuration: ViewConfiguration(
      size: Size(size.toDouble(), size.toDouble()),
      devicePixelRatio: 1.0,
    ),
  );

  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(focusManager: FocusManager());

  // Renderizar el widget
  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
    container: repaintBoundary,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: widget,
    ),
  ).attachToRenderTree(buildOwner);

  buildOwner.buildScope(rootElement);
  buildOwner.finalizeTree();

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  // Capturar la imagen
  final image = await repaintBoundary.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Crear directorio si no existe
  final file = File(outputPath);
  await file.parent.create(recursive: true);

  // Guardar archivo
  await file.writeAsBytes(bytes);
}
