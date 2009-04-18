use strict;
use warnings;

use Test::More;
use lib 't/lib';

use DateTime;

BEGIN
{
   plan tests => 9;
}

{
   package My::Form;
   use HTML::FormHandler::Moose;
   extends 'HTML::FormHandler';

   use Moose::Util::TypeConstraints;

   subtype 'MyStr'
       => as 'Str'
       => where { /^a/ };

   subtype 'MyInt'
       => as 'Int';
 
   coerce 'MyInt'
       => from 'MyStr'
       => via { return $1 if /(\d+)/ };

   type 'MyDateTime'
       => message { 'This is not a correct date' };
   coerce 'MyDateTime'
       => from 'HashRef'
       => via { DateTime->new( $_ ) };


   has_field 'sprintf_filter' => (
      actions => [ { transform => sub{ sprintf '<%.1g>', $_[0] } } ]
   );
   has_field 'date_time_error' => (
      actions => [ { transform => sub{ DateTime->new( $_[0] ) } } ],
   );
   has_field 'date_time' => ( 
      type => 'Compound',
      actions => [ { transform => sub{ DateTime->new( $_[0] ) } } ],
   );
   has_field 'date_time.year' => ( type => 'Text', );
   has_field 'date_time.month' => ( type => 'Text', );
   has_field 'date_time.day' => ( type => 'Text', );

   has_field 'coerce_error' => (
      actions => [ 'MyInt' ]
   );
   has_field 'coerce_pass' => (
      actions => [ 'MyInt' ]
   );
   
   has_field 'date_coercion_pass' => ( 
      type => 'Compound',
      actions => [ 'MyDateTime' ],
   );
   has_field 'date_coercion_pass.year' => ( type => 'Text', );
   has_field 'date_coercion_pass.month' => ( type => 'Text', );
   has_field 'date_coercion_pass.day' => ( type => 'Text', );

   has_field 'date_coercion_error' => ( 
      type => 'Compound',
      actions => [ 'MyDateTime' ],
   );
   has_field 'date_coercion_error.year' => ( type => 'Text', );
   has_field 'date_coercion_error.month' => ( type => 'Text', );
   has_field 'date_coercion_error.day' => ( type => 'Text', );

}


my $form = My::Form->new();
ok( $form, 'get form' );

my $params = $form->validate(
   {
      sprintf_filter   => '100',
      date_time_error  => 'aaa',
      'date_time.year' => 2009,
      'date_time.month' => 4,
      'date_time.day' => 16,
      coerce_error => 'b10',
      coerce_pass  => 'a10',
      'date_coercion_pass.year' => 2009,
      'date_coercion_pass.month' => 4,
      'date_coercion_pass.day' => 16,
      'date_coercion_error.year' => 2009,
      'date_coercion_error.month' => 20,
      'date_coercion_error.day' => 16,
   }
);

is( $form->field('sprintf_filter')->value, '<1e+02>', 'sprintf filter' );
ok( $form->field('date_time_error')->has_errors,      'DateTime error catched' );
is( ref $form->field('date_time')->value, 'DateTime',   'DateTime object created' );
ok( $form->field('coerce_error')->has_errors,     'no suitable coercion - error' );
is( $form->field('coerce_pass')->value, 10, 'coercion filter' );
is( ref $form->field('date_coercion_pass')->value, 'DateTime',   'values coerced to DateTime object' );
ok( $form->field('date_coercion_error')->has_errors,     'DateTime coercion error' );
my ( $message ) = $form->field('date_coercion_error')->errors;
is( $message, 'This is not a correct date', 'Error message for coercion' );

