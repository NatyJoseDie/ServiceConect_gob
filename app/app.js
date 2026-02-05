// Configuración inicial del mapa centrada en Florencio Varela
const map = L.map('map').setView([-34.8219, -58.2691], 13);

// Capa de mapa oscura (estética premium)
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OpenStreetMap &copy; CARTO'
}).addTo(map);

async function loadProfessionals() {
    try {
        const response = await fetch('/odata/v4/public/Professionals?$expand=trade,neighborhood');
        const data = await response.json();
        const professionals = data.value;

        const grid = document.getElementById('professionalsGrid');
        grid.innerHTML = '';

        professionals.forEach(prof => {
            // Marcador en el Mapa
            if (prof.latitude && prof.longitude) {
                const marker = L.marker([prof.latitude, prof.longitude]).addTo(map);

                // Pop-over con teléfono y matrícula
                marker.bindPopup(`
                    <div class="pop-over-content">
                        <h4>${prof.fullName}</h4>
                        <p><strong>Oficio:</strong> ${prof.trade ? prof.trade.name : 'N/A'}</p>
                        <p><strong>Matrícula:</strong> ${prof.registrationNumber}</p>
                        <p><strong>Tel:</strong> ${prof.phone}</p>
                        <button class="premium-btn" style="padding: 0.4rem 1rem; font-size: 0.8rem; margin-top: 5px;">Ver Perfil</button>
                    </div>
                `);
            }

            // Tarjeta en el Grid
            const card = document.createElement('div');
            card.className = 'prof-card';
            card.innerHTML = `
                <span class="badge badge-official">OFICIAL VARELA</span>
                <h3>${prof.fullName}</h3>
                <div class="rating">⭐ ${prof.averageRating ? prof.averageRating.toFixed(1) : '5.0'}</div>
                <div class="contact-info">
                    <p>📍 ${prof.neighborhood ? prof.neighborhood.name : 'Varela'}</p>
                    <p>📞 ${prof.phone}</p>
                    <p>📜 Mat: ${prof.registrationNumber}</p>
                </div>
                <button class="premium-btn" onclick="openReviewDialog('${prof.ID}')">Dejar Reseña</button>
            `;
            grid.appendChild(card);
        });
    } catch (error) {
        console.error('Error cargando profesionales:', error);
    }
}

function openReviewDialog(profID) {
    // Simulación: En un sistema real aquí se verificaría la sesión con Google
    const rating = prompt("Califica del 1 al 5:");
    const comment = prompt("Tu comentario:");

    if (rating && comment) {
        submitReview(profID, rating, comment);
    }
}

async function submitReview(profID, rating, comment) {
    try {
        // En una implementación real se enviaría el token de Google en el header
        const response = await fetch('/odata/v4/public/submitReview', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                professionalID: profID,
                rating: parseInt(rating),
                comment: comment
            })
        });

        if (response.ok) {
            alert("¡Gracias! Tu reseña ha sido enviada y será moderada por el equipo municipal.");
            loadProfessionals(); // Recargar para ver estrellas (aunque no el comentario hasta moderar)
        } else {
            const err = await response.json();
            alert("Error: " + (err.error ? err.error.message : "No se pudo enviar la reseña"));
        }
    } catch (error) {
        alert("Error al conectar con el servidor municipal.");
    }
}

// Cargar al inicio
loadProfessionals();
