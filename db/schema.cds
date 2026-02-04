namespace sc.muni;

using { managed, cuid } from '@sap/cds/common';

entity Professionals : cuid, managed {
    fullName           : String(100);
    registrationNumber : String(50); // Matrícula
    phone              : String(20);
    email              : String(100);
    location           : String(255);
    latitude           : Decimal(9, 6);
    longitude          : Decimal(9, 6);
    isVerified         : Boolean default true;
    trade              : Association to Trades;
    neighborhood       : Association to Neighborhoods;
}

entity Trades : cuid {
    name        : String(100);
    category    : Association to Categories;
    professionals : Association to many Professionals on professionals.trade = $self;
}

entity Categories : cuid {
    name   : String(100);
    trades : Association to many Trades on trades.category = $self;
}

entity Neighborhoods : cuid {
    name : String(100);
    professionals : Association to many Professionals on professionals.neighborhood = $self;
}
