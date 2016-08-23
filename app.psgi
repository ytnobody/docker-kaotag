use strict;
use warnings;
use Amagi;
use Try::Tiny;
use Net::Microsoft::CognitiveServices::Face;

our $FACE           = 'Net::Microsoft::CognitiveServices::Face';
our $ACCESS_KEY     = $ENV{'MS_ACCESS_KEY'};
our $PERSONGROUP_ID = 'kaotag';

### Set the access_key
$FACE->access_key($ACCESS_KEY);

### Initialize the PersonGroup
our $person_group = try {
    $FACE->PersonGroup->get($PERSONGROUP_ID)
} catch {
    $FACE->PersonGroup->create($PERSONGROUP_ID, name => 'kaotag');
    $FACE->PersonGroup->get($PERSONGROUP_ID);
};

### Get training status
get '/' => sub {
    my $status = try {
        $FACE->PersonGroup->training_status($PERSONGROUP_ID);
    } catch {
        {message => $_, createdDateTime => undef, lastActionDateTime => undef, status => undef};
    };
    {result => $status};
};

### Add person with face
post '/person/' => sub {
    my ($app, $req) = @_;
    my $img  = $req->param('img');
    my $name = $req->param('name');
    if (!defined $img || !defined $name) {
        return $app->error_res(400 => 'parameter "img" and "name" is required');
    }
    my $person = $FACE->Person->create($PERSONGROUP_ID, name => $name);
    $FACE->Person->add_face($PERSONGROUP_ID, $person->{personId}, $img);
    $FACE->PersonGroup->train($PERSONGROUP_ID);
    {result => {person => $person}};
};

### Identify a person by face
get '/person/' => sub {
    my ($app, $req) = @_;
    my $img = $req->param('img');
    if (!defined $img) {
        return $app->error_res(400 => 'parameter "img" is required');
    }
    my $face    = $FACE->Face->detect($img);
    my $matched = $FACE->Face->identify(
        faceIds                    => [$face->[0]{faceId}],
        personGroupId              => $PERSONGROUP_ID,
        confidenceThreshold        => 0.5,
        maxNumOfCandidatesReturned => 1,
    );
    my $candidate = $matched->[0]{candidates}[0];
    my $person    = $FACE->Person->get($PERSONGROUP_ID, $candidate->{personId});
    {result => {person => $person, face => $face}}; 
};

get '/persons' => sub {
    my ($app, $req) = @_;
    my $result = $FACE->Person->list($PERSONGROUP_ID);
    {result => $result};
};

post '/person/:personId' => sub {
    my ($app, $req) = @_;
    my $person_id = $req->param('id');
    my $tag = $req->param('tag');
    if (!defined $person_id || !defined $tag) {
        return $app->res_error(400 => 'parameter "id" and "tag" is required');
    }
    my $person = $FACE->Person->get($PERSONGROUP_ID, $person_id);
    $FACE->Person->update($PERSONGROUP_ID, name => $person->{name}, userData => join($person->{userData}, $tag));
    {result => {message => "done"}};
};


### flush PersonGroup
post '/flush' => sub {
    $FACE->PersonGroup->delete($PERSONGROUP_ID);
    $FACE->PersonGroup->create($PERSONGROUP_ID, name => 'kaotag');
    {result => 'done'};
};

__PACKAGE__->app;
