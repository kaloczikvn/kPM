import React, { useState } from "react";
import { GameStates, GameStatesRoundString } from "./helpers/GameStates";
import { GameTypes, GameTypesString } from './helpers/GameTypes';
import CountDown from "./components/CountDown";

import './Header.scss';

interface Props {
    teamAttackersScore: number;
    teamDefendersScore: number;
    teamAttackersClan?: string;
    teamDefendersClan?: string;
    currentScene: GameStates;
    round: number|null;
    showHud: boolean;
    gameType: GameTypes;
}

const Header: React.FC<Props> = ({ teamAttackersClan, teamDefendersClan, teamAttackersScore, teamDefendersScore, currentScene, round, showHud, gameType }) => {
    const [ time, setTime ] = useState<number>(0);

    window.SetTimer = function(p_Time: number) {
        setTime(p_Time - 1); //Hacky stuff, -1 sec is needed to show accurate time
    }

    return (
        <>
            <div id="promodHeader">
                Promod
            </div>

            <div id="debug">
                <button onClick={() => setTime(300)}>300 sec</button>
                <button onClick={() => setTime(200)}>200 sec</button>
                <button onClick={() => setTime(100)}>100 sec</button>
            </div>

            {showHud &&
                <div id="inGameHeader" className="fadeInTop">
                    {teamAttackersClan 
                    ?
                        <div id="teamAttackers">
                            {teamAttackersClan}
                        </div>
                    :
                        <div></div>
                    }
                    <div id="score">
                        <div id="scoreAttackers">
                            {/*<span id="team">Attackers</span>*/}
                            <span className="points">{teamAttackersScore??0}</span>
                        </div>
                        <div id="roundTimer">
                            <span className="timer">
                                {(time > 0)
                                ?
                                    <CountDown time={time} />
                                :
                                    <>
                                        00:00
                                    </>
                                }
                            </span>
                            <span className="round">
                                {GameStatesRoundString[currentScene].replace('{round}', (round?.toString()??'1'))??''}
                            </span>

                            <div className="gameTypeLabel">
                                {GameTypesString[gameType]}
                            </div>
                        </div>
                        <div id="scoreDefenders">
                            {/*<span id="team">Defenders</span>*/}
                            <span className="points">{teamDefendersScore??0}</span>
                        </div>
                    </div>
                    {teamDefendersClan 
                    ?
                        <div id="teamDefenders">
                            {teamDefendersClan}
                        </div>
                    :
                        <div></div>
                    }
                </div>
            }
        </>
    );
};

Header.defaultProps = {
    currentScene: GameStates.None,
    teamAttackersScore: 0,
    teamDefendersScore: 0,
    round: 0,
};

export default Header;

declare global {
    interface Window {
        SetTimer: (p_Time: number) => void;
    }
}
