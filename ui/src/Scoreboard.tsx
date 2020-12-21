import React from "react";
import ScoreboardTeam from "./components/ScoreboardTeam";
import { GameStates } from "./helpers/GameStates";
import { Players } from "./helpers/Player";
import { RoundInfo } from "./helpers/RoundInfo";
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
    roundsList: RoundInfo[];
}

const Scoreboard: React.FC<Props> = ({ showScoreboard, teamAttackersScore, teamDefendersScore, players, gameState, round, maxRounds, roundsList }) => {
    const rounds = [];
    for (let i = 0; i < maxRounds; i++) {
        if (maxRounds / 2 === i) {
            rounds.push(<div className="roundInfo halfTime" key={9999}></div>);
        }

        if (roundsList[i] !== undefined && roundsList[i] !== null) {
            var teamString = "defenders";
            if (roundsList[i].winner === Teams.Attackers) {
                teamString = "attackers";
            }
            rounds.push(<div className={"roundInfo isOver " + teamString} key={i}><span>{i + 1}</span></div>);
        } else {
            rounds.push(<div className="roundInfo isEmpty" key={i}><span>{i + 1}</span></div>);
        }
    }

    return (
        <>
            {showScoreboard &&
                <div id="inGameScoreboard" className="fadeInBottom">
                    <ScoreboardTeam team={Teams.Attackers} score={teamAttackersScore} players={players[Teams.Attackers]} gameState={gameState} />
                    <div className="roundCounter">
                        Round {round??0} / {maxRounds??0}
                        {/*<div className="roundList">
                            {rounds}
                        </div>*/}
                    </div>
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
