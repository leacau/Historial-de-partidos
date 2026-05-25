import flet as ft
import firebase_admin
from firebase_admin import credentials, firestore, storage 
from datetime import datetime, timezone 
import urllib.parse 
import json
import os
import csv
import webbrowser 
import uuid 
from PIL import Image
import time

# 1. Configuración de Firebase (Automática)
try:
    with open("credenciales.json", "r") as f:
        cred_data = json.load(f)
        # Extrae automáticamente tu ID de proyecto y arma la URL del bucket
        auto_bucket = f"{cred_data.get('project_id')}.appspot.com"
except Exception:
    auto_bucket = "" # Por si hay algún error leyendo el archivo

cred = credentials.Certificate("credenciales.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred, {
        'storageBucket': auto_bucket 
    })
db = firestore.client()

# --- LÓGICA DE MEMORIA NATIVA ---
def cargar_nombre():
    if os.path.exists("config.json"):
        try:
            with open("config.json", "r") as f:
                return json.load(f).get("nombre", "Mi Hijo")
        except:
            return "Mi Hijo"
    return "Mi Hijo"

def guardar_nombre(nombre):
    with open("config.json", "w") as f:
        json.dump({"nombre": nombre}, f)

def comprimir_imagen(ruta_origen):
    MAX_SIZE = 2 * 1024 * 1024 
    ruta_comprimida = "temp_comprimida.jpg"
    img = Image.open(ruta_origen)
    if img.mode in ("RGBA", "P"): img = img.convert("RGB")
    img.thumbnail((1920, 1920), Image.Resampling.LANCZOS)
    calidad = 90
    img.save(ruta_comprimida, format="JPEG", quality=calidad, optimize=True)
    while os.path.getsize(ruta_comprimida) > MAX_SIZE and calidad > 10:
        calidad -= 5
        img.save(ruta_comprimida, format="JPEG", quality=calidad, optimize=True)
    return ruta_comprimida

def borrar_foto_segura(foto_path, foto_url):
    blob_name = foto_path
    if not blob_name and foto_url:
        try: blob_name = urllib.parse.unquote(foto_url.split('/o/')[1].split('?')[0])
        except: pass
    if blob_name:
        try: storage.bucket().blob(blob_name).delete()
        except Exception: pass

def parsear_fecha_partido(fecha_texto):
    if not fecha_texto:
        return None
    fecha_texto = fecha_texto.strip()
    for formato in ("%d/%m/%Y %H:%M", "%d/%m/%Y"):
        try:
            return datetime.strptime(fecha_texto, formato).replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    return None

def fecha_orden_partido(datos):
    fecha_partido = datos.get("fecha_partido")
    if isinstance(fecha_partido, datetime):
        return fecha_partido if fecha_partido.tzinfo else fecha_partido.replace(tzinfo=timezone.utc)

    fecha_parseada = parsear_fecha_partido(datos.get("fecha", ""))
    if fecha_parseada:
        return fecha_parseada

    timestamp = datos.get("timestamp")
    if isinstance(timestamp, datetime):
        return timestamp if timestamp.tzinfo else timestamp.replace(tzinfo=timezone.utc)

    return datetime.min.replace(tzinfo=timezone.utc)

# --- COMPONENTE DE ANIMACIÓN UNIVERSAL ---
class Animado(ft.Container):
    def __init__(self, content, delay=0):
        super().__init__()
        self.content = content
        self.opacity = 0
        # SOLUCIÓN: ft.Offset directo en lugar de ft.transform.Offset
        self.offset = ft.Offset(0, 0.05) 
        self.animate_opacity = ft.Animation(400, ft.AnimationCurve.DECELERATE)
        self.animate_offset = ft.Animation(400, ft.AnimationCurve.DECELERATE)
        self.delay = delay

    def did_mount(self):
        if self.delay > 0:
            time.sleep(self.delay)
        self.opacity = 1
        # SOLUCIÓN: ft.Offset directo en lugar de ft.transform.Offset
        self.offset = ft.Offset(0, 0) 
        self.update()

def main(page: ft.Page):
    # --- CONFIGURACIÓN VISUAL ESTILO CHAMPIONS ---
    page.window.icon = "icon.png"
    page.title = "Partidos Pro"
    page.theme_mode = ft.ThemeMode.LIGHT
    page.window_width = 450
    page.window_height = 850
    page.bgcolor = "#F0F3F6" 

    
    color_primario = ft.Colors.BLUE_700
    color_secundario = ft.Colors.BLUE_GREY_600
    color_fondo_tarjeta = ft.Colors.WHITE
    
    page.theme = ft.Theme(
        color_scheme_seed=color_primario,
        visual_density=ft.VisualDensity.STANDARD,
    )
    
    page.appbar = ft.AppBar(
        title=ft.Text("Partidos Pro", weight=ft.FontWeight.W_800, color=ft.Colors.BLUE_900, size=22),
        center_title=True,
        bgcolor=color_fondo_tarjeta,
        elevation=2, 
    )

    nombre_jugador = cargar_nombre()
    lista_torneos, lista_rivales, lista_canchas = set(), set(), set()
    lista_equipos_hijo = {"Cosmos FC"}
    
    id_edicion = None
    fecha_temporal = None 
    ruta_foto_temporal = None 
    foto_actual_url = None
    foto_actual_path = None
    foto_eliminada = False

    # --- COMPONENTES DE DISEÑO UI/UX MEJORADOS Y BLINDADOS ---
    def UI_Input(label, icon=None, suffix=None, read_only=False, on_click=None, value="", **kwargs):
        return ft.TextField(
            label=label, prefix_icon=icon, suffix=suffix, read_only=read_only, on_click=on_click,
            value=value, border_radius=12, border_color=ft.Colors.BLUE_GREY_200, 
            focused_border_color=color_primario, dense=True, filled=True,
            fill_color=ft.Colors.WHITE,
            text_style=ft.TextStyle(size=14),
            label_style=ft.TextStyle(color=color_secundario), cursor_color=color_primario, **kwargs
        )

    def UI_Dropdown(label, options=[], value=None, **kwargs):
        return ft.Dropdown(
            label=label, options=[ft.dropdown.Option(o) for o in options], value=value,
            border_radius=12, border_color=ft.Colors.BLUE_GREY_200, filled=True,
            fill_color=ft.Colors.WHITE,
            focused_border_color=color_primario, dense=True, 
            text_style=ft.TextStyle(size=14),
            label_style=ft.TextStyle(color=color_secundario), **kwargs
        )

    def UI_Card(titulo, icono, contenido, color_icono=color_primario):
        return ft.Card(
            elevation=8,
            shadow_color=ft.Colors.BLACK12,
            content=ft.Container(
                bgcolor=color_fondo_tarjeta,
                padding=20,
                border_radius=20,
                content=ft.Column([
                    ft.Row([
                        ft.Icon(icono, color=color_icono, size=22), 
                        ft.Text(titulo, size=18, weight=ft.FontWeight.BOLD, color=ft.Colors.BLUE_900)
                    ], spacing=10),
                    ft.Divider(color=ft.Colors.GREY_100, height=20, thickness=1),
                    contenido
                ], spacing=10)
            )
        )

    def mostrar_notificacion(mensaje, color=ft.Colors.GREEN_600):
        snack = ft.SnackBar(content=ft.Text(mensaje, weight=ft.FontWeight.BOLD), bgcolor=color)
        page.overlay.append(snack)
        snack.open = True
        page.update()

    def mostrar_alerta(titulo, mensaje):
        dlg = ft.AlertDialog(
            title=ft.Text(titulo, size=22, weight=ft.FontWeight.BOLD, color=ft.Colors.BLUE_800),
            content=ft.Text(mensaje)
        )
        page.overlay.append(dlg)
        dlg.open = True
        page.update()

    # --- SELECTORES DE FECHA Y HORA ---
    def cambiar_hora(e):
        if time_picker.value and fecha_temporal:
            hora_str = time_picker.value.strftime("%H:%M")
            fecha_str = fecha_temporal.strftime("%d/%m/%Y")
            fecha_input.value = f"{fecha_str} {hora_str}"
            page.update()

    time_picker = ft.TimePicker(on_change=cambiar_hora)
    page.overlay.append(time_picker)

    def cambiar_fecha(e):
        nonlocal fecha_temporal
        if date_picker.value:
            fecha_temporal = date_picker.value
            fecha_input.value = fecha_temporal.strftime("%d/%m/%Y")
            time_picker.open = True 
            page.update()

    date_picker = ft.DatePicker(on_change=cambiar_fecha, first_date=datetime(2024, 1, 1), last_date=datetime(2030, 12, 31))
    page.overlay.append(date_picker)

    def abrir_calendario(e):
        date_picker.open = True
        page.update()

    def abrir_foto_pantalla_completa(url):
        def cerrar_dialogo(e):
            dlg_visor.open = False
            page.update()
        dlg_visor = ft.AlertDialog(content=ft.Image(src=url, fit="contain", expand=True), content_padding=0, actions=[ft.Button("Cerrar", on_click=cerrar_dialogo)])
        page.overlay.append(dlg_visor)
        dlg_visor.open = True
        page.update()

    miniatura_foto = ft.Image(src="", width=100, height=100, fit="cover", border_radius=15, visible=False)
    file_picker = ft.FilePicker()
    
    if hasattr(page, "services"): page.services.append(file_picker)
    else: page.overlay.append(file_picker)

    def limpiar_foto(e):
        nonlocal ruta_foto_temporal, foto_eliminada
        ruta_foto_temporal = None
        if foto_actual_url: foto_eliminada = True
        miniatura_foto.src = ""
        miniatura_foto.visible = False
        btn_quitar_foto.visible = False
        page.update()

    btn_quitar_foto = ft.IconButton(icon=ft.Icons.CANCEL, icon_color=ft.Colors.RED_400, on_click=limpiar_foto, visible=False, tooltip="Quitar foto")
    
    async def abrir_selector(e):
        nonlocal ruta_foto_temporal, foto_eliminada
        try:
            archivos = await file_picker.pick_files(allow_multiple=False, allowed_extensions=["png", "jpg", "jpeg"])
            if archivos:
                ruta_elegida = archivos[0].path if isinstance(archivos, list) and len(archivos) > 0 else (archivos.files[0].path if hasattr(archivos, "files") and archivos.files else None)
                if ruta_elegida:
                    ruta_foto_temporal = ruta_elegida
                    foto_eliminada = False 
                    miniatura_foto.src = ruta_foto_temporal 
                    miniatura_foto.visible = True
                    btn_quitar_foto.visible = True
                    page.update()
        except Exception: pass

    boton_foto = ft.Button("Adjuntar Foto", icon=ft.Icons.ADD_A_PHOTO, on_click=abrir_selector)

    # --- CAMPOS: CONTEXTO DEL PARTIDO ---
    tipo_partido_input = UI_Dropdown("Categoría", ["Liga", "Amistoso", "Torneo"], "Liga", expand=True)
    
    def set_fase(val):
        fase_torneo_input.value = val
        page.update()
        
    def set_copa(val):
        copa_input.value = val
        page.update()

    menu_fase = ft.PopupMenuButton(
        icon=ft.Icons.ARROW_DROP_DOWN,
        items=[
            ft.PopupMenuItem(content=ft.Text("Fase de Grupos"), on_click=lambda _: set_fase("Fase de Grupos")),
            ft.PopupMenuItem(content=ft.Text("Octavos de Final"), on_click=lambda _: set_fase("Octavos de Final")),
            ft.PopupMenuItem(content=ft.Text("Cuartos de Final"), on_click=lambda _: set_fase("Cuartos de Final")),
            ft.PopupMenuItem(content=ft.Text("Semifinal"), on_click=lambda _: set_fase("Semifinal")),
            ft.PopupMenuItem(content=ft.Text("Final"), on_click=lambda _: set_fase("Final")),
            ft.PopupMenuItem(content=ft.Text("3er y 4to Puesto"), on_click=lambda _: set_fase("3er y 4to Puesto")),
        ]
    )
    fase_torneo_input = UI_Input("Fase (ej: Grupos, Final)", suffix=menu_fase, expand=True)

    menu_copa = ft.PopupMenuButton(
        icon=ft.Icons.ARROW_DROP_DOWN,
        items=[
            ft.PopupMenuItem(content=ft.Text("Oro"), on_click=lambda _: set_copa("Oro")),
            ft.PopupMenuItem(content=ft.Text("Plata"), on_click=lambda _: set_copa("Plata")),
            ft.PopupMenuItem(content=ft.Text("Bronce"), on_click=lambda _: set_copa("Bronce")),
            ft.PopupMenuItem(content=ft.Text("Ninguna"), on_click=lambda _: set_copa("Ninguna")),
        ]
    )
    copa_input = UI_Input("Copa (Opcional)", suffix=menu_copa, expand=True)
    
    row_fase_copa = ft.Row([fase_torneo_input, copa_input], spacing=10)
    
    # --- CAMPOS: PENALES ---
    penales_input = ft.Checkbox(label="Hubo definición por penales", value=False, label_style=ft.TextStyle(size=14, color=ft.Colors.BLUE_GREY_800))
    row_checkbox_penales = ft.Row([penales_input], alignment=ft.MainAxisAlignment.START)
    
    score_penales_equipo = UI_Input("A Favor", value="0", width=80, text_align=ft.TextAlign.CENTER, keyboard_type=ft.KeyboardType.NUMBER)
    score_penales_rival = UI_Input("En Contra", value="0", width=80, text_align=ft.TextAlign.CENTER, keyboard_type=ft.KeyboardType.NUMBER)
    
    def set_penal_hijo(val):
        penal_hijo_input.value = val
        page.update()

    menu_penal_hijo = ft.PopupMenuButton(
        icon=ft.Icons.ARROW_DROP_DOWN,
        items=[
            ft.PopupMenuItem(content=ft.Text("No pateó"), on_click=lambda _: set_penal_hijo("No pateó")),
            ft.PopupMenuItem(content=ft.Text("Anotó"), on_click=lambda _: set_penal_hijo("Anotó")),
            ft.PopupMenuItem(content=ft.Text("Erró / Atajado"), on_click=lambda _: set_penal_hijo("Erró / Atajado")),
        ]
    )
    penal_hijo_input = UI_Input(f"Penal de {nombre_jugador}", value="No pateó", suffix=menu_penal_hijo, expand=True)

    tarjeta_penales_ui = ft.Container(
        content=ft.Column([
            ft.Text("Resultado de Penales", weight=ft.FontWeight.BOLD, size=14, color=ft.Colors.BLUE_900),
            ft.Row([score_penales_equipo, ft.Text("-", size=24, weight=ft.FontWeight.BOLD), score_penales_rival], alignment=ft.MainAxisAlignment.CENTER),
            ft.Row([penal_hijo_input])
        ], spacing=10), 
        padding=15, bgcolor=ft.Colors.BLUE_GREY_50, border_radius=12
    )

    # --- ESPACIOS RESERVADOS ---
    espacio_fase_copa = ft.Column(spacing=0)
    espacio_checkbox_penales = ft.Column(spacing=0)
    espacio_tarjeta_penales = ft.Column(spacing=0)

    # --- LÓGICA DE INYECCIÓN ---
    def toggle_torneo(e=None):
        es_torneo = (tipo_partido_input.value == "Torneo")
        
        espacio_fase_copa.controls.clear()
        espacio_checkbox_penales.controls.clear()
        
        if es_torneo:
            espacio_fase_copa.controls.append(ft.Container(content=row_fase_copa, padding=5))
            espacio_checkbox_penales.controls.append(ft.Container(content=row_checkbox_penales, padding=5))
        else:
            fase_torneo_input.value = "Fase de Grupos"
            copa_input.value = "Ninguna"
            penales_input.value = False
            toggle_penales() 
            
        page.update()

    def toggle_penales(e=None):
        espacio_tarjeta_penales.controls.clear()
        
        if penales_input.value:
            espacio_tarjeta_penales.controls.append(ft.Container(content=tarjeta_penales_ui, padding=10))
        else:
            score_penales_equipo.value = "0"
            score_penales_rival.value = "0"
            penal_hijo_input.value = "No pateó"
            
        page.update()

    tipo_partido_input.on_change = toggle_torneo
    penales_input.on_change = toggle_penales

    # --- MARCADOR Y MENÚS DINÁMICOS ---
    label_equipo = ft.Text("Tu Equipo", size=14, weight=ft.FontWeight.BOLD, color=ft.Colors.BLUE_900)
    label_rival = ft.Text("Rival", size=14, weight=ft.FontWeight.BOLD, color=ft.Colors.RED_900)

    def actualizar_marcador(e=None):
        label_equipo.value = equipo_input.value if equipo_input.value else "Tu Equipo"
        label_rival.value = rival_input.value if rival_input.value else "Rival"
        page.update()

    menu_torneo_g = ft.PopupMenuButton(icon=ft.Icons.ARROW_DROP_DOWN)
    menu_equipo_g = ft.PopupMenuButton(icon=ft.Icons.ARROW_DROP_DOWN)
    menu_rival_g = ft.PopupMenuButton(icon=ft.Icons.ARROW_DROP_DOWN)
    menu_cancha_g = ft.PopupMenuButton(icon=ft.Icons.ARROW_DROP_DOWN)

    torneo_input = UI_Input("Evento (Ej: Torneo Verano)", suffix=menu_torneo_g, expand=True)
    equipo_input = UI_Input(f"Equipo", value="Cosmos FC", suffix=menu_equipo_g, expand=True, on_change=actualizar_marcador)
    rival_input = UI_Input("Rival", suffix=menu_rival_g, expand=True, on_change=actualizar_marcador)
    cancha_input = UI_Input("Cancha / Predio", suffix=menu_cancha_g, expand=True)
    
    fecha_input = UI_Input("Fecha y Hora", read_only=True, on_click=abrir_calendario, value=datetime.now().strftime("%d/%m/%Y %H:%M"), expand=True)
    
    posicion_input = UI_Dropdown("Posición", ["Delantero", "Mediocampista", "Defensor", "Arquero"], "Delantero", expand=True)
    
    analisis_input = ft.TextField(
        label="Notas y análisis técnico...", multiline=True, min_lines=2, max_lines=4, expand=True, 
        border_radius=12, border_color=ft.Colors.BLUE_GREY_200, focused_border_color=color_primario, 
        filled=True, fill_color=ft.Colors.WHITE, text_style=ft.TextStyle(size=14), label_style=ft.TextStyle(color=color_secundario)
    )

    score_hijo = ft.TextField(value="0", width=70, text_align=ft.TextAlign.CENTER, keyboard_type=ft.KeyboardType.NUMBER, border_radius=12, border_color=ft.Colors.BLUE_GREY_300, focused_border_color=color_primario, dense=True, filled=True, fill_color=ft.Colors.WHITE, text_style=ft.TextStyle(size=26, weight=ft.FontWeight.BOLD))
    score_rival = ft.TextField(value="0", width=70, text_align=ft.TextAlign.CENTER, keyboard_type=ft.KeyboardType.NUMBER, border_radius=12, border_color=ft.Colors.BLUE_GREY_300, focused_border_color=color_primario, dense=True, filled=True, fill_color=ft.Colors.WHITE, text_style=ft.TextStyle(size=26, weight=ft.FontWeight.BOLD))
    
    texto_goles_carga = ft.Text(f"Goles de {nombre_jugador}:", size=16, weight=ft.FontWeight.W_500, color=ft.Colors.BLUE_GREY_900)
    goles_individuales = ft.Text(value="0", size=32, weight=ft.FontWeight.BOLD, color=color_primario)

    def compartir_whatsapp(d):
        s_hijo = d.get('score_hijo', 0)
        s_rival = d.get('score_rival', 0)
        nombre_bd = d.get('nombre_jugador', nombre_jugador)
        
        res = "¡Ganamos! 🏆" if s_hijo > s_rival else ("¡Empate! ⚖️" if s_hijo == s_rival else "¡Buen partido! ⚽")
        
        tipo_str = d.get('tipo_partido', 'Liga')
        contexto = f"Tipo: {tipo_str}"
        if tipo_str == "Torneo":
            if d.get('fase'): contexto += f" | {d.get('fase')}"
            if d.get('copa') and d.get('copa') != "Ninguna": contexto += f" - Copa {d.get('copa')}"
            
        marcador_txt = f"{s_hijo} - {s_rival}"
        if d.get('penales'):
            marcador_txt = f"{s_hijo} ({d.get('score_penales_equipo',0)}) - ({d.get('score_penales_rival',0)}) {s_rival} [PENALES]"
            if d.get('score_penales_equipo',0) > d.get('score_penales_rival',0): res = "¡Ganamos por Penales! 🏆🔥"
            elif d.get('score_penales_equipo',0) < d.get('score_penales_rival',0): res = "¡Partidazo! (Caímos en penales) ⚽"

        texto = (f"{res}\nEvento: {d.get('torneo', 'Amistoso')}\n"
                 f"{contexto}\n"
                 f"Resultado: {d.get('equipo', 'Equipo')} {marcador_txt} {d.get('rival', 'Rival')}\n"
                 f"Goles de {nombre_bd}: {d.get('goles_hijo', 0)}\nPosición: {d.get('posicion', 'No especificada')}\n"
                 f"Cancha: {d.get('cancha', '')}\nFecha: {d.get('fecha', '')}")
                 
        if d.get('penales') and d.get('penal_hijo') and d.get('penal_hijo') != "No pateó":
            texto += f"\nTanda de Penales: {nombre_bd} {d.get('penal_hijo').lower()} su penal 🎯"

        if d.get('analisis'):
            texto += f"\n\nAnálisis: {d.get('analisis')}"
            
        webbrowser.open(f"https://wa.me/?text={urllib.parse.quote(texto)}")

    # --- CRUD Y SUBIDA A FIREBASE STORAGE ---
    def guardar_partido(e):
        nonlocal id_edicion, ruta_foto_temporal, foto_actual_url, foto_actual_path, foto_eliminada
        if not torneo_input.value or not rival_input.value: return
        
        goles_partido = int(goles_individuales.value)
        tipo = tipo_partido_input.value
        ahora = datetime.now(timezone.utc)
        fecha_partido = parsear_fecha_partido(fecha_input.value) or ahora
        
        datos = {
            "nombre_jugador": nombre_jugador, "torneo": torneo_input.value, 
            "tipo_partido": tipo,
            "fase": fase_torneo_input.value if tipo == "Torneo" and fase_torneo_input.value else "",
            "copa": copa_input.value if tipo == "Torneo" and copa_input.value else "Ninguna",
            "equipo": equipo_input.value, "rival": rival_input.value,
            "cancha": cancha_input.value, "fecha": fecha_input.value, 
            "posicion": posicion_input.value, "analisis": analisis_input.value,
            "score_hijo": int(score_hijo.value), "score_rival": int(score_rival.value), 
            "goles_hijo": goles_partido, "timestamp": fecha_partido,
            "fecha_partido": fecha_partido,
            "actualizado_en": ahora,
            
            "penales": penales_input.value,
            "score_penales_equipo": int(score_penales_equipo.value) if penales_input.value else 0,
            "score_penales_rival": int(score_penales_rival.value) if penales_input.value else 0,
            "penal_hijo": penal_hijo_input.value if penales_input.value else "No pateó"
        }

        if foto_actual_url and not foto_eliminada and not ruta_foto_temporal:
            datos["foto"] = foto_actual_url
            if foto_actual_path: datos["foto_path"] = foto_actual_path

        if foto_eliminada:
            borrar_foto_segura(foto_actual_path, foto_actual_url)
            datos["foto"] = ""
            datos["foto_path"] = ""

        if ruta_foto_temporal:
            try:
                if foto_actual_url and not foto_eliminada:
                    borrar_foto_segura(foto_actual_path, foto_actual_url)
                
                mostrar_notificacion("Procesando foto... ☁️⏳", ft.Colors.BLUE_600)
                ruta_procesada = comprimir_imagen(ruta_foto_temporal)
                
                bucket = storage.bucket()
                nombre_archivo = f"fotos/img_{int(datetime.now().timestamp())}.jpg"
                blob = bucket.blob(nombre_archivo)
                
                token = uuid.uuid4()
                blob.metadata = {"firebaseStorageDownloadTokens": str(token)}
                blob.upload_from_filename(ruta_procesada)
                
                if os.path.exists(ruta_procesada): os.remove(ruta_procesada)
                
                ruta_codificada = urllib.parse.quote(nombre_archivo, safe='')
                url_foto = f"https://firebasestorage.googleapis.com/v0/b/{bucket.name}/o/{ruta_codificada}?alt=media&token={token}"
                
                datos["foto"] = url_foto
                datos["foto_path"] = nombre_archivo 
                
            except Exception as ex:
                mostrar_notificacion(f"Error al subir la foto: {ex}", ft.Colors.RED_600)
                return 

        if id_edicion:
            db.collection("historial").document(id_edicion).update(datos)
            id_edicion = None
            btn_guardar.text = "Guardar Partido"
            mostrar_notificacion("Partido actualizado en la nube")
        else:
            datos["creado_en"] = ahora
            db.collection("historial").add(datos)
            if goles_partido >= 3:
                mostrar_alerta(f"¡HAT-TRICK DE {nombre_jugador.upper()}! ⚽⚽⚽", f"¡Impresionante partido! Guardaste un registro histórico con {goles_partido} goles.")
            else:
                mostrar_notificacion("Partido guardado con éxito")

        limpiar_campos()
        obtener_unicos()
        page.navigation_bar.selected_index = 1
        navegar(None)

    def limpiar_campos():
        nonlocal ruta_foto_temporal, foto_actual_url, foto_actual_path, foto_eliminada
        torneo_input.value = rival_input.value = cancha_input.value = analisis_input.value = ""
        equipo_input.value = "Cosmos FC"
        posicion_input.value = "Delantero"
        score_hijo.value = score_rival.value = "0"
        goles_individuales.value = "0"
        
        tipo_partido_input.value = "Liga"
        fase_torneo_input.value = "Fase de Grupos"
        copa_input.value = "Ninguna"
        penales_input.value = False
        score_penales_equipo.value = "0"
        score_penales_rival.value = "0"
        penal_hijo_input.value = "No pateó"
        
        toggle_torneo()
        
        ruta_foto_temporal = None
        foto_actual_url = None
        foto_actual_path = None
        foto_eliminada = False
        
        miniatura_foto.src = ""
        miniatura_foto.visible = False
        btn_quitar_foto.visible = False
        actualizar_marcador()

    def obtener_unicos():
        partidos = db.collection("historial").stream()
        for p in partidos:
            d = p.to_dict()
            if d.get("torneo"): lista_torneos.add(d["torneo"])
            if d.get("rival"): lista_rivales.add(d["rival"])
            if d.get("equipo"): lista_equipos_hijo.add(d["equipo"])
            if d.get("cancha"): lista_canchas.add(d["cancha"])
        
        menu_torneo_g.items = [ft.PopupMenuItem(content=ft.Text(t), on_click=lambda e, v=t: (setattr(torneo_input, "value", v), page.update())) for t in sorted(lista_torneos)]
        menu_equipo_g.items = [ft.PopupMenuItem(content=ft.Text(eq), on_click=lambda e, v=eq: (setattr(equipo_input, "value", v), actualizar_marcador())) for eq in sorted(lista_equipos_hijo)]
        menu_rival_g.items = [ft.PopupMenuItem(content=ft.Text(r), on_click=lambda e, v=r: (setattr(rival_input, "value", v), actualizar_marcador())) for r in sorted(lista_rivales)]
        menu_cancha_g.items = [ft.PopupMenuItem(content=ft.Text(c), on_click=lambda e, v=c: (setattr(cancha_input, "value", v), page.update())) for c in sorted(lista_canchas)]
        page.update()

    # --- DASHBOARD Y EXPORTACIÓN ---
    filtro_search = UI_Input("Filtrar historial...", icon=ft.Icons.SEARCH, on_change=lambda _: actualizar_dashboard())
    historial_lista = ft.Column(spacing=10)
    contenedor_stats_globales = ft.Container()
    contenedor_stats_torneos = ft.Column()
    contenedor_grafico = ft.Container(height=180, padding=10)
    etiqueta_racha = ft.Text("", size=14, weight=ft.FontWeight.BOLD, color=ft.Colors.ORANGE_800)

    def eliminar_partido(doc_id, foto_path, foto_url):
        def confirmar(e):
            if foto_url:
                borrar_foto_segura(foto_path, foto_url)
            db.collection("historial").document(doc_id).delete()
            dlg_conf.open = False
            mostrar_notificacion("Partido eliminado", ft.Colors.RED_600)
            actualizar_dashboard()
            page.update()
            
        dlg_conf = ft.AlertDialog(
            title=ft.Text("¿Eliminar partido?"),
            content=ft.Text("Esta acción no se puede deshacer."),
            actions=[
                ft.Button("Cancelar", on_click=lambda _: (setattr(dlg_conf, "open", False), page.update())),
                ft.Button("Eliminar", style=ft.ButtonStyle(bgcolor=ft.Colors.RED_600, color=ft.Colors.WHITE), on_click=confirmar),
            ]
        )
        page.overlay.append(dlg_conf)
        dlg_conf.open = True
        page.update()

    def exportar_csv(e):
        partidos_ref = db.collection("historial").stream()
        partidos_lista = [p.to_dict() for p in partidos_ref]
        partidos_lista.sort(key=fecha_orden_partido, reverse=True)
        nombre_archivo = "historial_partidos.csv"
        try:
            with open(nombre_archivo, mode='w', newline='', encoding='utf-8') as file:
                writer = csv.writer(file)
                writer.writerow(["Fecha", "Tipo Partido", "Torneo/Evento", "Fase", "Copa", "Penales", "Penales Favor", "Penales Contra", "Penal Jugador", "Cancha", "Equipo", "Goles Favor", "Goles Contra", "Rival", "Nombre Jugador", "Goles Jugador", "Posición", "Análisis", "Foto URL"])
                for d in partidos_lista:
                    writer.writerow([
                        d.get('fecha', ''), d.get('tipo_partido', 'Liga'), d.get('torneo', ''), 
                        d.get('fase', ''), d.get('copa', ''), "Sí" if d.get('penales') else "No",
                        d.get('score_penales_equipo', 0), d.get('score_penales_rival', 0), d.get('penal_hijo', 'No pateó'),
                        d.get('cancha', ''), d.get('equipo', ''), d.get('score_hijo', 0), d.get('score_rival', 0), 
                        d.get('rival', ''), d.get('nombre_jugador', ''), d.get('goles_hijo', 0), 
                        d.get('posicion', ''), d.get('analisis', ''), d.get('foto', '')
                    ])
            mostrar_notificacion(f"¡Exportado con éxito a {nombre_archivo}!")
        except Exception as ex:
            mostrar_notificacion(f"Error al exportar: {str(ex)}", ft.Colors.RED_600)

    def crear_cuadricula_stats(stats):
        def cajita(lbl, val, col):
            return ft.Container(
                content=ft.Column([ft.Text(lbl, size=12, weight=ft.FontWeight.W_500), ft.Text(str(val), size=20, weight=ft.FontWeight.BOLD, color=col)], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=2),
                expand=True, bgcolor=ft.Colors.WHITE, border_radius=8, padding=5
            )
        r1 = ft.Row([cajita("PJ", stats["pj"], ft.Colors.BLACK), cajita("PG", stats["pg"], ft.Colors.GREEN_600), cajita("PE", stats["pe"], ft.Colors.ORANGE_600), cajita("PP", stats["pp"], ft.Colors.RED_600)])
        r2 = ft.Row([cajita("GF", stats["gf"], ft.Colors.BLUE_600), cajita("GC", stats["gc"], ft.Colors.BLUE_GREY_600), cajita("DG", stats["dg"], ft.Colors.PURPLE_600), cajita("GP", stats["gp"], ft.Colors.TEAL_600)])
        return ft.Column([r1, r2], spacing=5)
    
    def actualizar_dashboard():
        partidos_ref = db.collection("historial").stream()
        partidos_lista = [{"id": p.id, **p.to_dict()} for p in partidos_ref]
        partidos_lista.sort(key=fecha_orden_partido, reverse=True)

        stats_global = {"pj": 0, "pg": 0, "pe": 0, "pp": 0, "gf": 0, "gc": 0, "dg": 0, "gp": 0}
        stats_por_torneo = {}
        historial_lista.controls.clear()
        query = filtro_search.value.lower() if filtro_search.value else ""
        
        goles_historia = []
        racha_actual = 0
        racha_rota = False

        for d in partidos_lista:
            torneo_str = d.get('torneo', 'Sin Torneo')
            rival_str = d.get('rival', '')
            s_hijo = d.get('score_hijo', 0)
            s_rival = d.get('score_rival', 0)
            g_hijo = int(d.get('goles_hijo', d.get('goles', 0)))
            nombre_bd = d.get('nombre_jugador', nombre_jugador)

            if not racha_rota:
                gano_partido = s_hijo > s_rival
                gano_penales = d.get('penales') and d.get('score_penales_equipo', 0) > d.get('score_penales_rival', 0)
                if gano_partido or gano_penales: racha_actual += 1
                else: racha_rota = True

            if not query:
                goles_historia.append(g_hijo) 
                if torneo_str not in stats_por_torneo:
                    stats_por_torneo[torneo_str] = {"pj": 0, "pg": 0, "pe": 0, "pp": 0, "gf": 0, "gc": 0, "dg": 0, "gp": 0}
                
                stats_global["pj"] += 1; stats_global["gf"] += s_hijo; stats_global["gc"] += s_rival; stats_global["gp"] += g_hijo
                if s_hijo > s_rival: stats_global["pg"] += 1
                elif s_hijo == s_rival: stats_global["pe"] += 1
                else: stats_global["pp"] += 1

                t_stats = stats_por_torneo[torneo_str]
                t_stats["pj"] += 1; t_stats["gf"] += s_hijo; t_stats["gc"] += s_rival; t_stats["gp"] += g_hijo
                if s_hijo > s_rival: t_stats["pg"] += 1
                elif s_hijo == s_rival: t_stats["pe"] += 1
                else: t_stats["pp"] += 1

            if query and query not in torneo_str.lower() and query not in rival_str.lower(): 
                continue

            tipo_str = d.get('tipo_partido', 'Liga')
            fase_str = d.get('fase', '')
            copa_str = d.get('copa', '')
            hubo_penales = d.get('penales', False)
            
            if tipo_str == "Torneo":
                badge_fase = f" | {fase_str}" if fase_str else ""
                badge_copa = f" (Copa {copa_str})" if copa_str and copa_str != "Ninguna" else ""
                badge_tipo = f"🏆 Torneo{badge_fase}{badge_copa}"
                color_bg = ft.Colors.AMBER_50
            elif tipo_str == "Amistoso":
                badge_tipo = f"🤝 Amistoso"
                color_bg = ft.Colors.GREEN_50
            else:
                badge_tipo = f"⚽ Liga"
                color_bg = ft.Colors.WHITE

            marcador_txt = f"{s_hijo} - {s_rival}"
            if hubo_penales:
                marcador_txt = f"{s_hijo} ({d.get('score_penales_equipo',0)}) - ({d.get('score_penales_rival',0)}) {s_rival}"

            elementos_tarjeta = [
                ft.Row([
                    ft.Text(f"{d.get('fecha', '')} | {d.get('cancha', '')}", size=11, color=ft.Colors.GREY_600),
                    ft.Row([
                        ft.IconButton(ft.Icons.SHARE, icon_size=18, on_click=lambda e, dat=d: compartir_whatsapp(dat)),
                        ft.IconButton(ft.Icons.EDIT, icon_size=18, on_click=lambda e, i=d['id'], dat=d: preparar_edicion(i, dat)),
                        ft.IconButton(ft.Icons.DELETE, icon_size=18, icon_color=ft.Colors.RED_400, on_click=lambda e, i=d['id'], fp=d.get('foto_path'), fu=d.get('foto'): eliminar_partido(i, fp, fu)),
                    ])
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                ft.Text(f"{badge_tipo} - {torneo_str}", weight=ft.FontWeight.BOLD, color=ft.Colors.BLUE_900),
                ft.Text(f"{d.get('equipo', 'Equipo')} {marcador_txt} {rival_str}", size=18, weight=ft.FontWeight.W_500)
            ]
            
            if hubo_penales and d.get('penal_hijo') and d.get('penal_hijo') != "No pateó":
                icono_penal = "✅" if d.get('penal_hijo') == "Anotó" else "❌"
                elementos_tarjeta.append(ft.Text(f"Tanda de Penales: {d.get('penal_hijo')} {icono_penal}", size=12, italic=True))

            elementos_tarjeta.append(
                ft.Row([
                    ft.Text(f"🥅 Goles: {g_hijo}", color=ft.Colors.BLUE_700, weight=ft.FontWeight.BOLD),
                    ft.Text(f"📍 {d.get('posicion', 'ND')}", color=ft.Colors.GREY_600, size=12)
                ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
            )

            if d.get('foto'):
                elementos_tarjeta.append(
                    ft.Container(
                        content=ft.Image(src=d['foto'], fit="cover", border_radius=8),
                        height=150, width=float("inf"), padding=5,
                        on_click=lambda e, url=d['foto']: abrir_foto_pantalla_completa(url),
                        ink=True 
                    )
                )

            if d.get('analisis'):
                elementos_tarjeta.append(ft.Text(f"📝 {d['analisis']}", size=12, italic=True, color=ft.Colors.GREY_800))

            historial_lista.controls.append(
                Animado(
                    ft.Card(
                        elevation=2,
                        content=ft.Container(
                            content=ft.Column(elementos_tarjeta),
                            padding=15,
                            bgcolor=color_bg,
                            border_radius=15
                        )
                    )
                )
            )
        
        etiqueta_racha.value = f"🔥 Racha de victorias: {racha_actual}" if racha_actual >= 2 else ""

        goles_historia.reverse() 
        ultimos_goles = goles_historia[-10:] if len(goles_historia) > 0 else [0]
        max_goles = max(ultimos_goles) if ultimos_goles else 1
        
        barras = []
        for g in ultimos_goles:
            altura = (g / max_goles) * 100 if max_goles > 0 else 0
            barras.append(
                ft.Column([
                    ft.Text(str(g), size=12, weight=ft.FontWeight.BOLD, color=ft.Colors.BLUE_900),
                    ft.Container(
                        width=20, height=altura if altura > 0 else 5, 
                        bgcolor=ft.Colors.BLUE_400, border_radius=5
                    )
                ], alignment=ft.MainAxisAlignment.END, horizontal_alignment=ft.CrossAxisAlignment.CENTER)
            )

        contenedor_grafico.content = ft.Container(
            content=ft.Row(barras, alignment=ft.MainAxisAlignment.SPACE_EVENLY, vertical_alignment=ft.CrossAxisAlignment.END),
            height=140, padding=10, bgcolor=ft.Colors.WHITE, border_radius=10
        )

        stats_global["dg"] = stats_global["gf"] - stats_global["gc"]
        for t in stats_por_torneo:
            stats_por_torneo[t]["dg"] = stats_por_torneo[t]["gf"] - stats_por_torneo[t]["gc"]

        contenedor_stats_globales.content = crear_cuadricula_stats(stats_global)

        contenedor_stats_torneos.controls.clear()
        for torneo, stats in stats_por_torneo.items():
            contenedor_stats_torneos.controls.append(
                ft.ExpansionTile(
                    title=ft.Text(torneo, weight=ft.FontWeight.BOLD),
                    subtitle=ft.Text(f"{stats['pj']} partidos jugados"),
                    controls=[ft.Container(content=crear_cuadricula_stats(stats), padding=10)],
                )
            )

        page.update()

    def preparar_edicion(doc_id, d):
        nonlocal id_edicion, foto_actual_url, foto_actual_path, ruta_foto_temporal, foto_eliminada
        id_edicion = doc_id
        torneo_input.value = d.get('torneo', '')
        equipo_input.value = d.get('equipo', '')
        rival_input.value = d.get('rival', '')
        cancha_input.value = d.get('cancha', '')
        fecha_input.value = d.get('fecha', '')
        posicion_input.value = d.get('posicion', 'Delantero')
        analisis_input.value = d.get('analisis', '')
        score_hijo.value = str(d.get('score_hijo', 0))
        score_rival.value = str(d.get('score_rival', 0))
        goles_individuales.value = str(d.get('goles_hijo', d.get('goles', 0)))
        
        tipo_partido_input.value = d.get('tipo_partido', 'Liga')
        fase_torneo_input.value = d.get('fase') if d.get('fase') else "Fase de Grupos"
        copa_input.value = d.get('copa') if d.get('copa') else "Ninguna"
        penales_input.value = d.get('penales', False)
        score_penales_equipo.value = str(d.get('score_penales_equipo', 0))
        score_penales_rival.value = str(d.get('score_penales_rival', 0))
        penal_hijo_input.value = d.get('penal_hijo', 'No pateó')
        
        toggle_torneo()
        toggle_penales()
        
        btn_guardar.text = "Actualizar"
        
        foto_actual_url = d.get('foto')
        foto_actual_path = d.get('foto_path')
        ruta_foto_temporal = None
        foto_eliminada = False
        
        if foto_actual_url:
            miniatura_foto.src = foto_actual_url
            miniatura_foto.visible = True
            btn_quitar_foto.visible = True
        else:
            miniatura_foto.src = ""
            miniatura_foto.visible = False
            btn_quitar_foto.visible = False
            
        actualizar_marcador()
        page.navigation_bar.selected_index = 0
        navegar(None)

    # --- NUEVA VISTA: PERFIL ---
    input_nombre_perfil = UI_Input("Nombre del jugador", value=nombre_jugador, expand=True)

    def actualizar_perfil(e):
        nonlocal nombre_jugador
        nuevo_nombre = input_nombre_perfil.value if input_nombre_perfil.value else "Mi Hijo"
        guardar_nombre(nuevo_nombre)
        nombre_jugador = nuevo_nombre
        equipo_input.label = f"Equipo de {nombre_jugador}"
        texto_goles_carga.value = f"Goles de {nombre_jugador}:"
        penal_hijo_input.label = f"Penal de {nombre_jugador}"
        mostrar_notificacion(f"¡Perfil actualizado para {nombre_jugador}!")
        actualizar_dashboard()

    vista_perfil = ft.Container(
        content=Animado(ft.Column([
            ft.Text("Configuración de Perfil", size=24, weight=ft.FontWeight.BOLD),
            ft.Text("Personalizá la aplicación para que muestre el nombre de tu hijo en las tarjetas y al compartir resultados.", color=ft.Colors.GREY_700),
            ft.Divider(height=20, color="transparent"),
            input_nombre_perfil,
            ft.Row([ft.Button("Guardar Configuración", icon=ft.Icons.SAVE, on_click=actualizar_perfil)], alignment=ft.MainAxisAlignment.CENTER)
        ])), padding=15
    )

    # --- DISEÑO PRINCIPAL FIJO ---
    tarjeta_contexto = UI_Card(
        "Contexto", ft.Icons.EDIT_DOCUMENT,
        ft.Column([
            ft.Row([tipo_partido_input, torneo_input]),
            espacio_fase_copa, 
            ft.Row([cancha_input, fecha_input])
        ])
    )

    tarjeta_marcador = UI_Card(
        "Partido", ft.Icons.SCOREBOARD,
        ft.Column([
            ft.Row([equipo_input, rival_input]),
            ft.Container(content=ft.Row([
                ft.Column([label_equipo, score_hijo], horizontal_alignment=ft.CrossAxisAlignment.CENTER, expand=True),
                ft.Text("VS", size=24, weight=ft.FontWeight.BOLD),
                ft.Column([label_rival, score_rival], horizontal_alignment=ft.CrossAxisAlignment.CENTER, expand=True),
            ]), padding=15, bgcolor=ft.Colors.WHITE, border_radius=10),
            espacio_checkbox_penales, 
            espacio_tarjeta_penales
        ])
    )

    tarjeta_rendimiento = UI_Card(
        f"Rendimiento de {nombre_jugador}", ft.Icons.STAR,
        ft.Column([
            ft.Row([posicion_input, boton_foto]), 
            ft.Row([miniatura_foto, btn_quitar_foto], alignment=ft.MainAxisAlignment.START), 
            analisis_input,
            ft.Divider(),
            ft.Row([
                texto_goles_carga, 
                ft.IconButton(ft.Icons.REMOVE_CIRCLE, icon_color=ft.Colors.RED_400, on_click=lambda _: (setattr(goles_individuales, "value", str(max(0, int(goles_individuales.value)-1))), page.update())), 
                goles_individuales, 
                ft.IconButton(ft.Icons.ADD_CIRCLE, icon_color=ft.Colors.GREEN_400, on_click=lambda _: (setattr(goles_individuales, "value", str(int(goles_individuales.value)+1)), page.update()))
            ], alignment=ft.MainAxisAlignment.CENTER),
        ])
    )

    btn_guardar = ft.Button("Guardar Partido", icon=ft.Icons.CLOUD_UPLOAD, on_click=guardar_partido, expand=True)

    vista_carga = ft.Container(
        content=Animado(ft.Column([
            ft.Text("Registrar Partido", size=24, weight=ft.FontWeight.BOLD),
            tarjeta_contexto,
            tarjeta_marcador,
            tarjeta_rendimiento,
            ft.Row([btn_guardar], alignment=ft.MainAxisAlignment.CENTER)
        ], scroll=ft.ScrollMode.AUTO)), padding=15
    )

    vista_stats = ft.Container(
        content=Animado(ft.Column([
            ft.Row([
                ft.Text("Rendimiento", size=24, weight=ft.FontWeight.BOLD),
                ft.IconButton(icon=ft.Icons.DOWNLOAD, tooltip="Exportar a CSV", icon_color=ft.Colors.GREEN_700, on_click=exportar_csv)
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            etiqueta_racha, 
            contenedor_stats_globales,
            ft.Divider(height=20),
            ft.Text("Evolución de Goles (Últimos 10)", size=16, weight=ft.FontWeight.BOLD, color=ft.Colors.BLUE_900),
            contenedor_grafico,
            ft.Divider(height=20),
            ft.Text("Por Torneo", size=20, weight=ft.FontWeight.BOLD),
            contenedor_stats_torneos,
            ft.Divider(height=20),
            ft.Text("Historial Completo", size=20, weight=ft.FontWeight.BOLD),
            filtro_search, 
            historial_lista
        ], scroll=ft.ScrollMode.AUTO)), padding=15
    )

    contenedor = ft.Container(content=vista_carga, expand=True)

    def navegar(e):
        if page.navigation_bar.selected_index == 0: 
            contenedor.content = vista_carga
        elif page.navigation_bar.selected_index == 1: 
            actualizar_dashboard()
            contenedor.content = vista_stats
        elif page.navigation_bar.selected_index == 2:
            contenedor.content = vista_perfil
        page.update()

    page.navigation_bar = ft.NavigationBar(
        destinations=[
            ft.NavigationBarDestination(icon=ft.Icons.ADD_BOX, label="Cargar"), 
            ft.NavigationBarDestination(icon=ft.Icons.ANALYTICS, label="Stats"),
            ft.NavigationBarDestination(icon=ft.Icons.PERSON, label="Perfil")
        ],
        on_change=navegar
    )

    page.add(contenedor)
    
    limpiar_campos()
    obtener_unicos()

ft.run(main, assets_dir="assets")
