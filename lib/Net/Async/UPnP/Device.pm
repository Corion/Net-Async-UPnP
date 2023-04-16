package Net::Async::UPnP::Device;
use Moo 2;
use 5.020; # signatures
use feature 'signatures';
no warnings 'experimental::signatures';

use URI;
use XML::LibXML '1.170';

our $VERSION = '0.01';

has 'ua' => (
    is => 'ro',
    weak_ref => 1,
    default => sub ($self) {
        Net::Async::HTTP->new();
    },
);

has 'urlbase' => (
    is => 'ro',
);

has 'controlpoint' => (
    is => 'ro',
    weak_ref => 1,
);

has 'ssdp' => (
    is => 'ro',
);

has 'description' => (
    is => 'ro',
);

has 'location' => (
    is => 'ro',
);

has 'devicetype' => (
    is => 'lazy',
    default => sub($s) { $s->get_attribute('deviceType');},
);

has 'manufacturer' => (
    is => 'lazy',
    default => sub($s) { $s->get_attribute('manufacturer');},
);

has 'friendlyname' => (
    is => 'lazy',
    default => sub($s) { $s->get_attribute('friendlyName');},
);

has 'udn' => (
    is => 'lazy',
    default => sub($s) { $s->get_attribute('UDN');},
);

has 'services' => (
    is => 'lazy',
    default => \&_parse_services,
);

around BUILDARGS => sub( $orig, $class, %args ) {
    if( exists $args{ description } and ! ref $args{ description } ) {
        $args{ description } = XML::LibXML->load_xml( string => $args{ description } );
    };
    return $class->$orig(%args)
};

has 'xpc' => (
    is => 'lazy',
    default => sub($s) {
        my $xpc = XML::LibXML::XPathContext->new;
        $xpc->registerNs('dev', 'urn:schemas-upnp-org:device-1-0');
        $xpc->registerNs('ev', 'urn:schemas-upnp-org:event-1-0');
        return $xpc;
    },
);

sub get_attribute( $self, $attr ) {
    my @res = $self->xpc->findnodes( ".//dev:$attr", $self->description )->get_nodelist;

    if( @res ) {
        return $res[0]->textContent
    } else {
        return
    }
}

sub _parse_services( $self, $description = $self->description ) {
    my @services = $self->xpc->findnodes( './/dev:serviceList/dev:service', $self->description );
    @services = map {
        my $d = $_;
        Net::Async::UPnP::Service->new(
            device       => $self,
            description  => $d,
            controlpoint => $self->controlpoint,
        );
    } @services;
    return \@services;
}

sub service_by_name( $self, $name ) {
    foreach my $s ($self->services->@*) {
        return $s if $s->type eq $name
    }
    return ()
}

1;
