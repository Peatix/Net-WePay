package Net::WePay::OAuth2;

use strict;
use warnings;

use HTTP::Request::Common qw( POST );
use JSON qw( encode_json decode_json );
use LWP::UserAgent;
use URI;

our $VERSION = '0.01';

use constant STAGE_UI_ENDPOINT => "https://stage.wepay.com/v2";
use constant PRODUCTION_UI_ENDPOINT => "https://www.wepay.com/v2";

use constant STAGE_API_ENDPOINT => "https://stage.wepayapi.com/v2";
use constant PRODUCTION_API_ENDPOINT => "https://wepayapi.com/v2";

sub new {
    my $class = shift;
    my %params = @_;

    my $is_production = $params{ is_production } || 0;
    $params{ ui_endpoint } = $is_production
        ? PRODUCTION_UI_ENDPOINT
        : STAGE_UI_ENDPOINT
    ;
    $params{ api_endpoint } = $is_production
        ? PRODUCTION_API_ENDPOINT
        : STAGE_API_ENDPOINT
    ;
    $params{ redirect_uri } && ref( $params{ redirect_uri } ) and
        $params{ redirect_uri } = $params{ redirect_uri }->as_string
    ;
    unless ( exists $params{ ua } ) {
        $params{ ua } = LWP::UserAgent->new;
        $params{ ua }->agent( "WePay v2 Perl SDK v$VERSION" );
    }
    return bless \%params, $class;
}

sub get_authorize_uri {
    my $wepay_object = shift;
    my ( $permissions, %params ) = @_;

    $permissions && @$permissions or
        $permissions = [
            'manage_accounts'
            #, 'collect_payments'
            #, 'view_user'
            #, 'send_money'
            #, 'preapprove_payments'
            #, 'manage_subscriptions'
        ]
    ;
    my $uri = URI->new( $wepay_object->{ ui_endpoint } . '/oauth2/authorize' );
    $uri->query_form(
        client_id      => $wepay_object->{ client_id }
        , redirect_uri => $wepay_object->{ redirect_uri }
        , scope        => join( ',', @$permissions )
        , %params
    );

    return $uri;
}

sub get_token_from_code {
    my $wepay_object = shift;
    my ( $code ) = @_;

    my %params = (
        client_id       => $wepay_object->{ client_id }
        , client_secret => $wepay_object->{ client_secret }
        , redirect_uri  => $wepay_object->{ redirect_uri }
        , code          => $code
    ); 

    my $ua = $wepay_object->{ ua };

    my $uri = URI->new( $wepay_object->{ api_endpoint } . '/oauth2/token' );

    my $request = HTTP::Request->new( POST => $uri );
    $request->header( 'Content-Type' => 'application/json' );
    $wepay_object->{ api_version } and
        $request->header( 'Api-Version' => $wepay_object->{ api_version }  );
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

Net::WePay::OAuth2 - helps you make API calls to the WePay OAuth2 endpoint

=head1 SYNOPSIS

  my $wepay_oauth2 = Net::WePay::OAuth2->new(
      client_id       => 'Your App\'s client id'
      , client_secret => 'Your App\'s client secret'
      , redirect_uri  => URI->new( 'http://your-oauth-call-back-endpoint' )
      , is_production => 0 # decides which WePay endpoint to go
  );

  my $uri = $wepay_oauth2->get_authorize_uri(
      permissions  => [ 'manage_accounts', 'collect_payments' ]
      , user_name  => 'Merchant\'s name'
      , user_email => 'Merchant\'s email'
      , state      => 'surfin csrf'
  );

  $res->redirect( $uri );

  ...

  my $code = $req->params->{ code }; # in OAuth2 response
  my $access_token_info = $wepay_oauth2->get_token_from_code(
      $code
  );

See Net::WePay for how the module helps calling WePay API.

=head1 DESCRIPTION

This module is a bunch of helper methods that does most of the
heavy liftings required to call WePay API v2.

=head1 METHODS

=head2 new

( client_id => ..., client_secret => ..., redirect_uri => ..., is_production => ..., )

=head2 get_authorize_uri

( \@permissions, %( user_email => ..., user_name => ... ) )

=head2 get_token_from_code

( $code )

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 AUTHOR

Fumiaki Yoshimatsu

=head1 SEE ALSO

=cut
