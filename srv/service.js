const cds = require('@sap/cds');

module.exports = cds.service.impl(async function() {
    const { Professionals, Trades, Neighborhoods } = this.entities;

    // 1. Auditoría de Operadores: Completar automáticamente validatedBy y validationDate
    this.before(['CREATE', 'UPDATE'], 'Professionals', req => {
        req.data.validatedBy = req.user.id || 'ANONYMOUS_OPERADOR';
        req.data.validationDate = new Date().toISOString();
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

        // Función simple de distancia Haversine (simplificada para este caso)
        const calculateDistance = (lat1, lon1, lat2, lon2) => {
            const R = 6371; // Radio de la Tierra en km
            const dLat = (lat2 - lat1) * Math.PI / 180;
            const dLon = (lon2 - lon1) * Math.PI / 180;
            const a = 
                Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
                Math.sin(dLon/2) * Math.sin(dLon/2);
            const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
            return R * c;
        };

        return allActive.filter(p => {
            if (!p.latitude || !p.longitude) return false;
            const dist = calculateDistance(lat, lon, p.latitude, p.longitude);
            return dist <= radius;
        });
    });
});
