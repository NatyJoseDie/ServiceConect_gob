using { sc.muni as my } from '../db/schema';

@(requires: 'OPERADOR')
service AdminService {
    @odata.draft.enabled
    entity Professionals as projection on my.Professionals;
    
    entity Trades as projection on my.Trades;
    entity Categories as projection on my.Categories;
    entity Neighborhoods as projection on my.Neighborhoods;
}

service PublicService {
    @readonly
    entity Professionals as projection on my.Professionals {
        ID, fullName, phone, email, location, latitude, longitude, trade, neighborhood
    } where isVerified = true;
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
        isVerified
    ],
    UI.LineItem : [
        { Value : fullName, Label: 'Nombre Completo' },
        { Value : trade.name, Label: 'Oficio' },
        { Value : registrationNumber, Label: 'Matrícula' },
        { Value : phone, Label: 'Teléfono' },
        { Value : neighborhood.name, Label: 'Barrio' },
        { Value : isVerified, Label: 'Verificado' }
    ],
    UI.Facets : [
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Información General',
            Target : '@UI.FieldGroup#General'
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
        }
    ],
    UI.FieldGroup #General : {
        Data : [
            { Value : fullName },
            { Value : registrationNumber },
            { Value : trade_ID },
            { Value : isVerified }
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
    }
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

annotate AdminService.Trades with {
    name @Common.Label : 'Oficio';
    category @(
        Common.ValueList : {
            $Type : 'Common.ValueListType',
            CollectionPath : 'Categories',
            Parameters : [
                { $Type : 'Common.ValueListParameterInOut', LocalDataProperty : category_ID, ValueListProperty : 'ID' },
                { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' }
            ]
        },
        Common.Text : category.name,
        Common.TextArrangement : #TextOnly
    );
}

annotate AdminService.Categories with {
    name @Common.Label : 'Categoría';
}

annotate AdminService.Neighborhoods with {
    name @Common.Label : 'Barrio';
}
