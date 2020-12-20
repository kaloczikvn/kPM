import React from "react";
import ScoreboardTeam from "./components/ScoreboardTeam";
import { GameStates } from "./helpers/GameStates";
import { Players } from "./helpers/Player";
import { Teams } from "./helpers/Teams";

import './Scoreboard.scss';

interface Props {
    showScoreboard: boolean;
    teamAttackersScore: number;
    teamDefendersScore: number;
    players: Players;
    gameState: GameStates;
    round: number;
    maxRounds: number;
}

const Scoreboard: React.FC<Props> = ({ showScoreboard, teamAttackersScore, teamDefendersScore, players, gameState, round, maxRounds }) => {
    return (
        <>
            {showScoreboard &&
                <div id="inGameScoreboard" className="fadeInBottom">
                    <ScoreboardTeam team={Teams.Attackers} score={teamAttackersScore} players={players[Teams.Attackers]} gameState={gameState} />
                    <div className="roundCounter">Round {round??0} / {maxRounds??0}</div>
                    <ScoreboardTeam team={Teams.Defenders} score={teamDefendersScore} players={players[Teams.Defenders]} gameState={gameState} />
                </div>
            }
        </>
    );
};

Scoreboard.defaultProps = {
    showScoreboard: false,
};


export default Scoreboard;
