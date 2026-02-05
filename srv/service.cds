using { sc.muni as my } from '../db/schema';

@(requires: 'OPERADOR')
service AdminService {
    @odata.draft.enabled
    entity Professionals as projection on my.Professionals;
    
    entity Trades as projection on my.Trades;
    entity Categories as projection on my.Categories;
    entity Neighborhoods as projection on my.Neighborhoods;
    entity Specializations as projection on my.Specializations;
    entity Reviews as projection on my.PublicReviews;
    entity Citizens as projection on my.Citizens;

    // Reportes para el Intendente
    function getMunicipalStats() returns array of {
        neighborhood : String;
        trade        : String;
        count        : Integer;
    };
}

service PublicService {
    @readonly
    entity Professionals as projection on my.Professionals {
        ID, fullName, phone, email, location, latitude, longitude, registrationNumber,
        trade, neighborhood,
        specializations : redirected to PublicSpecializations,
        reviews : redirected to PublicReviews,
        null as averageRating : Decimal(3,2)
    } where status = 'ACTIVE';

    @readonly
    entity PublicSpecializations as projection on my.ProfessionalSpecializations {
        ID, specialization.name as specName
    };

    @readonly
    entity PublicReviews as projection on my.PublicReviews {
        ID, rating, comment, createdAt,
        citizen.fullName as reviewerName
    } where isModerated = false;

    @requires: 'authenticated-user'
    action submitReview(professionalID: UUID, rating: Integer, comment: String);

    // Búsqueda por Radio de Cercanía
    function getNearbyProfessionals(lat: Decimal(9,6), lon: Decimal(9,6), radius: Integer) returns array of Professionals;
}

// UI Annotations for Professionals
annotate AdminService.Professionals with @(
    UI.HeaderInfo : {
        TypeName       : 'Profesional',
        TypeNamePlural : 'Profesionales',
        Title          : { Value : fullName },
        Description    : { Value : registrationNumber }
    },
    UI.SelectionFields : [
        trade_ID,
        neighborhood_ID,
        status
    ],
    UI.LineItem : [
        { Value : fullName, Label: 'Nombre Completo' },
        { Value : trade.name, Label: 'Oficio' },
        { Value : registrationNumber, Label: 'Matrícula' },
        { Value : phone, Label: 'Teléfono' },
        { Value : neighborhood.name, Label: 'Barrio' },
        { Value : status, Label: 'Estado' }
    ],
    UI.Facets : [
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Información General',
            Target : '@UI.FieldGroup#General'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Especialidades',
            Target : 'specializations/@UI.LineItem'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Contacto',
            Target : '@UI.FieldGroup#Contact'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Ubicación',
            Target : '@UI.FieldGroup#Location'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Auditoría Institucional',
            Target : '@UI.FieldGroup#Audit'
        }
    ],
    UI.FieldGroup #General : {
        Data : [
            { Value : fullName },
            { Value : registrationNumber },
            { Value : trade_ID },
            { Value : status }
        ]
    },
    UI.FieldGroup #Contact : {
        Data : [
            { Value : phone },
            { Value : email }
        ]
    },
    UI.FieldGroup #Location : {
        Data : [
            { Value : neighborhood_ID },
            { Value : location },
            { Value : latitude },
            { Value : longitude }
        ]
    },
    UI.FieldGroup #Audit : {
        Data : [
            { Value : validatedBy, Label: 'Validado por (Operador)' },
            { Value : validationDate, Label: 'Fecha de Validación' }
        ]
    }
);

annotate AdminService.ProfessionalSpecializations with @(
    UI.LineItem : [
        { Value : specialization_ID, Label: 'Especialidad' }
    ]
);

// Annotations for Value Helps
annotate AdminService.Professionals with {
    trade @(
        Common.ValueList : {
            $Type : 'Common.ValueListType',
            CollectionPath : 'Trades',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut', LocalDataProperty : trade_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' }
            ]
        },
        Common.Text : trade.name,
        Common.TextArrangement : #TextOnly
    );
    neighborhood @(
        Common.ValueList : {
            $Type : 'Common.ValueListType',
            CollectionPath : 'Neighborhoods',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut', LocalDataProperty : neighborhood_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' }
            ]
        },
        Common.Text : neighborhood.name,
        Common.TextArrangement : #TextOnly
    );
}

annotate AdminService.ProfessionalSpecializations with {
    specialization @(
        Common.ValueList : {
            $Type : 'Common.ValueListType',
            CollectionPath : 'Specializations',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut', LocalDataProperty : specialization_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' }
            ]
        },
        Common.Text : specialization.name,
        Common.TextArrangement : #TextOnly
    );
}

annotate AdminService.Trades with {
    name @Common.Label : 'Oficio';
}

annotate AdminService.Categories with {
    name @Common.Label : 'Categoría';
}

annotate AdminService.Neighborhoods with {
    name @Common.Label : 'Barrio';
}

annotate AdminService.Specializations with {
    name @Common.Label : 'Especialidad';
}
