#using scripts\codescripts\struct;

#using scripts\shared\hud_util_shared;
#using scripts\shared\music_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;

#using scripts\shared\hud_message_shared;
#using scripts\shared\system_shared;

#using scripts\mp\gametypes\_globallogic_audio;

#using scripts\mp\_util;

#precache( "string", "MP_FIRSTPLACE_NAME" );
#precache( "string", "MP_SECONDPLACE_NAME" );
#precache( "string", "MP_THIRDPLACE_NAME" );
#precache( "string", "MP_WAGER_PLACE_NAME" );
#precache( "string", "MP_MATCH_BONUS_IS" );
#precache( "string", "MP_CODPOINTS_MATCH_BONUS_IS" );
#precache( "string", "MP_WAGER_WINNINGS_ARE" );
#precache( "string", "MP_WAGER_SIDEBET_WINNINGS_ARE" );
#precache( "string", "MP_WAGER_IN_THE_MONEY" );
#precache( "string", "MP_DRAW_CAPS" );
#precache( "string", "MP_ROUND_DRAW_CAPS" );
#precache( "string", "MP_ROUND_WIN_CAPS" );
#precache( "string", "MP_ROUND_LOSS_CAPS" );
#precache( "string", "MP_VICTORY_CAPS" );
#precache( "string", "MP_DEFEAT_CAPS" );
#precache( "string", "MP_TOP3_CAPS" );
#precache( "string", "MP_GAME_OVER_CAPS" );
#precache( "string", "MP_HALFTIME_CAPS" );
#precache( "string", "MP_OVERTIME_CAPS" );
#precache( "string", "MP_ROUNDEND_CAPS" );
#precache( "string", "MP_INTERMISSION_CAPS" );
#precache( "string", "MP_SWITCHING_SIDES_CAPS" );
#precache( "string", "MP_MATCH_BONUS_IS" );
#precache( "string", "MP_CODPOINTS_MATCH_BONUS_IS" );
#precache( "string", "MP_WAGER_WINNINGS_ARE" );
#precache( "string", "MP_WAGER_SIDEBET_WINNINGS_ARE" );
#precache( "string", "MP_WAGER_IN_THE_MONEY_CAPS" );
#precache( "string", "MP_WAGER_LOSS_CAPS" );
#precache( "string", "MP_WAGER_TOPWINNERS" );
#precache( "string", "MP_JOIN_IN_PROGRESS_LOSS" );
#precache( "string", "MP_WINS" );
#precache( "string", "MP_TEAM_ELIMINATED" );

#precache( "eventstring", "show_outcome" );

#namespace hud_message;

function init()
{
	game["strings"]["draw"] = &"MP_DRAW_CAPS";
	game["strings"]["round_draw"] = &"MP_ROUND_DRAW_CAPS";
	game["strings"]["round_win"] = &"MP_ROUND_WIN_CAPS";
	game["strings"]["round_loss"] = &"MP_ROUND_LOSS_CAPS";
	game["strings"]["victory"] = &"MP_VICTORY_CAPS";
	game["strings"]["defeat"] = &"MP_DEFEAT_CAPS";
	game["strings"]["top3"] = &"MP_TOP3_CAPS";
	game["strings"]["game_over"] = &"MP_GAME_OVER_CAPS";
	game["strings"]["halftime"] = &"MP_HALFTIME_CAPS";
	game["strings"]["overtime"] = &"MP_OVERTIME_CAPS";
	game["strings"]["roundend"] = &"MP_ROUNDEND_CAPS";
	game["strings"]["intermission"] = &"MP_INTERMISSION_CAPS";
	game["strings"]["side_switch"] = &"MP_SWITCHING_SIDES_CAPS";
	game["strings"]["match_bonus"] = &"MP_MATCH_BONUS_IS";
	game["strings"]["codpoints_match_bonus"] = &"MP_CODPOINTS_MATCH_BONUS_IS";
	game["strings"]["wager_winnings"] = &"MP_WAGER_WINNINGS_ARE";
	game["strings"]["wager_sidebet_winnings"] = &"MP_WAGER_SIDEBET_WINNINGS_ARE";
	game["strings"]["wager_inthemoney"] = &"MP_WAGER_IN_THE_MONEY_CAPS";
	game["strings"]["wager_loss"] = &"MP_WAGER_LOSS_CAPS";
	game["strings"]["wager_topwinners"] = &"MP_WAGER_TOPWINNERS";
	game["strings"]["join_in_progress_loss"] = &"MP_JOIN_IN_PROGRESS_LOSS";
	game["strings"]["cod_caster_team_wins"] = &"MP_WINS";
	game["strings"]["cod_caster_team_eliminated"] = &"MP_TEAM_ELIMINATED";
}

function teamOutcomeNotify( winner, endType, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );
	
	team = self.pers["team"];
	
	if ( team != "spectator" && ( !isdefined( team ) || !isdefined( level.teams[team] ) ) )
		team = "allies";

	// wait for notifies to finish
	while ( self.doingNotify )
		WAIT_SERVER_FRAME;

	self endon ( "reset_outcome" );
	
	outcomeText = "";
	notifyRoundEndToUI = undefined;

	overrideSpectator = false;
	
	if ( endType == "halftime" )
	{
		outcomeText = game["strings"]["halftime"];
		notifyRoundEndToUI = true;
	}
	else if ( endType == "intermission" )
	{
		outcomeText = game["strings"]["intermission"];
		notifyRoundEndToUI = true;
	}
	else if ( endType == "overtime" )
	{
		outcomeText = game["strings"]["overtime"];
		notifyRoundEndToUI = true;
	}
	else if ( endType == "roundend" )
	{
		if ( winner == "tie" )
		{
			outcomeText = game["strings"]["round_draw"];
		}
		else if ( isdefined( self.pers["team"] ) && winner == team )
		{
			outcomeText = game["strings"]["round_win"];
			overrideSpectator = true;
		}
		else
		{
			outcomeText = game["strings"]["round_loss"];
			
			if ( isdefined( level.endDefeatReasonText ) )
			{
				endReasonText = level.endDefeatReasonText;
			}

			overrideSpectator = true;
		}
		notifyRoundEndToUI = true;
	}
	else if ( endType == "gameend" )
	{
		if ( winner == "tie" )
		{
			outcomeText = game["strings"]["draw"];
		}
		else if ( isdefined( self.pers["team"] ) && winner == team )
		{
			outcomeText = game["strings"]["victory"];
			overrideSpectator = true;
		}
		else
		{
			outcomeText = game["strings"]["defeat"];
			
			if ( isdefined( level.endDefeatReasonText ) )
			{
				endReasonText = level.endDefeatReasonText;
			}
			
			if ( (level.rankedMatch || level.leagueMatch ) && ( self.pers["lateJoin"] === true ) )
			{
			   endReasonText = game["strings"]["join_in_progress_loss"];	
			}
			
			overrideSpectator = true;
			
		}
		notifyRoundEndToUI = false;
	}
	
	matchBonus = 0;
	if ( isdefined( self.pers["totalMatchBonus"] ) )
	{
		bonus = Ceil( self.pers["totalMatchBonus"] * level.xpScale );

		if ( bonus > 0 )
		{
			matchBonus = bonus;
		}
	}

	winnerEnum = 0;

	if ( winner == "allies" ) 
	{
		winnerEnum = TEAM_ALLIES;
	}
	else if ( winner == "axis" )
	{
		winnerEnum = TEAM_AXIS;
	}

	if( ( ( level.gameType == "ctf" ) || ( level.gameType == "escort" ) || ( level.gameType == "ball" ) ) && isdefined( game["overtime_round"] ) )
	{
		if( game["overtime_round"] == 1 )
		{
			if( isdefined( game[level.gameType + "_overtime_first_winner"]) )
			{
				winner = game[level.gameType + "_overtime_first_winner"];
			}

			if( isdefined( winner ) && ( winner != "tie" ) )
			{
				winningTime = game[level.gameType + "_overtime_time_to_beat"];
			}
		}
		else
		{
			if( isdefined(game[level.gameType + "_overtime_first_winner"]) && game[level.gameType + "_overtime_first_winner"] == "tie" )
			{
				winningTime = game[level.gameType + "_overtime_best_time"];
			}
			else
			{
				winningTime = undefined;
				
				if ( winner == "tie" && isdefined(game[level.gameType + "_overtime_first_winner"]) )
				{
					if ( game[level.gameType + "_overtime_first_winner"] == "allies" ) 
					{
						winnerEnum = TEAM_ALLIES;
					}
					else if ( game[level.gameType + "_overtime_first_winner"] == "axis" )
					{
						winnerEnum = TEAM_AXIS;
					}
				}
				
				if ( isdefined(game[level.gameType + "_overtime_time_to_beat"]) )
				{
					winningTime = game[level.gameType + "_overtime_time_to_beat"];
				}
					
				if( isdefined( game[level.gameType + "_overtime_best_time"] ) && ( !isDefined( winningTime ) || (winningTime > game[level.gameType + "_overtime_best_time"]) ) )
				{
					if( game[level.gameType + "_overtime_first_winner"] !== winner )
					{
						losingTime = winningTime;
					}

					winningTime = game[level.gameType + "_overtime_best_time"];

					if( winner === "tie" )
					{
						winningTime = 0;
					}
				}
			}
			
			if( ( level.gameType == "escort" ) && ( winner === "tie" ) )
			{
				winnerEnum = 0;
				if( !IS_TRUE( level.finalGameEnd ) )
				{
					if( game["defenders"] == team )
						outcomeText = game["strings"]["round_win"];
					else
						outcomeText = game["strings"]["round_loss"];
				}
			}
		}
		DEFAULT( winningTime, 0 );
		DEFAULT( losingTime, 0 );
		
		if( ( winningTime == 0 ) && ( losingTime == 0  ) )
			winnerEnum = 0;
		
		if ( team == "spectator" && overrideSpectator )
		{
			outcomeText = game["strings"]["cod_caster_team_wins"];
			notifyRoundEndToUI = false;
		}
		
		self LUINotifyEvent( &"show_outcome", 7, outcomeText, endReasonText, int( matchBonus ), winnerEnum, notifyRoundEndToUI, int( winningTime / 1000 ), int( losingTime  / 1000 ) );
	}
	else if( level.gameType == "ball" &&
	         isdefined( winner ) && ( winner != "tie" ) &&
	         game["roundsplayed"]  < level.roundLimit && 
	         isdefined( game["round_time_to_beat"] ) &&
	         !isdefined( game["overtime_round"] ) )
	{
		winningTime = game["round_time_to_beat"];
		
		DEFAULT( losingTime, 0 );
		
		switch( winner )
		{
			case "allies":
				winnerEnum = TEAM_ALLIES;
				break;
			case "axis":
				winnerEnum = TEAM_AXIS;
				break;
			default:
				winnerEnum = 0;
		}
		
		if ( team == "spectator" && overrideSpectator )
		{
			outcomeText = game["strings"]["cod_caster_team_wins"];
			notifyRoundEndToUI = false;
		}
	
		self LUINotifyEvent( &"show_outcome", 7, outcomeText, endReasonText, int( matchBonus ), winnerEnum, notifyRoundEndToUI, int( winningTime / 1000 ), int( losingTime  / 1000 ) );
	}
	else
	{
		// Codcaster Specific Outcome Override
		if ( team == "spectator" && overrideSpectator )
		{
			// Special case handling of end reason text
			foreach( team in level.teams )
			{
				if ( endreasontext == game["strings"][team + "_eliminated"] )
				{
					endReasonText = game["strings"]["cod_caster_team_eliminated"];
					break;
				}
			}
		
			outcomeText = game["strings"]["cod_caster_team_wins"];
			notifyRoundEndToUI = false;
		}
			
		self LUINotifyEvent( &"show_outcome", 5, outcomeText, endReasonText, int( matchBonus ), winnerEnum, notifyRoundEndToUI );
	}
}

function teamOutcomeNotifyZombie( winner, isRound, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	team = self.pers["team"];
	if ( isdefined( team ) && team == "spectator" )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( self.currentspectatingclient == level.players[i].clientId )
			{
				team = 	level.players[i].pers["team"];
				break;
			}
		}
	}
	
	if ( !isdefined( team ) || !isdefined( level.teams[team] ) )
		team = "allies";

	// wait for notifies to finish
	while ( self.doingNotify )
		WAIT_SERVER_FRAME;

	self endon ( "reset_outcome" );


	if ( level.splitscreen )
	{
		titleSize = 2.0;
		spacing = 10;
		font = "default";
	}
	else
	{
		titleSize = 3.0;
		spacing = 50;
		font = "objective";
	}

	const duration = 60000;

	outcomeTitle = hud::createFontString( font, titleSize );
	outcomeTitle hud::setPoint( "TOP", undefined, 0, spacing );
	outcomeTitle.glowAlpha = 1;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;
	outcomeTitle.immunetodemogamehudsettings = true;
	outcomeTitle.immunetodemofreecamera = true;

	outcomeTitle setText( endReasonText );
	outcomeTitle setPulseFX( 100, duration, 1000 );
	
	self thread resetOutcomeNotify( undefined, undefined, outcomeTitle );
}

function outcomeNotify( winner, isRoundEnd, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	// wait for notifies to finish
	while ( self.doingNotify )
		WAIT_SERVER_FRAME;

	self endon ( "reset_outcome" );

	outcomeText = "";
	players = level.placement["all"];
	numClients = players.size;

	overrideSpectator = false;
		
	if ( !util::isOneRound() && !isRoundEnd )
	{
		outcomeText = game["strings"]["game_over"];
	}
	else if ( players[0].pointstowin == 0 )
	{
		outcomeText = game["strings"]["tie"];
	}
	else if ( self isInTop( players, 1 ) )
	{
		outcomeText = game["strings"]["victory"];
		overrideSpectator = true;
	}
	else if ( self isInTop( players, 3 ) )
	{
		outcomeText = game["strings"]["top3"];
	}
	else
	{
		outcomeText = game["strings"]["defeat"];
		overrideSpectator = true;
	}

	matchBonus = 0;
	
	if ( isdefined( self.pers["totalMatchBonus"] ) )
	{
		matchBonus = self.pers["totalMatchBonus"];
	}
	
	wait( 2 );

	team = self.pers["team"];
	if( isdefined( team ) && team == "spectator" && overrideSpectator )
	{
		outcomeText = game["strings"]["cod_caster_team_wins"];
		self LUINotifyEvent( &"show_outcome", 5, outcomeText, endReasonText, matchBonus, winner, false );
	}
	else
	{
		self LUINotifyEvent( &"show_outcome", 4, outcomeText, endReasonText, matchBonus, numClients );
	}
	
}

function wagerOutcomeNotify( winner, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	// wait for notifies to finish
	while ( self.doingNotify )
		WAIT_SERVER_FRAME;
		
	self endon ( "reset_outcome" );

	headerFont = "extrabig";
	font = "objective";
	if ( self IsSplitscreen() )
	{
		titleSize = 2.0;
		winnerSize = 1.5;
		otherSize = 1.5;
		iconSize = 30;
		spacing = 2;
	}
	else
	{
		titleSize = 3.0;
		winnerSize = 2.0;
		otherSize = 1.5;
		iconSize = 30;
		spacing = 20;
	}
	
	halftime = false;
	if ( isdefined( level.sidebet ) && level.sidebet )
		halftime = true;

	duration = 60000;

	players = level.placement["all"];
		
	outcomeTitle = hud::createFontString( headerFont, titleSize );
	outcomeTitle hud::setPoint( "TOP", undefined, 0, spacing );
	if( halftime )
	{
		outcomeTitle setText( game["strings"]["intermission"] );
		outcomeTitle.color = (1.0, 1.0, 0.0);
		outcomeTitle.glowColor = (1.0, 0.0, 0.0);
	}
	else if( isdefined(level.dontCalcWagerWinnings) && level.dontCalcWagerWinnings == true )
	{
		outcomeTitle setText( game["strings"]["wager_topwinners"] );
		outcomeTitle.color = (0.42, 0.68, 0.46);
	}
	else
	{
		if ( isdefined( self.wagerWinnings ) && ( self.wagerWinnings > 0 ) )
		{
			outcomeTitle setText( game["strings"]["wager_inthemoney"] );
			outcomeTitle.color = (0.42, 0.68, 0.46);
		}
		else
		{
			outcomeTitle setText( game["strings"]["wager_loss"] );
			outcomeTitle.color = (0.73, 0.29, 0.19);
		}
	}
	outcomeTitle.glowAlpha = 1;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;
	outcomeTitle.immunetodemogamehudsettings = true;
	outcomeTitle.immunetodemofreecamera = true;
	outcomeTitle setCOD7DecodeFX( 200, duration, 600 );

	outcomeText = hud::createFontString( font, 2.0 );
	outcomeText hud::setParent( outcomeTitle );
	outcomeText hud::setPoint( "TOP", "BOTTOM", 0, 0 );
	outcomeText.glowAlpha = 1;
	outcomeText.hideWhenInMenu = false;
	outcomeText.archived = false;
	outcomeText.immunetodemogamehudsettings = true;
	outcomeText.immunetodemofreecamera = true;
	outcomeText setText( endReasonText );

	playerNameHudElems = [];
	playerCPHudElems = [];
	numPlayers = players.size;
	for ( i = 0 ; i < numPlayers ; i++ )
	{
		if ( !halftime && isdefined( players[i] ) )
		{
			secondTitle = hud::createFontString( font, otherSize );
			if ( playerNameHudElems.size == 0 )
			{
				secondTitle hud::setParent( outcomeText );
				secondTitle hud::setPoint( "TOP_LEFT", "BOTTOM", -175, spacing*3 );
			}
			else
			{
				secondTitle hud::setParent( playerNameHudElems[playerNameHudElems.size-1] );
				secondTitle hud::setPoint( "TOP_LEFT", "BOTTOM_LEFT", 0, spacing );
			}
			//secondTitle.glowColor = (0.2, 0.3, 0.7);
			secondTitle.glowAlpha = 1;
			secondTitle.hideWhenInMenu = false;
			secondTitle.archived = false;
			secondTitle.immunetodemogamehudsettings = true;
			secondTitle.immunetodemofreecamera = true;
			secondTitle.label = &"MP_WAGER_PLACE_NAME";
			secondTitle.playerNum = i;
			secondTitle setPlayerNameString( players[i] );
			playerNameHudElems[playerNameHudElems.size] = secondTitle;
		
			secondCP = hud::createFontString( font, otherSize );
			secondCP hud::setParent( secondTitle );
			secondCP hud::setPoint( "TOP_RIGHT", "TOP_LEFT", 350, 0 );
			secondCP.glowAlpha = 1;
			secondCP.hideWhenInMenu = false;
			secondCP.archived = false;
			secondCP.immunetodemogamehudsettings = true;
			secondCP.immunetodemofreecamera = true;
			secondCP.label = &"MENU_POINTS";
			secondCP.currentValue = 0;
			if ( isdefined( players[i].wagerWinnings ) )
				secondCP.targetValue = players[i].wagerWinnings;
			else
				secondCP.targetValue = 0;
			if ( secondCP.targetValue > 0 )
				secondCP.color = (0.42, 0.68, 0.46);
			secondCP setValue( 0 );
			playerCPHudElems[playerCPHudElems.size] = secondCP;
		}
	}
	
	self thread updateWagerOutcome( playerNameHudElems, playerCPHudElems );
	self thread resetWagerOutcomeNotify( playerNameHudElems, playerCPHudElems, outcomeTitle, outcomeText );
	
	if ( halftime )
		return;
	
	stillUpdating = true;
	countUpDuration = 2;
	CPIncrement = 9999;
	if ( isdefined( playerCPHudElems[0] ) )
	{
		CPIncrement = int( playerCPHudElems[0].targetValue / ( countUpDuration / 0.05 ) );
		if ( CPIncrement < 1 )
			CPIncrement = 1;
	}
	while( stillUpdating )
	{
		stillUpdating = false;
		for ( i = 0 ; i < playerCPHudElems.size ; i++ )
		{				
			if ( isdefined( playerCPHudElems[i] ) && ( playerCPHudElems[i].currentValue < playerCPHudElems[i].targetValue ) )
			{
				playerCPHudElems[i].currentValue += CPIncrement;
				if ( playerCPHudElems[i].currentValue > playerCPHudElems[i].targetValue )
					playerCPHudElems[i].currentValue = playerCPHudElems[i].targetValue;
				playerCPHudElems[i] SetValue( playerCPHudElems[i].currentValue );
				stillUpdating = true;
			}
		}
		WAIT_SERVER_FRAME;
	}
}

function teamWagerOutcomeNotify( winner, isRoundEnd, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	team = self.pers["team"];
	if ( !isdefined( team ) || (!isdefined( level.teams[team] ) ) )
		team = "allies";

	WAIT_SERVER_FRAME;

	// wait for notifies to finish
	while ( self.doingNotify )
		WAIT_SERVER_FRAME;

	self endon ( "reset_outcome" );
	
	headerFont = "extrabig";
	font = "objective";
	if ( self IsSplitscreen() )
	{
		titleSize = 2.0;
		textSize = 1.5;
		iconSize = 30;
		spacing = 10;
	}
	else
	{
		titleSize = 3.0;
		textSize = 2.0;
		iconSize = 70;
		spacing = 15;
	}

	halftime = false;
	if ( isdefined( level.sidebet ) && level.sidebet )
		halftime = true;

	duration = 60000;

	outcomeTitle = hud::createFontString( headerFont, titleSize );
	outcomeTitle hud::setPoint( "TOP", undefined, 0, spacing );
	outcomeTitle.glowAlpha = 1;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;
	outcomeTitle.immunetodemogamehudsettings = true;
	outcomeTitle.immunetodemofreecamera = true;
	
	outcomeText = hud::createFontString( font, 2.0 );
	outcomeText hud::setParent( outcomeTitle );
	outcomeText hud::setPoint( "TOP", "BOTTOM", 0, 0 );
	outcomeText.glowAlpha = 1;
	outcomeText.hideWhenInMenu = false;
	outcomeText.archived = false;
	outcomeText.immunetodemogamehudsettings = true;
	outcomeText.immunetodemofreecamera = true;
	
	if ( winner == "tie" )
	{
		if ( isRoundEnd )
			outcomeTitle setText( game["strings"]["round_draw"] );
		else
			outcomeTitle setText( game["strings"]["draw"] );
		outcomeTitle.color = (1, 1, 1);
		
		winner = "allies";
	}
	else if ( winner == "overtime" )
	{
		outcomeTitle setText( game["strings"]["overtime"] );
		outcomeTitle.color = (1, 1, 1);

	}
	else if ( isdefined( self.pers["team"] ) && winner == team )
	{
		if ( isRoundEnd )
			outcomeTitle setText( game["strings"]["round_win"] );
		else
			outcomeTitle setText( game["strings"]["victory"] );
		outcomeTitle.color = (0.42, 0.68, 0.46);
	}
	else
	{
		if ( isRoundEnd )
			outcomeTitle setText( game["strings"]["round_loss"] );
		else
			outcomeTitle setText( game["strings"]["defeat"] );
		outcomeTitle.color = (0.73, 0.29, 0.19);
	}
	if( !isdefined( level.dontShowEndReason ) || !level.dontShowEndReason )
	{
		outcomeText setText( endReasonText );
	}
	
	outcomeTitle setPulseFX( 100, duration, 1000 );
	outcomeText setPulseFX( 100, duration, 1000 );

	teamIcons = [];
	teamIcons[team] = hud::createIcon( game["icons"][team], iconSize, iconSize );
	teamIcons[team] hud::setParent( outcomeText );
	teamIcons[team] hud::setPoint( "TOP", "BOTTOM", -60, spacing );
	teamIcons[team].hideWhenInMenu = false;
	teamIcons[team].archived = false;
	teamIcons[team].alpha = 0;
	teamIcons[team] fadeOverTime( 0.5 );
	teamIcons[team].alpha = 1;
	teamIcons[team].immunetodemogamehudsettings = true;
	teamIcons[team].immunetodemofreecamera = true;
	
	foreach( enemyTeam in level.teams )
	{
		if ( team == enemyTeam )
			continue;
			
		teamIcons[enemyTeam] = hud::createIcon( game["icons"][enemyTeam], iconSize, iconSize );
		teamIcons[enemyTeam] hud::setParent( outcomeText );
		teamIcons[enemyTeam] hud::setPoint( "TOP", "BOTTOM", 60, spacing );
		teamIcons[enemyTeam].hideWhenInMenu = false;
		teamIcons[enemyTeam].archived = false;
		teamIcons[enemyTeam].alpha = 0;
		teamIcons[enemyTeam] fadeOverTime( 0.5 );
		teamIcons[enemyTeam].alpha = 1;
		teamIcons[enemyTeam].immunetodemogamehudsettings = true;
		teamIcons[enemyTeam].immunetodemofreecamera = true;
	}

	teamScores = [];
	teamScores[team] = hud::createFontString( font, titleSize );
	teamScores[team] hud::setParent( teamIcons[team] );
	teamScores[team] hud::setPoint( "TOP", "BOTTOM", 0, spacing );
	teamScores[team].glowAlpha = 1;
	teamScores[team] setValue( getTeamScore( team ) );
	teamScores[team].hideWhenInMenu = false;
	teamScores[team].archived = false;
	teamScores[team].immunetodemogamehudsettings = true;
	teamScores[team].immunetodemofreecamera = true;
	teamScores[team] setPulseFX( 100, duration, 1000 );

	foreach( enemyTeam in level.teams )
	{
		if ( team == enemyTeam )
			continue;
			
		teamScores[enemyTeam] = hud::createFontString( font, titleSize );
		teamScores[enemyTeam] hud::setParent( teamIcons[enemyTeam] );
		teamScores[enemyTeam] hud::setPoint( "TOP", "BOTTOM", 0, spacing );
		teamScores[enemyTeam].glowAlpha = 1;
		teamScores[enemyTeam] setValue( getTeamScore( enemyTeam ) );
		teamScores[enemyTeam].hideWhenInMenu = false;
		teamScores[enemyTeam].archived = false;
		teamScores[enemyTeam].immunetodemogamehudsettings = true;
		teamScores[enemyTeam].immunetodemofreecamera = true;
		teamScores[enemyTeam] setPulseFX( 100, duration, 1000 );
	}

	matchBonus = undefined;
	sidebetWinnings = undefined;
	if ( !isRoundEnd && !halftime && isdefined( self.wagerWinnings ) )
	{
		matchBonus = hud::createFontString( font, 2.0 );
		matchBonus hud::setParent( outcomeText );
		matchBonus hud::setPoint( "TOP", "BOTTOM", 0, iconSize + (spacing * 3) + teamScores[team].height );
		matchBonus.glowAlpha = 1;
		matchBonus.hideWhenInMenu = false;
		matchBonus.archived = false;
		matchBonus.immunetodemogamehudsettings = true;
		matchBonus.immunetodemofreecamera = true;
		matchBonus.label = game["strings"]["wager_winnings"];
		matchBonus setValue( self.wagerWinnings );

		if ( isdefined( game["side_bets"] ) && game["side_bets"] )
		{
			sidebetWinnings = hud::createFontString( font, 2.0 );
			sidebetWinnings hud::setParent( matchBonus );
			sidebetWinnings hud::setPoint( "TOP", "BOTTOM", 0, spacing );
			sidebetWinnings.glowAlpha = 1;
			sidebetWinnings.hideWhenInMenu = false;
			sidebetWinnings.archived = false;
			sidebetWinnings.immunetodemogamehudsettings = true;
			sidebetWinnings.immunetodemofreecamera = true;
			sidebetWinnings.label = game["strings"]["wager_sidebet_winnings"];
			sidebetWinnings setValue( self.pers["wager_sideBetWinnings"] );
		}
	}
	self thread resetOutcomeNotify( teamIcons, teamScores, outcomeTitle, outcomeText, matchBonus, sidebetWinnings );
}

function resetOutcomeNotify( hudElemList1, hudElemList2, hudElem3, hudElem4, hudElem5, hudElem6, hudElem7, hudElem8, hudElem9, hudElem10 )
{
	self endon ( "disconnect" );
	self waittill ( "reset_outcome" );
	
	destroyHudElem( hudElem3 );
	destroyHudElem( hudElem4 );
	destroyHudElem( hudElem5 );
	destroyHudElem( hudElem6 );
	destroyHudElem( hudElem7 );
	destroyHudElem( hudElem8 );
	destroyHudElem( hudElem9 );
	destroyHudElem( hudElem10 );
	
	if ( isdefined( hudElemList1 ) )
	{
		foreach( elem in hudElemList1 )
		{
			destroyHudElem( elem );
		}
	}
	
	if ( isdefined( hudElemList2 ) )
	{
		foreach( elem in hudElemList2 )
		{
			destroyHudElem( elem );
		}
	}
}

function resetWagerOutcomeNotify( playerNameHudElems, playerCPHudElems, outcomeTitle, outcomeText )
{
	self endon( "disconnect" );
	self waittill( "reset_outcome" );
	
	for ( i = playerNameHudElems.size - 1 ; i >= 0 ; i-- )
	{
		if ( isdefined( playerNameHudElems[i] ) )
			playerNameHudElems[i] destroy();
	}
		
	for ( i = playerCPHudElems.size - 1 ; i >= 0 ; i-- )
	{
		if ( isdefined( playerCPHudElems[i] ) )
			playerCPHudElems[i] destroy();
	}
	
	if ( isdefined( outcomeText ) )
		outcomeText destroy();
	
	if ( isdefined( outcomeTitle ) )
		outcomeTitle destroy();
}

function updateOutcome( firstTitle, secondTitle, thirdTitle )
{
	self endon( "disconnect" );
	self endon( "reset_outcome" );
	
	while( true )
	{
		self waittill( "update_outcome" );

		players = level.placement["all"];

		if ( isdefined( firstTitle ) && isdefined( players[0] ) )
			firstTitle setPlayerNameString( players[0] );
		else if ( isdefined( firstTitle ) )
			firstTitle.alpha = 0;
		
		if ( isdefined( secondTitle ) && isdefined( players[1] ) )
			secondTitle setPlayerNameString( players[1] );
		else if ( isdefined( secondTitle ) )
			secondTitle.alpha = 0;
		
		if ( isdefined( thirdTitle ) && isdefined( players[2] ) )
			thirdTitle setPlayerNameString( players[2] );
		else if ( isdefined( thirdTitle ) )
			thirdTitle.alpha = 0;
	}	
}

function updateWagerOutcome( playerNameHudElems, playerCPHudElems )
{
	self endon( "disconnect" );
	self endon( "reset_outcome" );
	
	while ( true )
	{
		self waittill( "update_outcome" );
		
		players = level.placement["all"];
		
		for ( i = 0 ; i < playerNameHudElems.size ; i++ )
		{
			if ( isdefined( playerNameHudElems[i] ) && isdefined( players[playerNameHudElems[i].playerNum] ) )
				playerNameHudElems[i] SetPlayerNameString( players[playerNameHudElems[i].playerNum] );
			else
			{
				if ( isdefined( playerNameHudElems[i] ) )
					playerNameHudElems[i].alpha = 0;
				if ( isdefined( playerCPHudElems[i] ) )
					playerCPHudElems[i].alpha = 0;
			}
		}
	}
}
