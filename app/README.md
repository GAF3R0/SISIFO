# Sisifo — App móvil de evaluación clínica

Herramienta Flutter para psicólogos que aplica el cuestionario **PHQ-9**, captura una foto del rostro del paciente y envía ambos datos a un agente IA para evaluar el riesgo de depresión.

## Requisitos

- Flutter SDK >= 3.3.0
- Servidor del agente corriendo (ver `../agent_server/`)
- Dispositivo físico o emulador con cámara

## Instalación

```bash
cd app
flutter pub get
flutter run
```

## Configuración del servidor del agente

La URL del agente está definida en `lib/providers/assessment_provider.dart`:

```dart
const String kAgentBaseUrl = 'http://10.0.2.2:8000'; // emulador Android
// Para dispositivo físico: usa la IP de tu máquina, ej: http://192.168.1.X:8000
```

## Estructura

```
lib/
├── main.dart                    # Entry point y configuración de rutas
├── models/
│   ├── phq9_result.dart         # Resultado del cuestionario
│   └── evaluation.dart          # Evaluación clínica completa
├── providers/
│   └── assessment_provider.dart # Estado global (Provider)
├── screens/
│   ├── login_screen.dart        # Login del psicólogo
│   ├── dashboard_screen.dart    # Panel principal
│   ├── phq9_screen.dart         # Cuestionario PHQ-9
│   ├── camera_screen.dart       # Captura de foto
│   ├── processing_screen.dart   # Envío y espera al agente
│   └── result_screen.dart       # Visualización de resultados
├── services/
│   ├── agent_service.dart       # HTTP al servidor del agente
│   └── auth_service.dart        # Autenticación de psicólogos
├── utils/
│   └── phq9_helper.dart         # Preguntas, opciones y colores PHQ-9
└── widgets/
    ├── question_card.dart       # Tarjeta de pregunta PHQ-9
    └── risk_badge.dart          # Badge visual de nivel de riesgo
```

## Flujo de la app

1. **Login** → Psicólogo inicia sesión
2. **Dashboard** → Ve evaluaciones previas, inicia nueva
3. **PHQ-9** → Ingresa nombre del paciente, responde 9 preguntas
4. **Cámara** → Captura foto frontal del rostro
5. **Procesamiento** → Envía PHQ-9 + foto al agente IA
6. **Resultado** → Muestra nivel de riesgo, recomendación y desglose

## TODOs pendientes

- [ ] Conectar autenticación real (Firebase Auth / Supabase)
- [ ] Persistir evaluaciones en SQLite
- [ ] Hacer configurable la URL del agente desde Settings
- [ ] Exportar evaluación como PDF
- [ ] Historial de evaluaciones desde la base de datos local
