#using scripts\codescripts\struct;

#using scripts\shared\callbacks_shared;
#using scripts\shared\hud_shared;
#using scripts\shared\scoreevents_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

#insert scripts\shared\scoreevents_shared.gsh;

#precache( "material", "white" );
#precache( "string", "MP_PLUS" );

#namespace rank;

REGISTER_SYSTEM( "rank", &__init__, undefined )
	
function __init__()
{
	callback::on_start_gametype( &init );
}

function init()
{
	level.scoreInfo = [];
	level.codPointsXpScale = GetDvarfloat( "scr_codpointsxpscale" );
	level.codPointsMatchScale = GetDvarfloat( "scr_codpointsmatchscale" );
	level.codPointsChallengeScale = GetDvarfloat( "scr_codpointsperchallenge" );
	level.rankXpCap = GetDvarint( "scr_rankXpCap" );
	level.codPointsCap = GetDvarint( "scr_codPointsCap" );	
	level.usingMomentum = true;
	level.usingScoreStreaks = GetDvarInt( "scr_scorestreaks" ) != 0;
	level.scoreStreaksMaxStacking = GetDvarInt( "scr_scorestreaks_maxstacking" );
	level.maxInventoryScoreStreaks = GetDvarInt( "scr_maxinventory_scorestreaks", 3 );
	level.usingRampage = !isdefined( level.usingScoreStreaks ) || !level.usingScoreStreaks;
	level.rampageBonusScale = GetDvarFloat( "scr_rampagebonusscale" );

	level.rankTable = [];
	
	if ( SessionModeIsCampaignGame() )
	{
		level.xpScale = GetDvarFloat( "scr_xpscalecp" );

		level.ranktable_name = "gamedata/tables/cp/cp_ranktable.csv";
		level.rankicontable_name = "gamedata/tables/cp/cp_rankIconTable.csv";
	}
	else if ( SessionModeIsZombiesGame() )
	{
		level.xpScale = GetDvarFloat( "scr_xpscalezm" );

		level.ranktable_name = "gamedata/tables/zm/zm_ranktable.csv";
		level.rankicontable_name = "gamedata/tables/zm/zm_rankIconTable.csv";
	}
	else
	{
		level.xpScale = GetDvarFloat( "scr_xpscalemp" );

		level.ranktable_name = "gamedata/tables/mp/mp_ranktable.csv";
		level.rankicontable_name = "gamedata/tables/mp/mp_rankIconTable.csv";
	}
	
	initScoreInfo();

	level.maxRank = int(tableLookup( level.ranktable_name, 0, "maxrank", 1 ));
	level.maxRankStarterPack = int(tableLookup( level.ranktable_name, 0, "maxrankstarterpack", 1 ));
	level.maxPrestige = int(tableLookup( level.rankicontable_name, 0, "maxprestige", 1 ));
	
	rankId = 0;
	rankName = tableLookup( level.ranktable_name, 0, rankId, 1 );
	assert( isdefined( rankName ) && rankName != "" );
		
	while ( isdefined( rankName ) && rankName != "" )
	{
		level.rankTable[rankId][1] = tableLookup( level.ranktable_name, 0, rankId, 1 );
		level.rankTable[rankId][2] = tableLookup( level.ranktable_name, 0, rankId, 2 );
		level.rankTable[rankId][3] = tableLookup( level.ranktable_name, 0, rankId, 3 );
		level.rankTable[rankId][7] = tableLookup( level.ranktable_name, 0, rankId, 7 );
		level.rankTable[rankId][14] = tableLookup( level.ranktable_name, 0, rankId, 14 );
		
		if( SessionModeIsCampaignGame() )
		{	//cp has an extra column that awards extra tokens per rank
			level.rankTable[rankId][18] = tablelookup( level.ranktable_name, 0, rankId, 18 );
		}
		rankId++;
		rankName = tableLookup( level.ranktable_name, 0, rankId, 1 );		
	}
	
	callback::on_connect( &on_player_connect );
}


function initScoreInfo()
{
	scoreInfoTableID = scoreevents::getScoreEventTableID();
		
	assert( isdefined( scoreInfoTableID ) );
	if ( !isdefined( scoreInfoTableID ) )
	{
		return;
	}
		
	scoreColumn = scoreevents::getScoreEventColumn( level.gameType );
	xpColumn = scoreevents::getXPEventColumn( level.gameType );

	assert( scoreColumn >= 0 );
	if ( scoreColumn < 0 )
	{
		return; 
	}

	assert( xpColumn >= 0 );
	if ( xpColumn < 0 )
	{
		return;
	}
		
		
	for( row = 1; row < SCORE_EVENT_MAX_COUNT; row++ )
	{
		type = tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_SCRIPT_REFERENCE );
		if ( type != "" )
		{
			labelString = tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_SCORE_STRING );
			label = undefined;
			if ( labelString != "" ) 
			{
				label = tableLookupIString( scoreInfoTableID, 0, type, SCOREINFOTABLE_SCORE_STRING );
			}

			teamScoreString = tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_TEAM_SCORE_MATERIAL );
			teamscore_material = undefined;
			if ( teamScorestring != "" )
			{
				teamscore_material = tableLookupIString( scoreInfoTableID, 0, type, SCOREINFOTABLE_TEAM_SCORE_MATERIAL );
			}

			scoreValue = int( tableLookupColumnForRow( scoreInfoTableID, row, scoreColumn ) );
			xpValue = int( tableLookupColumnForRow( scoreInfoTableID, row, xpColumn ) );
			registerScoreInfo( type, scoreValue, xpValue, label, teamscore_material );

			if ( !isdefined( game["ScoreInfoInitialized"] ) )
			{
				xpValue = float( tableLookupColumnForRow( scoreInfoTableID, row, xpColumn ) );
					
				setDDLStat = tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_SAVE_MEDAL_STATS );
				addPlayerStat = false;
				if ( setDDLStat == "TRUE" )
				{
					addPlayerStat = true;
				}
				isMedal = false;
				iString =  tableLookupIString( scoreInfoTableID, 0, type, SCOREINFOTABLE_MEDAL_REFERENCE );
				if ( isdefined( iString ) && iString != &"" )
				{
					isMedal = true;
				}

				demoBookmarkPriority = int( tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_DEMO_BOOKMARK_PRIORITY ) );
				if ( !isdefined( demoBookmarkPriority ) )
				{
					demoBookmarkPriority = 0;
				}

				RegisterXP( type, xpValue, addPlayerStat, isMedal, demoBookmarkPriority, row );
			}

			allowKillstreakWeapons = tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_INCLUDE_KILLSTREAKS );
			if ( allowKillstreakWeapons == "TRUE" )
			{
				level.scoreInfo[ type ][ "allowKillstreakWeapons" ] = true;
			}
			
			allowHero = tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_INCLUDE_HERO );
			if ( allowHero == "TRUE" )
			{
				level.scoreInfo[ type ][ "allow_hero" ] = true;
			}
			
			combatEfficiencyEvent = tableLookupColumnForRow( scoreInfoTableID, row, SCOREINFOTABLE_INCLUDE_COMBAT_EFFICIENCY_EVENT );
			if( IsDefined( combatEfficiencyEvent ) && combatEfficiencyEvent != "" )
			{
				level.scoreInfo[ type ][ "combat_efficiency_event" ] = combatEfficiencyEvent;
			}
		}
	}
	
	game["ScoreInfoInitialized"] = true;
}


function getRankXPCapped( inRankXp )
{
	if ( ( isdefined( level.rankXpCap ) ) && level.rankXpCap && ( level.rankXpCap <= inRankXp ) )
	{
		return level.rankXpCap;
	}
	
	return inRankXp;
}

function getCodPointsCapped( inCodPoints )
{
	if ( ( isdefined( level.codPointsCap ) ) && level.codPointsCap && ( level.codPointsCap <= inCodPoints ) )
	{
		return level.codPointsCap;
	}
	
	return inCodPoints;
}

function registerScoreInfo( type, value, xp, label, teamscore_material )
{
	overrideDvar = "scr_" + level.gameType + "_score_" + type;	
	if ( GetDvarString( overrideDvar ) != "" )
	{
		value = getDvarInt( overrideDvar );
	}

	if( type == "kill" )
	{
		multiplier = GetGametypeSetting( "killEventScoreMultiplier" );
		level.scoreInfo[type]["value"] = value;
		if ( multiplier > 0 )
		{
			level.scoreInfo[type]["value"] = int((multiplier) * value);
		}
	}
	else
	{
		level.scoreInfo[type]["value"] = value;
	}

	level.scoreInfo[type]["xp"] = xp;
	
	if ( isdefined( label ) )
	{
		level.scoreInfo[type]["label"] = label;
	}

	if ( isdefined( teamscore_material ) )
	{
		level.scoreInfo[type]["team_icon"] = teamscore_material;
	}
}

function getScoreInfoValue( type )
{
	if ( isdefined( level.scoreInfo[type] ) )
	{
		n_score = level.scoreInfo[type]["value"];
		if ( isdefined( level.scoreModifierCallback ) && isdefined( n_score ) )
		{
			n_score = [[level.scoreModifierCallback]](type, n_score);
		}

		return n_score;
	}
}

function getScoreInfoXP( type )
{
	if ( isdefined( level.scoreInfo[type] ) )
	{
		n_xp = level.scoreInfo[type]["xp"];
		if ( isdefined( level.xpModifierCallback ) && isdefined( n_xp ) )
		{
			n_xp = [[level.xpModifierCallback]]( type, n_xp );
		}

		return n_xp;
	}
}

function shouldSkipMomentumDisplay( type )
{
	if( IS_TRUE(level.disableMomentum) )
		return true;
	
	// If teamscore UI has been overridden, and this has a teamscore icon, don't display it in the momentum indicator.
	//
	if (isdefined(level.teamScoreUICallback) && isdefined( level.scoreInfo[type]["team_icon"] ))
	{
		return true;
	}
	
	return false;
}

function getScoreInfoLabel( type )
{
	return ( level.scoreInfo[type]["label"] );
}

function getCombatEfficiencyEvent( type )
{
	return ( level.scoreInfo[type]["combat_efficiency_event"] );
}

function doesScoreInfoCountTowardRampage( type )
{
	return isdefined( level.scoreInfo[type]["rampage"] ) && level.scoreInfo[type]["rampage"];
}

function getRankInfoMinXP( rankId )
{
	return int(level.rankTable[rankId][2]);
}

function getRankInfoXPAmt( rankId )
{
	return int(level.rankTable[rankId][3]);
}

function getRankInfoMaxXp( rankId )
{
	return int(level.rankTable[rankId][7]);
}

function getRankInfoFull( rankId )
{
	return tableLookupIString( level.ranktable_name, 0, rankId, 16 );
}

function getRankInfoIcon( rankId, prestigeId )
{
	return tableLookup( level.rankicontable_name, 0, rankId, prestigeId+1 );
}

function getRankInfoLevel( rankId )
{
	return int( tableLookup( level.ranktable_name, 0, rankId, 13 ) );
}

function getRankInfoCodPointsEarned( rankId )
{
	return int( tableLookup( level.ranktable_name, 0, rankId, 17 ) );
}

function shouldKickByRank()
{
	if ( self IsHost() )
	{
		// don't try to kick the host
		return false;
	}
	
	if (level.rankCap > 0 && self.pers["rank"] > level.rankCap)
	{
		return true;
	}
	
	if ( ( level.rankCap > 0 ) && ( level.minPrestige == 0 ) && ( self.pers["plevel"] > 0 ) )
	{
		return true;
	}
	
	if ( level.minPrestige > self.pers["plevel"] )
	{
		return true;
	}
	
	return false;
}

function getCodPointsStat()
{
	codPoints = self GetDStat( "playerstatslist", "CODPOINTS", "StatValue" );
	codPointsCapped = getCodPointsCapped( codPoints );
	
	if ( codPoints > codPointsCapped )
	{
		self setCodPointsStat( codPointsCapped );
	}

	return codPointsCapped;
}

function setCodPointsStat( codPoints )
{
	self SetDStat( "PlayerStatsList", "CODPOINTS", "StatValue", getCodPointsCapped( codPoints ) );
}

function getRankXpStat()
{
	rankXp = self GetDStat( "playerstatslist", "RANKXP", "StatValue" );
	rankXpCapped = getRankXPCapped( rankXp );
	
	if ( rankXp > rankXpCapped )
	{
		self SetDStat( "playerstatslist", "RANKXP", "StatValue", rankXpCapped );
	}

	return rankXpCapped;
}

function getArenaPointsStat()
{
	arenaSlot = ArenaGetSlot();
	arenaPoints = self GetDStat( "arenaStats", arenaSlot, "points" );
	
	//Increment arena points by 1, because we immediatly deduct a point from the player to prevent
	//players leaving early without penalty.
	return arenaPoints + 1;
}

function on_player_connect()
{
	self.pers["rankxp"] = self getRankXpStat();
	self.pers["codpoints"] = self getCodPointsStat();
	self.pers["currencyspent"] = self GetDStat( "playerstatslist", "currencyspent", "StatValue" );
	rankId = self getRankForXp( self getRankXP() );
	self.pers["rank"] = rankId;
	self.pers["plevel"] = self GetDStat( "playerstatslist", "PLEVEL", "StatValue" );

	if ( self shouldKickByRank() )
	{
		kick( self getEntityNumber() );
		return;
	}
	
	DEFAULT( self.pers["participation"], 0 );

	self.rankUpdateTotal = 0;
	
	// attempt to move logic out of menus as much as possible
	self.cur_rankNum = rankId;
	assert( isdefined(self.cur_rankNum), "rank: "+ rankId + " does not have an index, check " + level.ranktable_name );
	
	prestige = self GetDStat( "playerstatslist", "plevel", "StatValue" );
	self setRank( rankId, prestige );
	self.pers["prestige"] = prestige;
	
	if ( ( SessionModeIsMultiplayerGame() && GameModeIsUsingStats() ) || ( SessionModeIsZombiesGame() && SessionModeIsOnlineGame() ) )
	{
		paragonRank = self GetDStat( "playerstatslist", "paragon_rank", "StatValue" );
		self setParagonRank( paragonRank );
		self.pers["paragonrank"] = paragonRank;
		
		paragonIconId = self GetDStat( "playerstatslist", "paragon_icon_id", "StatValue" );
		self setParagonIconId( paragonIconId );
		self.pers["paragoniconid"] = paragonIconId;
	}
	
	if ( !isdefined( self.pers["summary"] ) )
	{
		self.pers["summary"] = [];
		self.pers["summary"]["xp"] = 0;
		self.pers["summary"]["score"] = 0;
		self.pers["summary"]["challenge"] = 0;
		self.pers["summary"]["match"] = 0;
		self.pers["summary"]["misc"] = 0;
		self.pers["summary"]["codpoints"] = 0;
	}

	if( GameModeIsMode( GAMEMODE_LEAGUE_MATCH ) && !( self util::is_bot() ) )
	{
		arenaPoints = self getArenaPointsStat();
		arenaPoints = int( min( arenaPoints, 100 ) ); // JATODO: 100 = max arena points, temp until TU4

		self.pers["arenapoints"] = arenaPoints;
		self setArenaPoints( arenaPoints );
	}

	if ( level.rankedMatch )
	{
		self SetDStat( "playerstatslist", "rank", "StatValue", rankId );
		self SetDStat( "playerstatslist", "minxp", "StatValue", getRankInfoMinXp( rankId ) );
		self SetDStat( "playerstatslist", "maxxp", "StatValue", getRankInfoMaxXp( rankId ) );
		self SetDStat( "playerstatslist", "lastxp", "StatValue", getRankXPCapped( self.pers["rankxp"] ) );				
	}
	
	self.explosiveKills[0] = 0;
	
	callback::on_spawned( &on_player_spawned );
	callback::on_joined_team( &on_joined_team );
	callback::on_joined_spectate( &on_joined_spectators );
}

function on_joined_team()
{
	self endon("disconnect");

	self thread removeRankHUD();
}

function on_joined_spectators()
{
	self endon("disconnect");

	self thread removeRankHUD();
}

function on_player_spawned()
{
	self endon("disconnect");
		
	/*if ( !isdefined( self.hud_momentumupdate ) )
	{
		self.hud_momentumupdate = NewScoreHudElem(self);
		self.hud_momentumupdate.horzAlign = "center";
		self.hud_momentumupdate.vertAlign = "middle";
		self.hud_momentumupdate.alignX = "center";
		self.hud_momentumupdate.alignY = "middle";
 		self.hud_momentumupdate.x = 0;
		if( self IsSplitscreen() )
			self.hud_momentumupdate.y = -72;
		else
			self.hud_momentumupdate.y = -117;
		self.hud_momentumupdate.baseY = self.hud_momentumupdate.y;
		self.hud_momentumupdate.font = "default";
		self.hud_momentumupdate.fontscale = 1.5;
		self.hud_momentumupdate.archived = false;
		self.hud_momentumupdate.color = (1,1,0.5);
		self.hud_momentumupdate.alpha = 0;
		self.hud_momentumupdate.sort = 50;
	}*/
	
	if(!isdefined(self.hud_rankscroreupdate))
	{
		self.hud_rankscroreupdate = NewScoreHudElem(self);
		self.hud_rankscroreupdate.horzAlign = "center";
		self.hud_rankscroreupdate.vertAlign = "middle";
		self.hud_rankscroreupdate.alignX = "center";
		self.hud_rankscroreupdate.alignY = "middle";
 		self.hud_rankscroreupdate.x = 0;
		if( self IsSplitscreen() )
			self.hud_rankscroreupdate.y = -15;
		else
			self.hud_rankscroreupdate.y = -60;
		self.hud_rankscroreupdate.font = "default";
		self.hud_rankscroreupdate.fontscale = 2.0;
		self.hud_rankscroreupdate.archived = false;
		self.hud_rankscroreupdate.color = (1,1,0.5);
		self.hud_rankscroreupdate.alpha = 0;
		self.hud_rankscroreupdate.sort = 50;
		self.hud_rankscroreupdate hud::font_pulse_init();
	}
	
	/*if(!isdefined(self.hud_momentumreason))
	{
		self.hud_momentumreason = NewScoreHudElem(self);
		self.hud_momentumreason.horzAlign = "center";
		self.hud_momentumreason.vertAlign = "middle";
		self.hud_momentumreason.alignX = "center";
		self.hud_momentumreason.alignY = "middle";
 		self.hud_momentumreason.x = 0;
		if( self IsSplitscreen() )
			self.hud_momentumreason.y = -32;
		else
			self.hud_momentumreason.y = -77;
		self.hud_momentumreason.font = "default";
		self.hud_momentumreason.fontscale = 1.5;
		self.hud_momentumreason.archived = false;
		self.hud_momentumreason.color = (1,1,1);
		self.hud_momentumreason.alpha = 0;
		self.hud_momentumreason.sort = 50;
		self.hud_momentumreason hud::font_pulse_init();
		self.hud_momentumreason.maxFontScale = 6.3;
		self.hud_momentumreason.outFrames = self.hud_momentumreason.inFrames + self.hud_momentumreason.outFrames;
		self.hud_momentumreason.inFrames = 0;
	}*/
}

function incCodPoints( amount )
{
	if( !util::isRankEnabled() )
		return;

	if( !level.rankedMatch )
		return;

	newCodPoints = getCodPointsCapped( self.pers["codpoints"] + amount );
	if ( newCodPoints > self.pers["codpoints"] )
	{
		self.pers["summary"]["codpoints"] += ( newCodPoints - self.pers["codpoints"] );
	}
	self.pers["codpoints"] = newCodPoints;
	
	setCodPointsStat( int( newCodPoints ) );
}

function atLeastOnePlayerOnEachTeam( )
{
	foreach( team in level.teams )
	{
		if ( !level.playerCount[team] )
			return false;
	}
	return true; 
}

function giveRankXP( type, value, devAdd )
{
	self endon("disconnect");
	
	// TODO: will enable it after zombies ranking system is working
	if( SessionModeIsZombiesGame() )	
	{
		return;
	}

	if ( level.teamBased && (!atLeastOnePlayerOnEachTeam()) && !isdefined( devAdd ) )
		return;
	else if ( !level.teamBased && ( util::totalPlayerCount() < 2) && !isdefined( devAdd ) )
		return;

	if( !util::isRankEnabled() )
		return;		

	pixbeginevent("giveRankXP");		

	if ( !isdefined( value ) )
		value = getScoreInfoValue( type );
	
	// this switch statement should be inverted.  I am pretty sure there are fewer
	// things that we dont want to scale then there are that we do.	
	switch( type )
	{
		case "kill":
		case "headshot":
		case "assist":
		case "assist_25":
		case "assist_50":
		case "assist_75":
		case "helicopterassist":
		case "helicopterassist_25":
		case "helicopterassist_50":
		case "helicopterassist_75":
		case "helicopterkill":
		case "rcbombdestroy":
		case "spyplanekill":
		case "spyplaneassist":
		case "dogkill":
		case "dogassist":
		case "capture":
		case "defend":
		case "return":
		case "pickup":
		case "plant":
		case "defuse":
		case "destroyer":
		case "assault":
		case "assault_assist":
		case "revive":
		case "medal":
			value = int( value * level.xpScale );
			break;
		default:
			if ( level.xpScale == 0 )
				value = 0;
			break;
	}

	xpIncrease = self incRankXP( value );

	if ( level.rankedMatch )
	{
		self updateRank();
	}

	// Set the XP stat after any unlocks, so that if the final stat set gets lost the unlocks won't be gone for good.
	if ( value != 0 )
	{
		self syncXPStat();
	}

	if ( isdefined( self.enableText ) && self.enableText && !level.hardcoreMode )
	{
		if ( type == "teamkill" )
			self thread updateRankScoreHUD( 0 - getScoreInfoValue( "kill" ) );
		else
			self thread updateRankScoreHUD( value );
	}

	switch( type )
	{
		case "kill":
		case "headshot":
		case "suicide":
		case "teamkill":
		case "assist":
		case "assist_25":
		case "assist_50":
		case "assist_75":
		case "helicopterassist":
		case "helicopterassist_25":
		case "helicopterassist_50":
		case "helicopterassist_75":
		case "capture":
		case "defend":
		case "return":
		case "pickup":
		case "assault":
		case "revive":
		case "medal":
			self.pers["summary"]["score"] += value;
			incCodPoints( round_this_number( value * level.codPointsXPScale ) );
			break;

		case "win":
		case "loss":
		case "tie":
			self.pers["summary"]["match"] += value;
			incCodPoints( round_this_number( value * level.codPointsMatchScale ) );
			break;

		case "challenge":
			self.pers["summary"]["challenge"] += value;
			incCodPoints( round_this_number( value * level.codPointsChallengeScale ) );
			break;
			
		default:
			self.pers["summary"]["misc"] += value;	//keeps track of ungrouped match xp reward
			self.pers["summary"]["match"] += value;
			incCodPoints( round_this_number( value * level.codPointsMatchScale ) );
			break;
	}
	
	self.pers["summary"]["xp"] += xpIncrease;
	
	pixendevent();
}

function round_this_number( value )
{
	value = int( value + 0.5 );
	return value;
}

function updateRank()
{
	newRankId = self getRank();
	if ( newRankId == self.pers["rank"] )
		return false;

	oldRank = self.pers["rank"];
	rankId = self.pers["rank"];
	self.pers["rank"] = newRankId;

	// This function is a bit 'funny' - it decides to handle all of the unlocks for the current rank
	// before handling all of the unlocks for any new ranks - it's probably as a safety to handle the
	// case where unlocks have not happened for the current rank (which should only be the case for rank 0)
	// This will hopefully go away once the new ranking system is in place fully	
	while ( rankId <= newRankId )
	{	
		self SetDStat( "playerstatslist", "rank", "StatValue", rankId );
		self SetDStat( "playerstatslist", "minxp", "StatValue", int(level.rankTable[rankId][2]) );
		self SetDStat( "playerstatslist", "maxxp", "StatValue", int(level.rankTable[rankId][7]) );
	
		// tell lobby to popup promotion window instead
		self.setPromotion = true;
		if ( level.rankedMatch && level.gameEnded && !self IsSplitscreen() )
			self setDStat( "AfterActionReportStats", "lobbyPopup", "promotion" );
		
		// Don't add CoD Points for the old rank - only add when actually ranking up
		if ( rankId != oldRank )
		{
			codPointsEarnedForRank = getRankInfoCodPointsEarned( rankId );
			
			incCodPoints( codPointsEarnedForRank );
			
			
			if ( !isdefined( self.pers["rankcp"] ) )
			{
				self.pers["rankcp"] = 0;
			}
			
			self.pers["rankcp"] += codPointsEarnedForRank;
		}

		rankId++;
	}
	/#print( "promoted from " + oldRank + " to " + newRankId + " timeplayed: " + self GetDStat( "playerstatslist", "time_played_total", "StatValue" ) );	#/

	self setRank( newRankId );

	return true;
}


function CodeCallback_RankUp( rank, prestige, unlockTokensAdded )
{
	//No campaign notifications, handled in AAR
	if( SessionModeIsCampaignGame() )
	{
		// If extra tokens should be awarded at this player level, award them immediately.
		n_extra_tokens = level.rankTable[rank][18];
		
		if (isdefined(n_extra_tokens) && n_extra_tokens != "" )
		{
			self GiveUnlockToken(int(n_extra_tokens));
		}
		
		UploadStats( self );
		return;	
	}

	if( SessionModeIsMultiplayerGame()  )
	{
		if ( rank > 53 )
		{
			self GiveAchievement( "MP_REACH_ARENA" );// Reach Commander (Level 55) in Multiplayer by playing in Public Match and/or Arena.
		}
		if ( rank > 8 ) 
		{
			self GiveAchievement( "MP_REACH_SERGEANT" );// 	Welcome to the Club Reach Sergeant (Level 10) in Multiplayer by playing in Public Match and/or Arena.
		}
	}
		
	self LUINotifyEvent( &"rank_up", 3, rank, prestige, unlockTokensAdded );
	self LUINotifyEventToSpectators( &"rank_up", 3, rank, prestige, unlockTokensAdded );
	
	if ( isdefined( level.playPromotionReaction ) )
	{
		self thread [[level.playPromotionReaction]]();
	}
}

function getItemIndex( refString )
{
	statsTableName = util::getStatsTableName();
	itemIndex = int( tableLookup( statsTableName, 4, refString, 0 ) );
	assert( itemIndex > 0, "statsTable refstring " + refString + " has invalid index: " + itemIndex );
	
	return itemIndex;
}

function endGameUpdate()
{
	player = self;			
}

function updateRankScoreHUD( amount )
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );
	
	if ( isdefined( level.usingMomentum ) && level.usingMomentum )
	{
		return; // Disabled because this is now handled in updateMomentumHUD function
	}

	if ( amount == 0 )
		return;

	self notify( "update_score" );
	self endon( "update_score" );

	self.rankUpdateTotal += amount;

	WAIT_SERVER_FRAME;

	if( isdefined( self.hud_rankscroreupdate ) )
	{			
		if ( self.rankUpdateTotal < 0 )
		{
			self.hud_rankscroreupdate.label = &"";
			self.hud_rankscroreupdate.color = (0.73,0.19,0.19);
		}
		else
		{
			self.hud_rankscroreupdate.label = &"MP_PLUS";
			self.hud_rankscroreupdate.color = (1,1,0.5);
		}

		self.hud_rankscroreupdate setValue(self.rankUpdateTotal);

		self.hud_rankscroreupdate.alpha = 0.85;
		self.hud_rankscroreupdate thread hud::font_pulse( self );

		wait 1;
		self.hud_rankscroreupdate fadeOverTime( 0.75 );
		self.hud_rankscroreupdate.alpha = 0;
		
		self.rankUpdateTotal = 0;
	}
}

function updateMomentumHUD( amount, reason, reasonValue )
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );

	if ( amount == 0 )
		return;

	self notify( "update_score" );
	self endon( "update_score" );
	
	self.rankUpdateTotal += amount;

	if( isdefined( self.hud_rankscroreupdate ) )
	{			
		if ( self.rankUpdateTotal < 0 )
		{
			self.hud_rankscroreupdate.label = &"";
			self.hud_rankscroreupdate.color = (0.73,0.19,0.19);
		}
		else
		{
			self.hud_rankscroreupdate.label = &"MP_PLUS";
			self.hud_rankscroreupdate.color = (1,1,0.5);
		}

		self.hud_rankscroreupdate setValue( self.rankUpdateTotal );

		self.hud_rankscroreupdate.alpha = 0.85;
		self.hud_rankscroreupdate thread hud::font_pulse( self );
		
		/*if ( isdefined( self.hud_momentumupdate ) && ( amount != self.rankUpdateTotal ) )
		{
			self.hud_momentumupdate.label = &"MP_PLUS";
			self.hud_momentumupdate setValue( amount );
			self.hud_momentumupdate.alpha = 1;
			self.hud_momentumupdate.y = self.hud_momentumupdate.baseY;
			self.hud_momentumupdate FadeOverTime( 0.5 );
			self.hud_momentumupdate MoveOverTime( 0.5 );
			self.hud_momentumupdate.y -= 20;
			self.hud_momentumupdate.alpha = 0;
		}*/
		
		if ( isdefined( self.hud_momentumreason ) )
		{
			if ( isdefined( reason ) )
			{
				if ( isdefined( reasonValue ) )
				{
					self.hud_momentumreason.label = reason;
					self.hud_momentumreason setValue( reasonValue );
				}
				else
				{
					/*self.hud_momentumreason.label = &"";
					self.hud_momentumreason SetText( reason );*/
					self.hud_momentumreason.label = reason;
					self.hud_momentumreason setValue( amount );
				}
				self.hud_momentumreason.alpha = 0.85;
				self.hud_momentumreason thread hud::font_pulse( self );
			}
			else
			{
				self.hud_momentumreason fadeOverTime( 0.01 );
				self.hud_momentumreason.alpha = 0;
			}
		}

		wait 1;
		self.hud_rankscroreupdate fadeOverTime( 0.75 );
		self.hud_rankscroreupdate.alpha = 0;
		
		if ( isdefined( self.hud_momentumreason ) && isdefined( reason ) )
		{
			self.hud_momentumreason fadeOverTime( 0.75 );
			self.hud_momentumreason.alpha = 0;	
		}
		
		wait 0.75;
		
		self.rankUpdateTotal = 0;
	}
}

function removeRankHUD()
{
	if(isdefined(self.hud_rankscroreupdate))
		self.hud_rankscroreupdate.alpha = 0;
		
	if ( isdefined( self.hud_momentumreason ) )
	{
		self.hud_momentumreason.alpha = 0;
	}
}

function getRank()
{	
	rankXp = getRankXPCapped( self.pers["rankxp"] );
	rankId = self.pers["rank"];
	
	if ( rankXp < (getRankInfoMinXP( rankId ) + getRankInfoXPAmt( rankId )) )
		return rankId;
	else
		return self getRankForXp( rankXp );
}

function getRankForXp( xpVal )
{
	rankId = 0;
	rankName = level.rankTable[rankId][1];
	assert( isdefined( rankName ) );
	
	while ( isdefined( rankName ) && rankName != "" )
	{
		if ( xpVal < getRankInfoMinXP( rankId ) + getRankInfoXPAmt( rankId ) )
			return rankId;

		rankId++;
		if ( isdefined( level.rankTable[rankId] ) )
			rankName = level.rankTable[rankId][1];
		else
			rankName = undefined;
	}
	
	rankId--;
	return rankId;
}

function getSPM()
{
	rankLevel = self getRank() + 1;
	return (3 + (rankLevel * 0.5))*10;
}

function getRankXP()
{
	return getRankXPCapped( self.pers["rankxp"] );
}

function incRankXP( amount )
{
	if ( !level.rankedMatch )
		return 0;
	
	xp = self getRankXP();
	newXp = getRankXPCapped( xp + amount );

	if ( self.pers["rank"] == level.maxRank && newXp >= getRankInfoMaxXP( level.maxRank ) )
		newXp = getRankInfoMaxXP( level.maxRank );

	if ( self IsStarterPack() && self.pers["rank"] >= level.maxRankStarterPack && newXp >= getRankInfoMinXP( level.maxRankStarterPack ) )
		newXp = getRankInfoMinXP( level.maxRankStarterPack );
		
	xpIncrease = getRankXPCapped( newXp ) - self.pers["rankxp"];
	
	if ( xpIncrease < 0 )
	{
		xpIncrease = 0;
	}

	self.pers["rankxp"] = getRankXPCapped( newXp );
	
	return xpIncrease;
}

function syncXPStat()
{
	xp = getRankXPCapped( self getRankXP() );
	
	cp = getCodPointsCapped( int( self.pers["codpoints"] ) );
	
	self SetDStat( "playerstatslist", "rankxp", "StatValue", xp );
	
	self SetDStat( "playerstatslist", "codpoints", "StatValue", cp );
}
