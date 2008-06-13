package TapTinder::Web::Model::WebDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'TapTinder::DB::SchemaAdd',
    connect_info => [
       TapTinder::Web->config->{db}->{dbi_dsn},
       TapTinder::Web->config->{db}->{user},
       TapTinder::Web->config->{db}->{pass},
        { AutoCommit => 1 },
    ],
);


1;
