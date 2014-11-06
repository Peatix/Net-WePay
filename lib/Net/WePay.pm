package Net::WePay;

use strict;
use warnings;

use HTTP::Request::Common qw( POST );
use JSON qw( encode_json decode_json );
use LWP::UserAgent;
use URI;

our $VERSION = '0.01';

use constant STAGE_API_ENDPOINT => "https://stage.wepayapi.com/v2";
use constant PRODUCTION_API_ENDPOINT => "https://wepayapi.com/v2";

sub new {
    my $class = shift;
    my %params = @_;

    my $is_production = $params{ is_production } || 0;
    $params{ endpoint } = $is_production
        ? PRODUCTION_API_ENDPOINT
        : STAGE_API_ENDPOINT
    ;
    unless ( exists $params{ ua } ) {
        $params{ ua } = LWP::UserAgent->new;
        $params{ ua }->agent( "WePay v2 Perl SDK v$VERSION" );
    }
    return bless \%params, $class;
}

sub call {
    my $wepay_object = shift;
    my ( $api_path, %params ) = @_;

    my $ua = $wepay_object->{ ua };

    $api_path =~ /^\// or $api_path = "/$api_path";
    my $uri = URI->new( $wepay_object->{ endpoint } . $api_path );

    my $request = HTTP::Request->new( POST => $uri );
    $request->header( 'Content-Type' => 'application/json' );
    $request->header( Authorization => ( 'Bearer ' . $wepay_object->{ access_token } ) );
    $wepay_object->{ api_version } and
        $request->header( 'Api-Version' => $wepay_object->{ api_version }  );
    %params and
        $request->content( encode_json( \%params ) );

    my $response = $ua->request( $request );

    if ( $response->is_success ) {
        my $ret = decode_json( $response->decoded_content );
        return $ret;
    }
    else {
        my $ret = eval { decode_json( $response->decoded_content ); };
        $ret and
            return $ret;
        $ret = { error => 'unknown_error', error_code => $response->code, error_description => $response->decoded_content };
    }
}

1;
__END__
=head1 NAME

Net::WePay - helps you make API calls to the WePay API v2

=head1 SYNOPSIS

  my $wepay = Net::WePay->new(
      access_token  => 'Access Token of your merchant'
  );

  my $response_body_hash = $wepay->call(
      '/checkout/create'
      , account_id        => 'Account ID of your merchant'
      , short_description => 'Gorgeous LED TV 50 inch'
      , type              => 'GOODS'
      , amount            => '5999.99'
  );

  my $checkout_id = $response_body_hash->{ checkout_id };

See Net::WePay::OAuth2 for how the module helps getting an access_token
on behalf of your merchant.

=head1 DESCRIPTION

This module is a bunch of helper methods that does most of the
heavy liftings required to call WePay API v2.

=head1 METHODS

=head2 new

( access_token => ..., is_production => ..., )

=head2 call

($api_path, %params )

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 AUTHOR

Fumiaki Yoshimatsu

=head1 SEE ALSO

=cut
