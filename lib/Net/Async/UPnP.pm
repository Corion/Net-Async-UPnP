package Net::Async::UPnP;
use 5.020; # signatures
use feature 'signatures';
no warnings 'experimental::signatures';
use Exporter 'import';

our @EXPORT_OK = ('$SSDP_ADDR', '$SSDP_PORT', 'entity_decode');

our $VERSION = '0.01';

=head1 NAME

Net::Async::UPnP - Async Perl extension for UPnP

=cut

our $SSDP_ADDR = '239.255.255.250';
our $SSDP_PORT = 1900;

sub entity_decode( $r ) {
    # Fake-decode XML
    $r =~ s/\&gt;/>/g;
    $r =~ s/\&lt;/</g;
    $r =~ s/\&quot;/\"/g;
    $r =~ s/\&amp;/\&/g;
    return $r
}

1;
