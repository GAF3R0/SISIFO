import sys
from fpdf import FPDF

class SisifoPDF(FPDF):
    def header(self):
        self.set_font('DejaVu', 'B', 9)
        self.set_text_color(100, 100, 100)
        self.cell(0, 8, 'Proyecto Sísifo — Evaluación Clínica de Riesgo de Depresión (IA Multimodal)', border=0, align='L')
        self.cell(0, 8, 'Confidencial / Clínico', border=0, align='R')
        self.ln(10)
        self.set_draw_color(200, 200, 200)
        self.line(15, 18, 195, 18)

    def footer(self):
        self.set_y(-15)
        self.set_font('DejaVu', 'I', 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, f'Página {self.page_no()}/{{nb}}', align='C')

def create_pdf(output_path):
    pdf = SisifoPDF(orientation='P', unit='mm', format='A4')
    pdf.alias_nb_pages()
    
    # Register TrueType fonts with full UTF-8 support
    pdf.add_font('DejaVu', '', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
    pdf.add_font('DejaVu', 'B', '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf')
    pdf.add_font('DejaVu', 'I', '/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf')
    pdf.add_font('DejaVu', 'BI', '/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf')

    pdf.set_auto_page_break(auto=True, margin=18)
    pdf.set_margins(15, 22, 15)
    pdf.add_page()

    # Title Banner
    pdf.set_fill_color(46, 134, 171) # #2E86AB
    pdf.rect(15, 22, 180, 28, 'F')
    
    pdf.set_xy(18, 26)
    pdf.set_font('DejaVu', 'B', 15)
    pdf.set_text_color(255, 255, 255)
    pdf.cell(174, 8, 'PROYECTO SÍSIFO: ESPECIFICACIÓN TÉCNICA Y CLÍNICA', ln=True, align='L')
    
    pdf.set_xy(18, 36)
    pdf.set_font('DejaVu', '', 9.5)
    pdf.set_text_color(230, 240, 255)
    pdf.cell(174, 7, 'Evaluación de Riesgo de Depresión mediante PHQ-9 y Análisis Facial con IA On-Device', ln=True, align='L')

    pdf.ln(12)

    def h1(title):
        pdf.set_font('DejaVu', 'B', 12)
        pdf.set_text_color(30, 75, 105)
        pdf.cell(0, 8, title, ln=True)
        pdf.set_draw_color(46, 134, 171)
        pdf.set_line_width(0.4)
        pdf.line(pdf.get_x(), pdf.get_y(), pdf.get_x() + 180, pdf.get_y())
        pdf.ln(2.5)

    def h2(title):
        pdf.set_font('DejaVu', 'B', 10)
        pdf.set_text_color(50, 50, 50)
        pdf.cell(0, 6.5, title, ln=True)

    def body(text):
        pdf.set_font('DejaVu', '', 9)
        pdf.set_text_color(40, 40, 40)
        pdf.multi_cell(0, 4.8, text)
        pdf.ln(1.5)

    def bullet(text, bold_prefix=""):
        pdf.set_font('DejaVu', '', 9)
        pdf.set_text_color(40, 40, 40)
        pdf.cell(5, 4.8, '•', ln=False, align='R')
        pdf.cell(3, 4.8, ' ', ln=False)
        if bold_prefix:
            pdf.set_font('DejaVu', 'B', 9)
            pdf.write(4.8, bold_prefix)
            pdf.set_font('DejaVu', '', 9)
        pdf.multi_cell(172, 4.8, text)
        pdf.ln(1)

    # 1. Planteamiento del Problema
    h1('1. Planteamiento del Problema que Busca Resolver Sísifo')
    h2('1.1. Contexto y Relevancia Epidemiológica')
    body('Los trastornos depresivos constituyen una de las principales causas mundiales de discapacidad según la Organización Mundial de la Salud (OMS). A pesar de su alta prevalencia, una gran proporción de los casos no es diagnosticada oportunamente. En la práctica clínica cotidiana, la saturación del sistema de salud y la limitación de tiempo por consulta dificultan una evaluación longitudinal y multidimensional profunda.')

    h2('1.2. Limitaciones del Diagnóstico Basado Exclusivamente en Autorreporte')
    body('En la práctica estándar, el tamizaje inicial descansa en cuestionarios estandarizados de autorreporte, predominantemente el PHQ-9 (Patient Health Questionnaire-9). Si bien cuenta con respaldo psicométrico, presenta sesgos intrínsecos al sujeto:')
    bullet(' Pacientes que, por estigma social, mecanismos de defensa o temor al diagnóstico, minimizan u omiten conscientemente o inconscientemente la severidad de su malestar.', 'Minimización de síntomas:')
    bullet(' Pacientes con cuadros melancólicos que pueden aparentar estabilidad en sus respuestas numéricas, pero cuyos patrones neuromusculares reflejan desregulación afectiva.', 'Aplanamiento afectivo y disimulo:')
    bullet(' La carencia de biomarcadores complementarios deja al terapeuta sin un instrumento rápido que contraste lo que el paciente expresa verbalmente con sus respuestas psicofisiológicas.', 'Ausencia de marcadores objetivos:')

    h2('1.3. Riesgos de Privacidad con Datos Médicos y Biométricos')
    body('El uso generalizado de IA en salud suele depender de nubes centralizadas donde se transmiten fotografías o videos sin custodia estricta, transgrediendo la legislación de protección de datos personales y sensibles (como la LFPDPPP y las normas mexicanas NOM-004-SSA3-2012 y NOM-024-SSA3-2012).')

    h2('1.4. Definición del Problema Central')
    pdf.set_fill_color(240, 245, 250)
    pdf.rect(15, pdf.get_y(), 180, 16, 'F')
    pdf.set_font('DejaVu', 'I', 8.8)
    pdf.set_text_color(20, 60, 90)
    pdf.set_xy(18, pdf.get_y() + 2)
    pdf.multi_cell(174, 4.6, '¿Cómo proporcionar al profesional de la salud mental una herramienta ágil, no invasiva y científicamente respaldada que aumente la sensibilidad diagnóstica mediante la fusión de psicometría estandarizada y biomarcadores faciales, garantizando la privacidad absoluta del paciente mediante procesamiento local (Edge AI) y auditoría inmutable?')
    pdf.ln(5)

    # 2. Diseño del Sistema
    h1('2. Diseño del Sistema y Flujo Clínico')
    h2('2.1. Diseño Conceptual del Flujo Clínico')
    body('Sísifo opera como un Sistema de Soporte a la Decisión Clínica (CDSS - Clinical Decision Support System). Su flujo secuencial contempla: (1) Autenticación profesional -> (2) Consentimiento informado digital expreso -> (3) Aplicación del test PHQ-9 de 9 reactivos -> (4) Captura fotográfica frontal guiada -> (5) Inferencia multimodal on-device -> (6) Generación de indicador de riesgo y expediente/auditoría inmutable.')

    h2('2.2. Arquitectura de Software por Capas (Local-First)')
    bullet(' Construida en Flutter (Material 3), con interfaces limpias y adaptadas al entorno clínico profesional.', 'Capa de Presentación:')
    bullet(' Centralizada con Provider (ChangeNotifier), desacoplando estado clínico y vistas.', 'Capa de Gestión de Estado:')
    bullet(' Agente multimodal dual: motor autónomo local en Dart (LocalSisifoAgent) y servidor de soporte opcional en FastAPI (Python).', 'Capa de Inteligencia Artificial:')
    bullet(' Base de datos local cifrada en reposo mediante SQLCipher (AES-256) y sincronización segura con MongoDB Atlas.', 'Capa de Persistencia:')

    h2('2.3. Diseño de Seguridad y Gobernanza de Datos')
    bullet(' Obligatorio antes de cualquier recolección biométrica (conforme a LFPDPPP Art. 8, 9 y 16).', 'Consentimiento Informado Expreso:')
    bullet(' Cada acción clínica genera un registro append-only con UUID, timestamp e integridad referencial (NOM-004-SSA3-2012).', 'Bitácora de Auditoría Inmutable:')
    bullet(' La imagen facial se analiza en memoria volátil en local para extraer descriptores FACS y se protege de fugas externas.', 'Protección de Datos Biométricos:')

    # 3. Metodología
    h1('3. Metodología')
    h2('3.1. Metodología de Desarrollo y Validación')
    body('Desarrollo iterativo adaptado a Software as a Medical Device (SaMD), incorporando diseño centrado en el usuario clínico, mitigación sistemática de falsos negativos y principios de Privacy by Design.')

    h2('3.2. Metodología de Evaluación Multimodal')
    bullet(' Instrumento validado (Kroenke et al., 2001) con 9 reactivos tipo Likert (rango 0 a 27), estratificado en 5 categorías (Mínima, Leve, Moderada, Moderadamente Severa y Severa).', 'Componente Psicométrico (PHQ-9):')
    bullet(' Análisis de Unidades de Acción faciales (Ekman & Friesen): AU1 (tensión/aflicción frontal), AU6 (elevación de mejilla/Duchenne), AU12 (comisura labial/sonrisa) y AU15 (depresor labial/tristeza prolongada).', 'Componente Biomarcador Facial (FACS):')
    bullet(' Cuando existe discrepancia (ej. autorreporte bajo con biomarcadores faciales de aflicción acentuada), el sistema reclasifica a "Riesgo Moderado Sugerido por Expresión Facial" y genera una alerta diferencial para el terapeuta.', 'Fusión Multimodal y Detección de Discrepancias:')

    # 4. Construcción del Prototipo
    h1('4. Construcción del Prototipo')
    h2('4.1. Stack Tecnológico')
    body('El prototipo fue implementado utilizando Flutter 3.3+, Dart, Provider, GoRouter, Camera, SQLCipher/sqflite, Mongo Dart, PDF/Printing y FastAPI con Python en el backend auxiliar.')

    h2('4.2. Módulos Implementados en el Prototipo')
    bullet(' Login clínico, gestión de psicólogos y control de sesión activa.', '1. Acceso y Perfiles:')
    bullet(' Pantalla interactiva que formaliza los permisos éticos y normativos.', '2. Consentimiento Informado:')
    bullet(' Cuestionario interactivo con tarjeta ergonómica de preguntas.', '3. Cuestionario PHQ-9:')
    bullet(' Cámara integrada con guía visual para captura frontal homogénea.', '4. Captura Biométrica:')
    bullet(' Extracción de AUs y reglas de fusión clínica 100% en el dispositivo móvil.', '5. Motor LocalSisifoAgent:')
    bullet(' Semáforo de riesgo visual (RiskBadge), explicabilidad de biomarcadores y recomendaciones clínicas.', '6. Resultados e Interpretación:')
    bullet(' Auditoría append-only y generación de dictamen clínico formal en PDF.', '7. Trazabilidad y Exportación:')

    # 5. Creatividad y Originalidad
    h1('5. Creatividad y Originalidad')
    bullet(' Combina psicometría validada con visión computacional aplicada en un solo índice de soporte clínico.', 'Fusión Subjetiva-Objetiva:')
    bullet(' Eliminación de la dependencia de nubes externas para el análisis biométrico, garantizando soberanía de datos.', 'Paradigma Edge AI / Local-First:')
    bullet(' La IA actúa como asistente explicable (XAI) que enriquece el ojo clínico sin desplazar la decisión del especialista.', 'Human-in-the-Loop:')
    bullet(' Incorporación desde el código de trazabilidad forense, cifrado AES y cumplimiento de normatividad en salud (NOM-004/024).', 'Compliance Normativo Nativo:')

    # 6. Conclusión
    h1('6. Conclusión')
    body('Sísifo representa un avance significativo al integrar salud mental, biometría no invasiva y tecnologías seguras en el dispositivo. Proporciona una respuesta innovadora, ética y robusta ante los desafíos del diagnóstico temprano del riesgo depresivo.')

    pdf.output(output_path)
    print(f"PDF generado exitosamente en: {output_path}")

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '/home/sisifo/DOCUMENTO_PROYECTO_SISIFO.pdf'
    create_pdf(out)
