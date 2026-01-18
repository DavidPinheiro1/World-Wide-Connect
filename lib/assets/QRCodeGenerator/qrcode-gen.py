import qrcode
from PIL import Image
import os

# --- 1. SETUP ---
# Your Logo Path (Mantido exatamente como enviaste)
logo_path = r"C:\Users\David Pinheiro\Documents\GitHub\World-Wide-Connect\lib\assets\icon\icon.png"
save_folder = r"C:\Users\David Pinheiro\Documents\GitHub\World-Wide-Connect\lib\assets\qrcodes"

# Ensure the save folder exists
os.makedirs(save_folder, exist_ok=True)

# --- AQUI ESTÁ A LÓGICA DO GITHUB ---
# O link base do teu repositório
base_url = "https://github.com/DavidPinheiro1/World-Wide-Connect"

# Define your data
# Agora usamos o URL com um parâmetro '?topic='. 
# - O telemóvel ignora o '?topic=' e abre o site.
# - A tua App lê o texto todo, encontra a palavra 'mensa' e abre a página certa.
qr_data = {
    "Mensa": f"{base_url}?topic=mensa",
    "Transportation": f"{base_url}?topic=transport",
    "Citizenship": f"{base_url}?topic=citizen"
}

# Load the logo once
try:
    logo = Image.open(logo_path)
except FileNotFoundError:
    print(f"Error: Could not find logo at {logo_path}")
    exit()

# --- 2. GENERATION LOOP ---
for name, link_data in qr_data.items():
    
    # Create the QR Code object
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H, # Alto nível de correção para suportar o logo
        box_size=10,
        border=2,
    )
    
    # Add data (O URL completo)
    qr.add_data(link_data)
    qr.make(fit=True)
    
    # Create the QR image (Color formatted to RGB)
    img_qr = qr.make_image(fill_color="black", back_color="white").convert('RGB')
    
    # --- 3. ADD LOGO ---
    # Resize logo to fit nicely in the center (25% of the QR width)
    logo_size = int(img_qr.size[0] * 0.25) 
    logo_resized = logo.resize((logo_size, logo_size))
    
    # Calculate position to center the logo
    pos = ((img_qr.size[0] - logo_resized.size[0]) // 2, 
           (img_qr.size[1] - logo_resized.size[1]) // 2)
    
    # Paste the logo onto the QR code
    # Mantive a tua lógica de máscara para transparência
    mask = logo_resized if 'A' in logo.mode else None
    img_qr.paste(logo_resized, pos, mask)
    
    # --- 4. SAVE ---
    filename = f"{name}.png"
    full_save_path = os.path.join(save_folder, filename)
    
    img_qr.save(full_save_path)
    print(f"Generated clean QR code: {filename} -> {link_data}")