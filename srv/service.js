const cds = require('@sap/cds');

module.exports = cds.service.impl(async function () {
    const { Professionals, Trades, Neighborhoods, PublicReviews, Citizens } = this.entities;

    // 1. Auditoría de Operadores: Completar automáticamente validatedBy y validationDate
    this.before(['CREATE', 'UPDATE'], 'Professionals', req => {
        if (req.user.is('OPERADOR')) {
            req.data.validatedBy = req.user.id || 'ANONYMOUS_OPERADOR';
            req.data.validationDate = new Date().toISOString();
        }
    });

    // 3 & 4. Autenticación Google y Regla de Oro (Prevención de Spam)
    this.on('submitReview', async (req) => {
        const { professionalID, rating, comment } = req.data;
        const userEmail = req.user.id; // En una integración real, esto vendría del token de Google

        if (!userEmail) return req.error(401, 'Debes iniciar sesión con Google para dejar una reseña.');

        // 1. Asegurar que el ciudadano existe en nuestra base (o crearlo)
        let citizen = await SELECT.one.from(Citizens).where({ email: userEmail });
        if (!citizen) {
            citizen = await INSERT.into(Citizens).entries({
                email: userEmail,
                fullName: req.user.name || userEmail,
                googleId: req.user.id
            });
            citizen = { ID: citizen.results[0].ID }; // Simplificado para el ejemplo
        }

        // 2. Verificar si ya dejó una reseña para este profesional (Regla de Oro)
        const existingReview = await SELECT.one.from(PublicReviews).where({
            professional_ID: professionalID,
            citizen_ID: citizen.ID
        });

        if (existingReview) return req.error(400, 'Ya has dejado una reseña para este profesional.');

        // 3. Guardar la reseña
        await INSERT.into(PublicReviews).entries({
            professional_ID: professionalID,
            citizen_ID: citizen.ID,
            rating: rating,
            comment: comment,
            isModerated: false
        });

        return "Reseña enviada con éxito. Pendiente de moderación.";
    });

    // 5. Calcular Average Rating al leer profesionales
    this.after('READ', 'Professionals', async (each) => {
        if (each.ID) {
            const result = await SELECT.one.from(PublicReviews)
                .columns('avg(rating) as average')
                .where({ professional_ID: each.ID, isModerated: false });
            each.averageRating = result ? result.average : 0;
        }
    });

    // 4. Reportes para el Intendente: Estadísticas por barrio y oficio
    this.on('getMunicipalStats', async (req) => {
        const stats = await cds.run(
            SELECT.from(Professionals)
                .columns('neighborhood.name as neighborhood', 'trade.name as trade', 'count(*) as count')
                .groupBy('neighborhood.name', 'trade.name')
        );
        return stats;
    });

    // 5. Búsqueda por Radio de Cercanía
    this.on('getNearbyProfessionals', async (req) => {
        const { lat, lon, radius } = req.data;

        // Obtenemos todos los activos
        const allActive = await SELECT.from(Professionals).where({ status: 'ACTIVE' });

        // Función simple de distancia Haversine
        const calculateDistance = (lat1, lon1, lat2, lon2) => {
            const R = 6371; // km
            const dLat = (lat2 - lat1) * Math.PI / 180;
            const dLon = (lon2 - lon1) * Math.PI / 180;
            const a =
                Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
            return R * c;
        };

        return allActive.filter(p => {
            if (!p.latitude || !p.longitude) return false;
            const dist = calculateDistance(lat, lon, p.latitude, p.longitude);
            return dist <= radius;
        });
    });
});
