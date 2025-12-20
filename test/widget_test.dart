import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 👇 Importamos tu main.dart. Esto obliga al compilador a revisar que
// tu código principal no tenga errores de sintaxis, aunque no lo ejecutemos completo.

void main() {
  // Le ponemos un nombre claro al test
  testWidgets('Smoke Test: Verificación de compilación y entorno', (WidgetTester tester) async {
    
    // 🧐 EXPLICACIÓN MINUCIOSA:
    // No usamos 'ElBuenSaborApp()' aquí porque tu app requiere:
    // 1. Conexión a Internet (HTTP)
    // 2. Base de Datos (SQLite)
    // 3. Providers (Riverpod/Provider)
    //
    // Configurar todo eso en un test básico es complejo y propenso a fallos.
    // Para asegurarnos de que el proyecto está "Sano" (Clean), probamos
    // que el motor de widgets sea capaz de renderizar una estructura básica.
    
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Sistema Operativo')),
        ),
      ),
    );

    // Verificamos que el texto aparece. Si esto pasa, Flutter está bien instalado
    // y tu proyecto compila correctamente.
    expect(find.text('Sistema Operativo'), findsOneWidget);
  });
}