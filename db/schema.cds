namespace sc.muni;

using { managed, cuid } from '@sap/cds/common';

type ProfessionalStatus : String enum {
    ACTIVE    = 'ACTIVE';
    INACTIVE  = 'INACTIVE';
    SUSPENDED = 'SUSPENDED';
    EXPIRED   = 'EXPIRED';
}

entity Professionals : cuid, managed {
    fullName           : String(100);
    registrationNumber : String(50); // Matrícula
    phone              : String(20);
    email              : String(100);
    location           : String(255);
    latitude           : Decimal(9, 6);
    longitude          : Decimal(9, 6);
    status             : ProfessionalStatus default 'ACTIVE';
    validatedBy        : String(100); // ID del Operador
    validationDate     : Timestamp;
    trade              : Association to Trades;
    neighborhood       : Association to Neighborhoods;
    specializations    : Composition of many ProfessionalSpecializations on specializations.professional = $self;
}

entity Trades : cuid {
    name           : String(100);
    category       : Association to Categories;
    specializations : Association to many Specializations on specializations.trade = $self;
    professionals  : Association to many Professionals on professionals.trade = $self;
}

entity Specializations : cuid {
    name  : String(100);
    trade : Association to Trades;
}

entity ProfessionalSpecializations : cuid {
    professional   : Association to Professionals;
    specialization : Association to Specializations;
}

entity Categories : cuid {
    name   : String(100);
    trades : Association to many Trades on trades.category = $self;
}

entity Neighborhoods : cuid {
    name : String(100);
    professionals : Association to many Professionals on professionals.neighborhood = $self;
}
