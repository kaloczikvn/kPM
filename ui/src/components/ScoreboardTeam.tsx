import React from "react";
import { GameStates } from "../helpers/GameStates";
import { Player } from "../helpers/Player";
import { Teams } from "../helpers/Teams";
import ScoreboardPlayer from "./ScoreboardPlayer";

interface Props {
    team: Teams;
    score: number;
    players?: Player[];
    gameState: GameStates;
}

const ScoreboardTeam: React.FC<Props> = ({ team, score, players, gameState }) => {

    const getAlivePlayersCount = () => {
        if (players !== undefined && players.length > 0) {
            var alive = Object.values(players).filter(item => item.isDead === false);
            return alive.length;
        } else {
            return 0;
        }
    }

    return (
        <>
            <div className={"team " + ((team === Teams.Attackers) ? 'attackers' : 'defenders') + ' gameState' + gameState.toString()} >
                <div className="headerBar">
                    <div className="teamName">
                        {(team === Teams.Attackers) ? 'Attackers' : 'Defenders'}
                        <span className="alive">{getAlivePlayersCount()} alive</span>
                    </div>
                    <div className="point">{score??0}</div>
                </div>
                <div className="playersHolderHeader">
                    <div className="playerPing">Ping</div>

                    {(gameState === GameStates.Warmup) &&
                        <div className="playerReady">Ready</div>
                    }

                    <div className="playerName">Name</div>
                    <div className="playerKill">Kill</div>
                    <div className="playerDeath">Death</div>
                </div>
                <div className="playersHolder">
                    <div className="playersHolderInner">
                        {(players !== undefined && players.length > 0)
                        ?
                            players.map((player: Player, key: number) => (
                                <ScoreboardPlayer player={player} key={key} gameState={gameState} />
                            ))
                        :
                            <div className="noPlayers">No players...</div>
                        }
                    </div>
                </div>
            </div>
        </>
    );
};

export default ScoreboardTeam;
