package Net::Async::UPnP::Service;
use Moo 2;
use 5.020; # signatures
use feature 'signatures';
no warnings 'experimental::signatures';
use URI;
use Carp 'croak';
use Encode 'encode';

our $VERSION = '0.01';

around BUILDARGS => sub( $orig, $class, %args ) {
    if( exists $args{ description } and ! ref $args{ description } ) {
        $args{ description } = XML::LibXML->load_xml( string => $args{ description } );
    };
    return $class->$orig(%args)
};

has 'controlpoint' => (
    is => 'ro',
    weak_ref => 1,
);

has 'xpc' => (
    is => 'lazy',
    default => sub($s) {
        my $xpc = XML::LibXML::XPathContext->new;
        $xpc->registerNs('dev', 'urn:schemas-upnp-org:device-1-0');
        $xpc->registerNs('ev', 'urn:schemas-upnp-org:event-1-0');
        return $xpc;
    },
);

has 'description' => (
    is => 'ro',
);

has 'device' => (
    is => 'ro',
    weak_ref => 1,
);

has 'eventsuburl' => (
    is => 'lazy',
    default => sub($s) {
        my $base = $s->device->urlbase || $s->device->location;
        URI->new_abs( $s->get_attribute( 'eventSubURL' ), $base )
    }
);

has 'id' => (
    is => 'lazy',
    default => sub($s) { $s->device->udn . ":" . $s->type },
);

sub get_attribute( $self, $attr ) {
    my @res = $self->xpc->findnodes( ".//dev:$attr", $self->description )->get_nodelist;

    if( @res ) {
        return $res[0]->textContent
    } else {
        return
    }
}

has 'type' => (
    is => 'lazy',
    default => sub($s) { $s->get_attribute('serviceType') },
);

has 'controlurl' => (
    is => 'lazy',
    default => sub($s) {
        my $base = $s->device->urlbase || $s->device->location;
        URI->new_abs( $s->get_attribute( 'controlURL' ), $base )
    }
);

# I've looked at SOAP::Serializer and XML::Compile::SOAP, and wept
sub _soap_xml( $self, $action_name,$args ) {
    $action_name or croak "Need an action_name";
    my $service_type = delete $args->{ service_type } // $self->type or croak "Need a service_type";
    my $res = <<"SOAP_CONTENT";
<?xml version="1.0" encoding="utf-8\"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
<u:$action_name xmlns:u="$service_type">
SOAP_CONTENT

	if (ref $args) {
		while (my ($arg_name, $arg_value) = each (%{$args} ) ) {
			if (length($arg_value) <= 0) {
				$res .= encode('UTF-8', "<$arg_name />\n");
			} else {
                $res .= encode('UTF-8', "<$arg_name>$arg_value</$arg_name>\n");
            }
		}
	}

    $res .= <<"SOAP_CONTENT";
</u:$action_name>
</s:Body>
</s:Envelope>
SOAP_CONTENT

    return $res
}

sub _parse_soap_response( $self, $action, $body ) {
}

sub postaction( $self, $action_name, $args ) {
    my $loc = $self->controlurl;
    $action_name or croak "Need an action_name";
    my $soap = $self->_soap_xml($action_name, $args);
    my $ua = $self->device->ua;
    my $type = $self->type;
    my $action = "$type#$action_name",;

    $ua->do_request(
        uri => $loc,
        headers => {
            SOAPACTION => $action,
        },
        content_type => 'text/xml; charset="utf-8"',
        content => $soap,
        method => 'POST',
    )->then( sub( $res ) {
        # decode the SOAP response maybe?!
        if( $res->code == 200 ) {
            my $body = $res->decoded_content;
            $body =~ m!<(?:\w+:)?${action_name}Response[^>]*>(.*?)</(?:\w+:)?${action_name}Response>!
                or return Future->fail(xmlerror => 500, "Invalid XML:\n". $body);
            my $res = $1;
            my %results;
            while( $res =~ m!<((?:\w+:)?(\w+))(?:[^>]*)>([^<]*)</\1>!sg ) {
                my $name = $2;
                my $r = $3;
                $r = Net::Async::UPnP::entity_decode( $r );
                $results{ $name } = $r;
            }
            Future->done( \%results )
        } else {
            warn $res->code . " for $action";
            Future->fail( error => $res->code, $res->decoded_content )
        }
    });
}

sub subscribe( $self, $cb ) {
    return $self->controlpoint->subscribe_service(
        service => $self,
        cb => $cb
    );
}

# There is no unsubscribe yet

1;
