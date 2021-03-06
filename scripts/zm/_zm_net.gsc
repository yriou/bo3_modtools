#using scripts\codescripts\struct;

#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

#namespace zm_net;

function network_choke_init( id, max )
{
	if ( !isdefined( level.zombie_network_choke_ids_max ) )
	{
		level.zombie_network_choke_ids_max = [];
		level.zombie_network_choke_ids_count = [];
	}

	level.zombie_network_choke_ids_max[ id ] = max;
	level.zombie_network_choke_ids_count[ id ] = 0;

	level thread network_choke_thread( id );
}

function network_choke_thread( id )
{
	while( 1 )
	{
		util::wait_network_frame();
		util::wait_network_frame();
		level.zombie_network_choke_ids_count[ id ] = 0;
	}
}

function network_choke_safe( id )
{
	return( level.zombie_network_choke_ids_count[ id ] < level.zombie_network_choke_ids_max[ id ] );
}

function network_choke_action( id, choke_action, arg1, arg2, arg3 )
{
	Assert( isdefined( level.zombie_network_choke_ids_max[ id ] ), "Network Choke: " + id + " undefined" );

	while( !network_choke_safe( id ) )
	{
		WAIT_SERVER_FRAME;		
	}

	level.zombie_network_choke_ids_count[ id ]++;

	if ( !isdefined( arg1 ) )
	{
		return ( [[choke_action]]() );
	}

	if ( !isdefined( arg2 ) )
	{
		return ( [[choke_action]]( arg1 ) );
	}
	
	if ( !isdefined( arg3 ) )
	{
		return ( [[choke_action]]( arg1, arg2 ) );
	}
	
	return ( [[choke_action]]( arg1, arg2, arg3 ) );
}

function network_entity_valid( entity )
{
	if( !isdefined( entity ) )
	{
		return false;
	}
	
	return true;
}

function network_safe_init( id, max )
{
	if ( !isdefined( level.zombie_network_choke_ids_max ) || !isdefined( level.zombie_network_choke_ids_max[ id ] ) )
	{
		network_choke_init( id, max );
	}

	assert( max == level.zombie_network_choke_ids_max[ id ] );
}

// SPAWNING
function _network_safe_spawn( classname, origin )
{
	return spawn( classname, origin );
}

function network_safe_spawn( id, max, classname, origin )
{
	network_safe_init( id, max );
	return ( network_choke_action( id,&_network_safe_spawn, classname, origin ) );
}

// FX
function _network_safe_play_fx_on_tag( fx, entity, tag )
{
	if ( network_entity_valid( entity ) )
	{
		PlayFxOnTag( fx, entity, tag );
	}
}

function network_safe_play_fx_on_tag( id, max, fx, entity, tag )
{
	network_safe_init( id, max );
	network_choke_action( id,&_network_safe_play_fx_on_tag, fx, entity, tag );
}
