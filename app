import streamlit as st
import pandas as pd
import plotly.express as px
from datetime import datetime, timedelta

# Configuration de la page
st.set_page_config(page_title="SoluCalc Planning 2026", layout="wide")

# Simulation d'une base de données (pourrait être un CSV sur le NAS)
if 'df_planning' not in st.session_state:
    data = {
        'Employé': ['Sarah Brel', 'Antoine Wibrin'],
        'Service': ['RH', 'Direction'],
        'Début': [datetime(2026, 2, 1), datetime(2026, 2, 10)],
        'Fin': [datetime(2026, 2, 5), datetime(2026, 2, 12)],
        'Motif': ['Congé', 'Déplacement'],
        'Couleur': ['#3498db', '#2ecc71']
    }
    st.session_state.df_planning = pd.DataFrame(data)

# --- STYLES ET COULEURS ---
MOTIFS_COLORS = {
    "Congé": "#3498db",      # Bleu
    "Maladie": "#e74c3c",    # Rouge
    "Déplacement": "#2ecc71" # Vert
}

# --- SIDEBAR : SAISIE ---
st.sidebar.header("📝 Saisie des absences")
with st.sidebar.form("form_absence"):
    nom = st.text_input("Nom de l'employé")
    service = st.selectbox("Service", ["Sales", "Technique", "Admin", "RH", "Direction"])
    date_debut = st.date_input("Date de début")
    date_fin = st.date_input("Date de fin")
    motif = st.selectbox("Motif", list(MOTIFS_COLORS.keys()))
    
    submit = st.form_submit_button("Ajouter au planning")
    
    if submit:
        new_data = {
            'Employé': nom,
            'Service': service,
            'Début': pd.to_datetime(date_debut),
            'Fin': pd.to_datetime(date_fin),
            'Motif': motif,
            'Couleur': MOTIFS_COLORS[motif]
        }
        st.session_state.df_planning = pd.concat([st.session_state.df_planning, pd.DataFrame([new_data])], ignore_index=True)
        st.success(f"Absence ajoutée pour {nom}")

# --- TITRE PRINCIPAL ---
st.title("🚀 SoluCalc - Gestion Planning & Congés 2026")
st.markdown("---")

# --- ALERTES HEBDOMADAIRES (Vue DG) ---
st.subheader("⚠️ Alertes Hebdo (Semaine Prochaine)")
next_week = datetime.now() + timedelta(days=7)
absents_soon = st.session_state.df_planning[st.session_state.df_planning['Début'] <= pd.to_datetime(next_week)]

if not absents_soon.empty:
    st.warning(f"Il y a {len(absents_soon)} absence(s) prévue(s) pour la semaine prochaine.")
else:
    st.info("Tout le monde est sur le pont la semaine prochaine !")

# --- FILTRES CODIR ---
st.subheader("🔍 Vue Stratégique")
col1, col2 = st.columns([1, 3])

with col1:
    dept_filter = st.multiselect("Filtrer par Département", 
                                 options=st.session_state.df_planning['Service'].unique(),
                                 default=st.session_state.df_planning['Service'].unique())

mask = st.session_state.df_planning['Service'].isin(dept_filter)
df_filtered = st.session_state.df_planning[mask]

# --- VUE CALENDRIER (GANTT) ---
if not df_filtered.empty:
    fig = px.timeline(df_filtered, 
                      x_start="Début", 
                      x_end="Fin", 
                      y="Employé", 
                      color="Motif",
                      color_discrete_map=MOTIFS_COLORS,
                      title="Planning Visuel SoluCalc",
                      hover_data=['Service'])
    fig.update_yaxes(autorange="reversed")
    st.plotly_chart(fig, use_container_width=True)

# --- CALCULATEUR DE SOLDE ---
st.markdown("---")
st.subheader("📊 Solde des Congés (Quota annuel : 25 j)")
df_solde = st.session_state.df_planning[st.session_state.df_planning['Motif'] == 'Congé'].copy()
df_solde['Jours'] = (df_solde['Fin'] - df_solde['Début']).dt.days + 1
solde_summary = df_solde.groupby('Employé')['Jours'].sum().reset_index()
solde_summary['Reste'] = 25 - solde_summary['Jours']
st.table(solde_summary)

# --- EXPORT NAS ---
st.markdown("---")
csv = st.session_state.df_planning.to_csv(index=False).encode('utf-8')
st.download_button(
    label="📂 Exporter pour archivage NAS",
    data=csv,
    file_name=f'planning_solucalc_{datetime.now().strftime("%Y%m%d")}.csv',
    mime='text/csv',
)
